# 第0章：安装开发工具链

为了编写操作系统，我们需要准备一系列工具，本章将安装这些工具。这些工具在一起所组成的整体称为开发工具链。

这套开发工具链，主要包括**交叉编译工具链**和**调试虚拟机**两部分。

> 什么是交叉编译我们在未来的章节会进行介绍



## 1. 一键化懒人操作脚本：init.sh

为了方便学习，我提供了一个懒人脚本`init.sh`，可以直接一键安装所有需要的工具。

> 未来的读者在使用的时候可能由于网络等原因需要更换一下网址，不过至少在目前（2023-2-24）来说，这个脚本是完全够用的。



### 1.1 -h参数

使用`-h`参数可以获得脚本的帮助信息

```shell
bash init.sh -h
```

![运行结果](./assets/image-20230227092534955.png)



### 1.2 -d参数

使用`-d`参数可以下载未来将要使用的交叉编译工具链中所有工具的源代码，以方便接下来编译得到所有交叉编译时用到的工具

> 脚本已经对国内外网络进行了适配，能访问外网时直接从gnu ftp服务器下载，否则从国内镜像源下载

```shell
bash init.sh -d
```

![运行结果](./assets/image-20230227092834850.png)

运行结束后，源代码的压缩包会被放在`${shell_folder}/tools/src`下

```shell
ls tools/src
```

![运行结果](./assets/image-20230227092955351.png)







### 1.3 -c参数

`-c`参数用于编译交叉编译工具链

> -c参数默认不会编译qemu，因为bochs对于WIOS来说就已经够用了，如果你需要在你的项目中使用init.sh脚本来构建交叉编译工具链，请参考-fc参数

```shell
bash init.sh -c
```

![开始编译](./assets/image-20230227093319466.png)

![编译完成](./assets/image-20230227101946470.png)

我们可以修改`init.sh`中`PREFIX`的值来指定编译完成后交叉编译工具链安装到的位置

> 默认的安装位置是：<path-to-WIOS>/tools/bin

```bash
ls tools/bin
```

![查看交叉编译链工具](./assets/image-20230227102426396.png)

为了我们能够在命令行中直接调用交叉编译工具链中的工具，我们还需要把交叉编译工具链所在的文件夹加入到`PATH`环境变量中。

这一步在`init.sh`中已经提供了，运行下面命令来添加

```shell
source init.sh
```

![添加到PATH中](./assets/image-20230227103215061.png)

而后我们输入`i686-elf<Tab><Tab>`就可以出现补全了，包括使用`which`进行查找

```shell
i686-elf-<Tab><Tab>
which i686-elf-gcc
```

![教程工具链已经出现补全](./assets/image-20230227103652682.png)



### 1.4 -fc参数

`-fc`参数在`-c`参数的基础上，还会编译`qemu`

```shell
bash init.sh -fc
```

![编译结果](./assets/image-20230227171630997.png)





## 2. 手动安装开发工具链

在未来，我们开发自己的操作系统的流程是这样的：

- 写代码
- 编译代码
- 虚拟机调试

**写代码使用编辑器就可以了**。`VSCode`、`Vim`、`gedit`、`nano`、`Emacs`乃至于记事本都可以

**编译代码则需要使用针对目标平台的的交叉编译工具链**。例如，我们未来的操作系统要能够在`Intel 80386`系列之后的CPU上运行，那么针对`80386`这个目标平台，我们需要使用能够生成可以在`80386 CPU`上运行的代码的编译器

**虚拟机调试则是我们需要模拟出来一个使用目标CPU的机器，然后我们在这个虚拟出来的机器上运行、调试我们的操作系统**。

> 尽管我上面已经解释过了为什么我们需要交叉编译工具链，但是初读到这里读者可能还是不明白为什么我们需要交叉编译工具链。放心，我们在后面的章节会进行介绍

### 2.1 调试操作系统

我们编写自己的操作系统，那么我们就无可避免的需要对我们的操作系统进行调试。那么在调试操作系统的时候会存在一个现象：**我们的电脑上正在运行一个操作系统（例如：`Windows`、`Linux`、`Mac`），而我们需要再这个操作系统中运行另外一个操作系统（我们自己的操作系统）**

在操作系统中运行另外一个操作系统，其实就是虚拟机，我们通过虚拟机软件，可以虚拟出来一个新的电脑，然后让我们的操作系统运行在虚拟出来的电脑中即可。

目前用的比较多的虚拟机软件有：`VMWare`、`VirtualBox`等，但是这类虚拟机软件的重点是运行一个操作系统，而非单步调试操作系统。因此我们需要的是一个提供了调试操作系统的接口的虚拟机软件。

目前支持调试操作系统的虚拟机软件有：`Bochs`和`QEMU`。`Bochs`轻量但是功能不如`QEMU`强大。对于我们将要写的`WIOS`来说，`Bochs`和`QEMU`都是可以的。



> 在后续的WIOS的调试中，我会使用Bochs，原因就是我习惯了Bochs，目前也没有遇到什么只有QEMU才有的功能





#### 2.1.1 编译Bochs

首先下载源码

```bash
    wget https://sourceforge.net/projects/bochs/files/bochs/2.7/bochs-2.7.tar.gz
```

> 也可以访问`SourceForge`上`Bochs`的网页去下载源码：https://sourceforge.net/projects/bochs/files/bochs/

然后安装编译时需要的依赖

```shell
sudo apt-get install build-essential xorg-dev libgtk2.0-dev bison
```

接下来编译安装`Bochs`

```shell
sudo tar xvzf bochs-2.7.0tar.gz
cd bochs-2.7.0
#  下面的配置编译得到的bochs不支持gdb调试，只能使用bochs自带的调试器
./configure  --PREFIX=安装到的目录 --enable-debugger --enable-iodebug --enable-x86-64 --with-x --with-x11
#  下面的配置编译得到的bochs支持gdb调试，可以使用gdb或者vscode中的gdb链接bochs调试
./configure  --PREFIX=安装到的目录 --enable-gdb-stub --enable-iodebug --enable-x86-64 --with-x --with-x11
make
make install
```

> 如果不指定--PREFIX参数，则默认安装到`/usr/bin`文件夹下，此时需要`sudo make install`



#### 2.1.2 编译QEMU

`QEMU`的编译相比于`Bochs`简单了很多

首先下载源码

```shell
wget https://download.qemu.org/qemu-7.2.0.tar.xz
```

然后解压、编译并安装`QEMU`

```shell
tar xvJf qemu-7.2.0.tar.xz
cd qemu-7.2.0
./configure
make
```

> 因为QEMU是使用的ninja来作为构建系统的，因此不需要进行`make install`

参考官网教程：https://www.qemu.org/download/#source





### 2.2 交叉编译工具链

交叉编译工具链需要我们编译目标平台的`binutils`和`gcc`。

首先下载`binutils`和`gcc`的源码

```shell
wget https://ftp.gnu.org/gnu/binutils/binutils-2.38.tar.gz
wget https://ftp.gnu.org/gnu/gcc/gcc-10.4.0/gcc-10.4.0.tar.gz
```

> 你也可以访问：https://ftp.gnu.org/gnu/binutils/ 和 https://ftp.gnu.org/gnu/gcc/ 下载你喜欢的版本



开始编译前先声明一些环境变量，用于后续的编译和安装

```shell
export PREFIX=交叉编译工具链将安装的位置
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
```

> 未来的WIOS将运行在Intel 60386 CPU上，因此我们把目标平台设置为i686-elf

接下来先编译`binutils`

```shell
tar xzvf binutils-x.y.z.tar.gz
 
mkdir build-binutils
cd build-binutils
../binutils-x.y.z/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make
make install
```

> 这里`bintuils-x.y.z`的`x.y.z`是版本号，具体替换成你下载的`binutils`的版本号

最后编译`gcc`

```shell
tar xzvf gcc-x.y.z.tar.gz
 
# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
which -- $TARGET-as || echo $TARGET-as is not in the PATH
 
mkdir build-gcc
cd build-gcc
../gcc-x.y.z/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc
make all-target-libgcc
make install-gcc
make install-target-libgcc
```

> 这里`gcc-x.y.z`的`x.y.z`是版本号，具体替换成你下载的`gcc`的版本号



