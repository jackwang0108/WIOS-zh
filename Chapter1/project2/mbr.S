;mbr.S
section MBR vstart=0x7c00
    ; 设置段寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    ; 设置显卡内存地址
    mov ax, 0xb800
    mov gs, ax

    ; 写显存方式打印字符串, 4表示前景色为红色，A表示绿色背景闪烁
    mov byte [gs:0x00], 'H'
    mov byte [gs:0x01], 0x4A
    mov byte [gs:0x02], 'e'
    mov byte [gs:0x03], 0x4A
    mov byte [gs:0x04], 'l'
    mov byte [gs:0x05], 0x4A
    mov byte [gs:0x06], 'l'
    mov byte [gs:0x07], 0x4A
    mov byte [gs:0x08], 'o'
    mov byte [gs:0x09], 0x4A
    mov byte [gs:0x0a], ' '
    mov byte [gs:0x0b], 0x4A
    mov byte [gs:0x0c], 'W'
    mov byte [gs:0x0d], 0x4A
    mov byte [gs:0x0e], 'o'
    mov byte [gs:0x0f], 0x4A
    mov byte [gs:0x10], 'r'
    mov byte [gs:0x11], 0x4A
    mov byte [gs:0x12], 'l'
    mov byte [gs:0x13], 0x4A
    mov byte [gs:0x14], 'd'
    mov byte [gs:0x15], 0x4A
    mov byte [gs:0x16], '!'

    ; 程序悬停在此
    jmp $

  ; 前面的指令肯定用不到446字节，并且我们直接让分区表为0
  ; 所以这使用times伪指令在最终的程序中从当前字节开始，
  ; 一直到第446+64=510个字节全为0
  times 510 - ($ - $$) db 0

  ; 第511个字节和512个字节是MBR分区标志,0x55AA
  db 0x55, 0xaa
