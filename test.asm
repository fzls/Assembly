;==============源程序开始========================
code segment
assume cs:code,ds:code
;--------------Int_8h---------------------------
int_8h:
    inc cs:[count]
    cmp cs:[count],18
    jb  goto_old_8h
    mov cs:[count],0
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    ;
    push cs
    pop  ds; DS=CS
    push cs
    pop  es; ES=CS
    mov al,4
    out 70h,al; index hour
    in al,71h ; AL=hour(e.g. 08h means 8 am., 15h means 3 pm.)
    call convert
    mov word ptr current_time[0],ax
    mov al,2
    out 70h,al; index minute
    in  al,71h; AL=minute
    call convert
    mov word ptr current_time[3],ax
    mov al,0  ; index second
    out 70h,al
    in  al,71h; AL=second
    call convert
    mov word ptr current_time[6],ax
    call disp_time
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
goto_old_8h:
    jmp dword ptr cs:[old_8h]
old_8h dw 0,0; old vector of int_8h
;---------End of Int_8h----------

;---------Disp_time--------------
;Output:display current time
;       at (X0,Y0)
X0 = 80-current_time_str_len
Y0 = 0
disp_time proc near
    push ax
    push cx
    push dx
    push si
    push di
    push ds
    push es
    mov ax,0B800h
    mov es,ax; ES=video buf seg
    mov ax,Y0
    mov cx,80*2
    mul cx   ; DX:AX=Y0*(80*2)
    mov dx,X0
    add dx,dx; DX=X0*2
    add ax,dx; AX=Y0*(80*2)+(X0*2)
    mov di,ax; ES:DI--->video buffer
    push cs
    pop  ds
    mov  si,offset current_time; DS:SI--->current_time
    mov  cx,current_time_str_len
    cld
    mov ah,17h; color=blue/white
disp_next_char:
    lodsb
    stosw
    loop disp_next_char
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret
disp_time endp
;---------End of Disp_time-------

;---------Convert----------------
;Input:AL=hour or minute or second
;      format:e.g. hour   15h means 3 pm.
;                  second 56h means 56s
;Output: (e.g. AL=56h)
;     AL='5'
;     AH='6'
convert proc near
    push cx
    mov ah,al ; e.g. assume AL=56h
    and ah,0Fh; AH=06h
    mov cl,4
    shr al,cl ; AL=05h
    add ax,'00'
    pop  cx
    ret
convert endp
;---------End of Convert---------
current_time db '00:00:00'
current_time_str_len = $-offset current_time ; 8 bytes
                                             ; $ is a macro which
                                             ; means current offset
count db 0   ; increment it on every interrupt
             ; When it reaches 18(about 1 second elapsed),
             ; it's time to display the time.
;============以上代码需要驻留=====================================

;程序从此处开始运行
initialize:
    push cs
    pop ds ; DS=CS
    xor ax, ax
    mov es, ax
    mov bx, 8*4; ES:BX-> int_8h's vector
    push es:[bx]
    pop old_8h[0]
    push es:[bx+2]
    pop old_8h[2]; save old vector of int_8h
    mov ax, offset int_8h
    cli    ; disable interrupt when changing int_8h's vector
    push ax
    pop es:[bx]
    push cs
    pop es:[bx+2]; set vector of int_8h
    sti    ; enable interrupt
install:
    mov ah,9
    mov dx,offset install_msg
    int 21h
    mov dx,offset initialize; DX=len before label initialize
    add dx,100h; include PSP's len
    add dx,0Fh; include remnant bytes
    mov cl,4
    shr dx,cl ; DX=program's paragraph size to keep resident
    mov ah,31h
    int 21h   ; keep resident
install_msg db 'AUTOTIME version 1.0',0Dh,0Ah
            db 'Copyright Black White. Nov 18,1997',0Dh,0Ah,'$'
code ends
end initialize
;==============源程序结束========================


