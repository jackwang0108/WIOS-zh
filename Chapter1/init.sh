#! /bin/bash

# ------------------------------------------------------------------------------------------
# -------------------------------------- Configuration -------------------------------------
# ------------------------------------------------------------------------------------------

# Installation Options, modify them if you need. Folder will be created if not exists.
shell_folder=$(
cd "$(dirname "$(readlink -f -- "$0")" > /dev/null 2&>/dev/null)"|| exit;
    pwd
)
export PREFIX="$shell_folder"/tools
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
export BXSHARE="$PREFIX/share/bochs"

# Configure Options
# modify them if you need more/less options. Don't forget <white-space> before \

# bochs configure options
read -r -d '' bochs_no_gdb_configure <<-EOM
--enable-debugger \
--enable-iodebug \
--enable-x86-64 \
--with-x \
--with-x11
EOM
read -r -d '' bochs_with_gdb_configure <<-EOM
--enable-gdb-stub \
--enable-iodebug \
--enable-x86-64 \
--with-x \
--with-x11
EOM

# qemu configure options
read -r -d '' qemu_configure <<-EOM
EOM

# gcc configrue options
read -r -d '' gcc_configure <<-EOM
--disable-nls \
--enable-language=c,c++ \
--without-headers 
EOM

# binutils configure options
read -r -d '' binutils_configure <<-EOM
--with-sysroot \
--disable-nls \
--disable-werror 
EOM

# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------

# terminal colors
purple='\e[35m'
green='\e[32m'
red='\e[31m'
return='\e[0m'

function red() {
    echo -e "$red$1$return"
}

function green() {
    echo -e "$green$1$return"
}

function purple() {
    echo -e "$purple$1$return"
}

# download link
bochs_download_link=(
    https://gitee.com/jackwangsh/bochs.git
    https://sourceforge.net/projects/bochs/files/bochs/2.7/bochs-2.7.tar.gz
)

qemu_download_link=(
    https://gitee.com/jackwangsh/qemu.git
    https://download.qemu.org/qemu-7.2.0-rc4.tar.xz
)

gcc_download_link=(
    https://gitee.com/jackwangsh/gcc.git
    https://ftp.gnu.org/gnu/gcc/gcc-10.4.0/gcc-10.4.0.tar.gz
)

binutils_doanload_link=(
    https://gitee.com/jackwangsh/binutils.git
    https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.gz
)

# source
is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then 
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

# Sample call.
is_sourced && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
    echo -n "Shell folder is: "; green $shell_folder
    echo -n "Binary util folder is: "; green $PREFIX/bin
    echo "Binary util folder has been added to PATH"
fi

if [[ $1 = '-h' ]] || [[ $1 = '--help' ]]; then
    echo "Init tools for downloading, compiling, and installing corss-compile and debug tool-chain for JackOS, created by Jack Wang"
    echo 'Options:'
    echo '    -h, --help                Show this help message'
    echo '    -d, --download            Download toolchain'
    echo '    -c, --compile             Compile toolchain, without qemu'
    echo '    -fc, --fully-compile      Compile toolchain, with qemu'
fi

if [[ $1 = "-d" ]] || [[ $1 = "--download" ]] || [[ ! -d "$shell_folder"/tools ]]; then
    # create folder
    if [[ ! -d "$shell_folder"/tools/src ]]; then
        read -p 'tools/src not exists, create? <y/n>: ' download
        if [[ $download = "y" ]]; then
            mkdir -p "$shell_folder"/tools/src
        fi
    fi
    # download
    if [[ $1 = "-d" ]] || [[ $1 = "--download" ]]; then
        # network test
        echo "Network status testing in 3 seconds..."
        google_status=$(curl -s -m 3 -IL https://www.google.com | grep 200)
        if [ "$google_status" == "" ]; then
            echo "google service is OFF, using Chinese image source"
            google=0
        else
            echo "google service is ON, using original source"
            google=1
        fi

        # download debug tools
        echo 'Downloading debug tools...'
        # bochs
        purple "=> bochs-2.7"
        if [ -f "$shell_folder"/tools/src/bochs-2.7.tar.gz ]; then
            size=$(du -k "$shell_folder"/tools/src/bochs-2.7.tar.gz | awk '{print $1}')
            if [ $size -le 5000 ]; then
                green 'bochs download failed, incomplete bochs source code detected! Run `rm -rf tools/src/bochs-2.7.tar.gz` to redownload'
            else
                green 'bochs already exists, nothing changed, run `rm -rf tools/src/bochs-2.7.tar.gz` to force re-download'
            fi
        else
            if [ $google -eq 0 ]; then
                if git clone ${bochs_download_link[$google]} "$shell_folder"/tools/src/bochs/ --depth=1; then
                    green "bochs download success"
                    mv "$shell_folder"/tools/src/bochs/bochs-2.7.tar.gz "$shell_folder"/tools/src/
                    rm -rf "$shell_folder"/tools/src/bochs
                else
                    red 'bochs download fail, removing temp files... exiting...'
                    rm -f "$shell_folder"/tools/src/bochs/bochs-2.7.tar.gz
                    exit 255
                fi
            else
                if wget -t 5 -T 5 -c --quiet --show-progress -O "$shell_folder"/tools/src/bochs-2.7.tar.gz ${bochs_download_link[$google]}; then
                    green "bochs download success"
                else
                    red 'bochs download fail, removing temp files... exiting...'
                    rm -f "$shell_folder"/tools/src/bochs-2.7.tar.gz
                    exit 255
                fi
            fi
        fi

        # qemu
        purple "=> qemu-7.2.0"
        if [ $google -eq 0 ]; then
            if git clone ${qemu_download_link[$google]} "$shell_folder"/tools/src/qemu --depth=1; then
                green "qemu download success"
                mv "$shell_folder"/tools/src/qemu/qemu-7.2.0-rc4.tar.gz "$shell_folder"/tools/src
                rm -rf "$shell_folder"/tools/src/qemu
            else
                red 'qemu download fail, exiting... Re-run `bash init.sh -d` to continue qemu download'
                exit 255
            fi
        else
            if wget -T 5 -c --quiet --show-progress -P "$shell_folder"/tools/src ${qemu_download_link[$google]}; then
                green "qemu download success"
            else
                red 'qemu download fail, exiting... Re-run `bash init.sh -d` to continue qemu download'
                exit 255
            fi
        fi

        echo 'Downloading cross-compiler...'
        # gcc
        purple "=> gcc-10.4"
        if [ $google -eq 0 ]; then
            if git clone ${gcc_download_link[$google]} "$shell_folder"/tools/src/gcc --depth=1; then
                green "gcc download success"
                mv "$shell_folder"/tools/src/gcc/gcc-10.4.0.tar.gz* "$shell_folder"/tools/src
                rm -rf "$shell_folder"/tools/src/gcc
            else
                red 'gcc download fail, exiting... Re-run `bash init.sh -d` to continue gcc download'
                exit 255
            fi
        else
            if wget -T 5 -c --quiet --show-progress -P "$shell_folder"/tools/src ${gcc_download_link[$google]}; then
                green "gcc download success"
            else
                red 'gcc download fail, exiting... Re-run `bash init.sh -d` to continue gcc download'
                exit 255
            fi
        fi

        # binutils
        purple "=> binutils-2.38"
        if [ $google -eq 0 ]; then
            if git clone ${binutils_doanload_link[$google]} "$shell_folder"/tools/src/binutils --depth=1; then
                green "binutils download success"
                mv "$shell_folder"/tools/src/binutils/binutils-2.38.tar.gz "$shell_folder"/tools/src
                rm -rf "$shell_folder"/tools/src/binutils
            else
                red 'binutils download fail, exiting... Re-run `bash init.sh -d` to continue binutils download'
                exit 255
            fi
        else
            if wget -c -T 5 --quiet --show-progress -P "$shell_folder"/tools/src https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.gz; then
                green "binutils download success"
            else
                red 'binutils downlaod fail, exiting... Re-run `bash init.sh -d` to continue binutils download'
                exit 255
            fi
        fi
    fi
fi

if [[ $1 = "-c" ]] || [[ $1 = "--compile" ]] || [[ $1 = "-fc" ]] || [[ $1 = '--fully-compile' ]]; then
    log="$shell_folder"/tools/log
    mkdir -p "$log"

    # print info
    echo -e "Target platform $green$TARGET${return}"
    echo -e "Cross-compile tools will be installed: ${green}$PREFIX$return"
    echo -e "Compile logs will be written to: ${green}$log$return"
    echo -e "Modify first few lines of init.sh to change compile options"
    if [[ $1 = '-fc' ]]; then
        echo -e "Please make sure at least ${green}18GB free space$return left, since ${green}qemu$return may take ${green}10GB$return and ${green}gcc$return will take another ${green}4.5GB$return"
        echo -e "Compile may take ${green}20 minutes${return}, start in 3 seconds..."
    else
        echo -e "Please make sure at least ${green}6GB free space$return left, since ${green}gcc$return will take ${green}4.5GB$return"
        echo -e "Compile may take ${green}5 minutes${return}, start in 3 seconds..."
    fi
    sleep 3s

    # basics utils
    purple "=> Installing basic utils:"
    if ! sudo apt update; then 
        red "install basic utils failed, exiting"
    else
	if ! sudo apt install -y pigz build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo libx11-dev xserver-xorg-dev xorg-dev 2>&1 | tee "$log"/basic-utils.log; then
            red "install basic utils failed, exiting"
            exit 255
	fi
    fi

    # bochs
    purple "=> Compile bochs-2.7: no gdb"
    cd "$shell_folder"/tools/src || (
        red "cd to tools/src fail, nothong changed, exiting..."
        exit 255
    )
    green "Compile options: $bochs_no_gdb_configure"
    echo "Extracting..."
    sleep 3s
    if ! tar xzf "$shell_folder"/tools/src/bochs-2.7.tar.gz; then
        red "extract bochs-2.7.tar.gz fail, exiting"
        exit 255
    fi
    if ! mkdir -p build-bochs; then
        red "creating build-bochs fail, exiting..."
        exit 255
    fi
    # bochs-2.7 no-gdb
    cd "$shell_folder"/tools/src/build-bochs || (
        red 'cd to build-bochs fail'
        exit
    )
    if ! ../bochs-2.7/configure --prefix="$PREFIX" $bochs_no_gdb_configure 2>&1 | tee "$log"/bochs-debugger-configure.log; then
        red 'bochs-2.7 no-gdb configure fail, exiting...'
        exit 255
    fi
    if ! make -j "$(nproc)" 2>&1 | tee "$log"/bochs-debugger-make.log; then
        red "bochs-2.7 no-gdb make fail, exiting..."
        exit 255
    fi
    cp bochs bochsdbg
    if ! make install -j "$(nproc)" 2>&1 | tee "$log"/bochs-debugger-make-install.log; then
        red "bochs-2.7 no-gdb make install fail, exiting..."
        exit 255
    fi

    # bochs-2.7 with-gdb
    purple "=> Compile bochs-2.7: with gdb"
    green "Compile options: $bochs_with_gdb_configure"
    sleep 5s
    if ! ../bochs-2.7/configure --prefix="$shell_folder"/tools/build-bochs-gdb $bochs_with_gdb_configure 2>&1 | tee "$log"/bochs-gdb-debugger-configure.log; then
        red "bochs-2.7 with-gdb configure fail, exiting..."
        exit 255
    fi
    if ! make -j "$(nproc)" 2>&1 | tee "$log"/bochs-gdb-make.log; then
        red "bcohs-2.7 with-gdb make fail, exiting..."
        exit 255
    fi
    cp bochs bochsdbg
    if ! make install -j "$(nproc)" 2>&1 | tee "$log"/bochs-gdb-make-install.log; then
        red "bochs-2.7 with-gdb make install fail, exiting...."
        exit 255
    fi
    if ! mv "$shell_folder"/tools/build-bochs-gdb/bin/bochs "$shell_folder"/tools/bin/bochs-gdb; then
        red "bochs-2.7 with-gdb rename fail, exiting..."
        exit 255
    fi
    if ! rm -r "$shell_folder"/tools/build-bochs-gdb; then
        red "bochs-2.7 with-gdb remove temp file failed, exiting..."
        exit 255
    fi
    green "bochs, bochs-gdb, bochsdbg and bximage successfully compiled and installed. PS: ignore bochsdbg not found, it doesn't matter"

    # qemu
    if [[ $1 = "-fc" ]] || [[ $1 = "--fully-compile" ]]; then
        purple "=> Compile qemu-7.2.0"
        cd "$shell_folder"/tools/src || (red "cd to tools/src fail, nothong changed, exiting..." && exit 255)
        green "Compile options: $qemu_configure"
        echo "Extracting..."
        sleep 2s
        if [ -f "$shell_folder"/tools/src/qemu-7.2.0-rc4.tar.xz ]; then
            if ! tar xJf "$shell_folder"/tools/src/qemu-7.2.0-rc4.tar.xz; then
                red "extract qemu-7.2.0 fail, exiting"
                exit 255
            fi
        else
            if ! tar xJf "$shell_folder"/tools/src/qemu-7.2.0-rc4.tar.gz; then
                red "extract qemu-7.2.0 fail, exiting"
                exit 255
            fi
        fi
        if ! mkdir -p build-qemu; then
            red "creating build-qemu fail, exiting..."
            exit 255
        fi
        cd "$shell_folder"/tools/src/build-qemu || (
            red 'cd to build-qemu fail'
            exit
        )
        if ! ../qemu-7.2.0-rc4/configure --prefix="$PREFIX" $qemu_configure 2>&1 | tee "$log"/qemu-configure.log; then
            red "qemu-7.2.0 configure fail, exiting..."
            exit 255
        fi
        if ! make -j "$(nproc)" 2>&1 | tee "$log"/qemu-make.log; then
            red "qemu-7.2.0 make fail, exiting..."
            exit 255
        fi
        if ! make install -j "$(nproc)" 2>&1 | tee "$log"/qemu-make-install.log; then
            red "qemu-7.2.0 make install fail, exiting..."
            exit 255
        fi
        green "qemu successfully compiled and installed"
    fi

    # binutils
    purple "=> Compile binutils-2.38"
    cd "$shell_folder"/tools/src || (red "cd to tools/src fail, nothong changed, exiting..." && exit 255)
    green "Compile options: $binutils_configure"
    echo "Extracting..."
    sleep 3s
    if ! tar xzf "$shell_folder"/tools/src/binutils-2.38.tar.gz; then
        red "extract binutils-2.38 fail, exiting"
        exit 255
    fi
    if ! mkdir -p build-binutils; then
        red "creating build-binutils fail, exiting..."
        exit 255
    fi
    cd "$shell_folder"/tools/src/build-binutils || (
        red 'cd to build-binutils fail'
        exit
    )
    if ! ../binutils-2.38/configure --target=$TARGET --prefix="$PREFIX" $binutils_configure 2>&1 | tee "$log"/binutil-configure.log; then
        red "binutils-2.38 configure fail, exiting..."
        exit 255
    fi
    if ! make -j "$(nproc)" 2>&1 | tee "$log"/binutil-make.log; then
        red "binutils-2.38 make fail, exiting..."
        exit 255
    fi
    if ! make install -j "$(nproc)" 2>&1 | tee "$log"/binutil-make-install.log; then
        red "binutils-2.38 make install fail, exiting..."
        exit 255
    fi
    green "binutils successfully compiled and installed"

    # gcc
    purple "=> Compile gcc"
    cd "$shell_folder"/tools/src || (echo "cd to tools fail, nothong changed, exiting..." && exit)
    echo "Searching $TARGET-as..."
    which -- $TARGET-as || (
        red "$TARGET-as is not in the PATH, aborting..."
        exit
    )
    green "Compile options: $binutils_configure"
    echo "Extracting..."
    sleep 3s
    if [ -f "$shell_folder"/tools/src/gcc-10.4.0.tar.gz.0 ]; then
	    if ! cat "$shell_folder"/tools/src/gcc-10.4.0.tar.gz.* | tar --use-compress-program=pigz -x; then
		red "extract gcc-10.4.0.tar.gz fail, exiting..."
		exit 255
	    fi
    else
	    if ! tar xzf "$shell_folder"/tools/src/gcc-10.4.0.tar.gz; then
		red "extract gcc-10.4.0.tar.gz fail, exiting..."
		exit 255
	    fi
    fi
    if ! mkdir -p build-gcc; then
        red "creating build-gcc fail, exiting..."
        exit 255
    fi
    cd "$shell_folder"/tools/src/gcc-10.4.0
    if [ $google -eq 0 ]; then
        if ! git clone https://gitee.com/jackwangsh/gcc_prerequisite.git "$shell_folder"/tools/src/gcc-10.4.0/prerequisite; then
            red "download gcc compile prerequisite failed!"
        fi
        mv "$shell_folder"/tools/src/gcc-10.4.0/prerequisite/*  "$shell_folder"/tools/src/gcc-10.4.0
    else
        if ! bash "$shell_folder"/tools/src/gcc-10.4.0/contrib/download_prerequisites; then
            red "download gcc compile prerequisite failed!"
            exit
        fi
    fi
    cd "$shell_folder"/tools/src/build-gcc || (
        red 'cd to build-gcc fail'
        exit
    )
    if ! ../gcc-10.4.0/configure --target=$TARGET --prefix="$PREFIX" $gcc_configure 2>&1 | tee "$log"/gcc-configure.log; then
        red "gcc-10.4.0 configure fail, exiting..."
        exit 255
    fi
    if ! make -j "$(nproc)" all-gcc 2>&1 | tee "$log"/gcc-make-all-gcc.log; then
        red "gcc-10.4.0 all-gcc make fail, exiting..."
        exit 255
    fi
    if ! make -j "$(nproc)" all-target-libgcc 2>&1 | tee "$log"/gcc-make-all-target-libgcc.log; then
        red "gcc-10.4.0 all-target-libgcc make fail, exiting..."
        exit 255
    fi
    if ! make install-gcc 2>&1 | tee "$log"/gcc-make-install-gcc.log; then
        red "gcc-10.4.0 all-gcc make install fail, exiting..."
        exit 255
    fi
    if ! make install-target-libgcc 2>&1 | tee "$log"/gcc-make-install-target-libgcc.log; then
        red "gcc-10.4.0 all-target-libgcc make install fail, exiting..."
        exit 255
    fi
    green "gcc successfully compiled and installed"

    cd "$shell_folder" || exit
    if [[ $1 = "-fc" ]] || [[ $1 = '--fully-compile' ]]; then
        purple "You can run bochs, bochs-gdb, qemu, $TARGET-gcc, $TARGET-ld, $TARGET-as now"
    else
        purple "You can run bochs, bochs-gdb, $TARGET-gcc, $TARGET-ld, $TARGET-as now"
    fi

    green "Run \`source init.sh\` first or manually add tools/bin into your PATH"
fi

