code segment
assume cs:code;cs: code segment
main:
        mov ax, 0A000h;ax: accumulator
        mov es, ax;es: extra segment
        ;instant number cannot moved to segment register directly, so we should use ax as a transition
        mov ax, 0013h
        int 10h
        mov di, (100-20)*320+(160-20); (160-20,100-20);di: destination index
        mov cx, 41; rows=41 ; cx: count
next_row:
        push cx;push cx into the stack
        push di;push di into the stack
        mov al, 4; color=red ;al: the lower part of ax
        mov cx, 41; dots=41
next_dot:
        mov es:[di], al
        add di, 1
        sub cx, 1
        jnz next_dot
        pop di; 左上角(x,y)对应的地址
        pop cx; cx=41
        add di, 320; 下一行的起点的地址
        sub cx, 1; 行数-1
        jnz next_row
        mov ah, 0;ah high end of accumulator register
        int 16h;键盘输入,类似int 21h的01h功能
        mov ax, 0003h
        int 10h; 切换到80*25文本模式
        mov ah, 4Ch
        int 21h
code ends
end main

