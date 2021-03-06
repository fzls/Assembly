 ;
 ;----------------------------------------------------------
 ;
 ; @authors: 风之凌殇//陈计 3130101213 <chenji@zju.edu.cn>
 ; @FILE NAME:	 hexfile.asm
 ; @version:	 	 v1.0
 ; @Time: 		 2015-12-30 18:00:00 ~ 2015-12-31 19:52:17
 ; @Description: the second homework of the Assembly Programming Language
 ;
 ;----------------------------------------------------------
 ;
data segment
	;---------------------KeyBoardConstant---------------------
	_PageUp       dw	4900h
	_PageDown     dw	5100h
	_Home         dw	4700h
	_End          dw	4F00h
	_Esc          dw	011Bh
	;---------------------Strings---------------------
	filename      db    101
                  db    ?
                  db    101 dup(0)
	buf           db    256 dup(?)
	prompt        db    'Please input filename:$'
	errorOpenFile db    'Cannot open file!$'
	debugInfo     db    '---------DEBUG----------!$'
	s             db    '00000000: xx xx xx xx|xx xx xx xx|xx xx xx xx|xx xx xx xx  ................'
	pattern       db    '00000000:            |           |           |                             '
	len_pattern   equ   $-pattern
	t             db    '0123456789ABCDEF'
	xx            db    ?
	;---------------------Int---------------------
	handle        dw    ?
	key           dw    ?
	bytes_in_buf  dw    ?
	rows          dw    ?
	bytes_on_row  dw    ?
	currRow       dw    ?
	curBufPos     dw    ?
   curVideoOffset dd    ?
	;---------------------Long_Int---------------------
	file_size     dd    ?
	offsets       dd    ?
	currRowOffset dd    ?
	n             dd    ?
	lastPageSize  dd    ?
data ends
mystack segment
	    dw 100h dup(?)
mystack ends
code segment
	assume cs:code, ds:data, ss:mystack
	main:
	    mov ax, data
	    mov ds, ax
	    call inputFileName
	    call openFile
	    call mainLoops
	    call closeFile
	    mov ah, 4ch
	    int 21h
;-----------------Below is the subFunctions-----------------
showprompt:
	    ;output prompt
	    mov dx, offset prompt
	    mov ah, 09h
	    int 21h
	    call newline
	    ret
newline:
		;output return
	    mov ah, 2
	    mov dl, 0Dh
	    int 21h
	    ;output line feeds
	    mov ah, 2
	    mov dl, 0Ah
	    int 21h
	    ret
inputFileName:
	    call showprompt
	    ;input file name
	    mov ah, 0ah
	    mov dx, offset filename
	    int 21h
	    ;set the filename to be zero-ending
	    mov al, filename[1]
	    mov ah, 0
	    mov si, ax
	    mov filename[2+si] ,0
	    call newline
	    ret
openFile:
		;NOTICE :filename should be end by 0 or $
		mov ah,3Dh
		mov al,0
		mov dx, offset filename+2
		int 21h
	    call checkIfOpenFileFailed
	    call getFileSize
		ret
checkIfOpenFileFailed:
	  jc  errorOpening
		mov handle, ax
		ret
errorOpening:
		mov dx, offset errorOpenFile
	    mov ah, 09h
	    int 21h
	    call newline
	    ;exit
		mov ah,4ch
		mov al, 0
		int 21h
getFileSize:
		mov ah, 42h
		mov al, 2
		mov bx, handle
		mov cx, 0
		mov dx, 0
		int 21h
		mov word ptr file_size[2], dx
		mov word ptr file_size[0], ax
		call computeLastPageSize
		ret
computeLastPageSize:
		;lastPageSize = file_size
		mov ax, word ptr file_size[0]
		mov dx, word ptr file_size[2]
		mov word ptr lastPageSize[0], ax
		mov word ptr lastPageSize[2], dx
		;while lastPageSize>256, lastPageSize -= 256
	seeIfNeeddecreaseAnother256:
		cmp word ptr lastPageSize[2], 0
	  ja largeThan256
		cmp word ptr lastPageSize[0], 256
	  ja largeThan256
      jmp doneCLPS
	largeThan256:
		sub word ptr lastPageSize[0], 256
		sbb word ptr lastPageSize[2], 0
	  jmp seeIfNeeddecreaseAnother256
	doneCLPS:
		ret
mainLoops:
		;init offset to 0
		mov word ptr offsets[2], 0;
		mov word ptr offsets[0], 0;
		;loop body
	again:
		call computeBufferSize
		call readFile
		call show_this_page
		call switchKey
		;if didn't strike ESC, continue loop
		mov ax , word ptr _Esc
		cmp word ptr key, ax
	  jne again
		ret
computeBufferSize:
		; n = file_size
		mov dx, word ptr file_size[2]
		mov ax, word ptr file_size[0]
		mov word ptr n[2], dx;
		mov word ptr n[0], ax;
		; n -= offsets
		mov dx, word ptr offsets[2]
		mov ax, word ptr offsets[0]
		sub word ptr n[0], ax
		sbb word ptr n[2], dx
		;compute bytes_in_buf
		cmp word ptr n[2], 0
	  ja greater
		cmp word ptr n[0], 256
	  jae greater
	lessThan256:
		mov ax, word ptr n[0]
		mov word ptr bytes_in_buf, ax
	  jmp done
	greater:
		mov word ptr bytes_in_buf, 256
	done:
		ret
readFile:
		;move file pointer
		mov ah, 42h
		mov al, 0
		mov bx, handle
		mov cx, word ptr offsets[2]
		mov dx, word ptr offsets[0]
		int 21h
		;read file
		mov ah, 3Fh
		mov bx, handle
		mov cx, bytes_in_buf
		mov dx, offset buf
		int 21h
		ret
show_this_page:
		call clear_this_page
		call computeRows
		mov cx, rows
		mov word ptr currRow, 0
		; use currRowOffset instead of offsets
		mov ax, word ptr offsets[0]
		mov dx, word ptr offsets[2]
		mov word ptr currRowOffset[0], ax
		mov word ptr currRowOffset[2], dx
	showRow:
		call computeBytesOnRow
		call show_this_row
		inc word ptr currRow
		add word ptr currRowOffset[0], 16
		adc word ptr currRowOffset[2], 0
	  loop showRow
		ret
clear_this_page:
		;start at B800:0000
		mov ax, 0B800h
		mov es, ax
		mov di, 0000h
		mov cx, 80*16
		mov ax, 0020h
		cld
		rep stosw
		ret
computeRows:
		mov ax, word ptr bytes_in_buf
		mov word ptr rows, ax
		add word ptr rows, 15
		mov ax, word ptr rows
		mov cl, 16
		div cl
		mov ah, 0
		mov word ptr rows, ax
		ret
computeBytesOnRow:
		mov ax, word ptr rows
		dec ax
		cmp word ptr currRow, ax
	  je bytesOnLastRow
		mov word ptr bytes_on_row, 16
	  jmp doneCBOR
	bytesOnLastRow:
		;bytes_on_row = bytes_in_buf
		mov ax, word ptr bytes_in_buf
		mov word ptr bytes_on_row, ax
		;currRow * 16
		mov ax, word ptr currRow
		mov bx, 16
		mul bx;save in dx:ax
		;bytes_on_row -= currRow * 16
		sub word ptr bytes_on_row, ax
	doneCBOR:
		ret
show_this_row:
		;start at B800:0000
		mov ax, 0B800h
		mov es, ax
		mov di, 0000h
		call copyString
		call outputOffsets
		call outputHexData
		call outptuByteData
		call outputThisRow
		ret
copyString:
	push cx
		;copy pattern to s
		mov ax, data
		mov es, ax
		lea si, pattern
		lea di, s
		mov cx, len_pattern
		cld
		rep movsb
	pop cx
		ret
outputOffsets:
	push cx
	push bx
		mov cx, 2
		mov bx, 0
	dealWithHigher8bit:
	  push cx
		mov cl, 8
		rol word ptr currRowOffset[2], cl
		mov al, byte ptr currRowOffset[2]
		mov byte ptr xx, al
		call char2hex
	  pop cx
		add bx, 2
	  loop dealWithHigher8bit
		mov cx, 2
	dealWithLower8bit:
	  push cx
		mov cl, 8
		rol word ptr currRowOffset[0], cl
		mov al, byte ptr currRowOffset[0]
		mov byte ptr xx, al
		call char2hex
	  pop cx
		add bx, 2
	  loop dealWithLower8bit
	pop bx
	pop cx
		ret
outputHexData:
	push cx
	push bx
		mov cx, word ptr bytes_on_row
		mov bx, 10
		mov ax, word ptr currRow
	  push bx
		mov bx, 16
		mul bx
		mov word ptr curBufPos, ax
	  pop bx
	dealWithNextHexData:
	  push bx
		mov bx, word ptr curBufPos
		mov al, byte ptr buf[bx]
		mov byte ptr xx, al
	  pop bx
		call char2hex
		inc word ptr curBufPos
		add bx, 3
	  loop dealWithNextHexData
	pop bx
	pop cx
		ret
outptuByteData:
	push cx
	push bx
		mov ax, data
		mov es, ax
		mov ax, word ptr currRow
		mov bx, 16
		mul bx
		mov bx, ax
		lea si, buf[bx]
		lea di, s[59]
		mov cx, bytes_on_row
		cld
		rep movsb
	pop bx
	pop cx
		ret
outputThisRow:
		mov ax, 0B800h
		mov es, ax
		mov ax, offset s
		mov si, ax
		mov word ptr curVideoOffset, 0000h
		mov ax, word ptr currRow
		mov bx, 80*2
		mul bx
		add word ptr curVideoOffset, ax
	push cx
		mov cx, len_pattern
		mov di, word ptr curVideoOffset
		cld
		mov bx,0
	displayCurrentLine:
		lodsb ;s[bx] is now in al
		mov ah, 07h
		cmp bx, 59
	  jae Others
		cmp al, '|'
	  jne Others
	isVerticalLine:
		mov ah, 0Fh
	Others:
		stosw
		inc bx
	  loop displayCurrentLine
	pop cx
		ret
char2hex:;(char xx, char s[], index is bx, bx+1)
		push cx
		;get higher 4 bits
		mov al, byte ptr xx
		mov cl, 4
		shr al, cl
		and al, 0Fh
		push bx
		mov bx, offset t
		xlat
		pop bx
		mov byte ptr s[bx], al
		;get lower 4 bits
		mov al, byte ptr xx
		and al, 0Fh
		push bx
		mov bx, offset t
		xlat
		pop bx
		mov byte ptr s[bx+1], al
		pop cx
		ret
switchKey:
		;input key
		mov ah, 0
		int 16h
		mov byte ptr key[0], al
		mov byte ptr key[1], ah
		;which key?
		mov ax , word ptr _PageUp
		cmp word ptr key, ax
	  je PageUpPressed
		mov ax , word ptr _PageDown
		cmp word ptr key, ax
	  je PageDownPressed
		mov ax , word ptr _Home
		cmp word ptr key, ax
	  je HomePressed
		mov ax , word ptr _End
		cmp word ptr key, ax
	  je EndPressed
		;if none of above, do nothing and go to end
		jmp doneSwitchKey
	PageUpPressed:
		; offsets -= 256
		sub word ptr offsets[0], 256
		sbb word ptr offsets[2], 0
		;if offsets < 0
		cmp word ptr offsets[2], 0
	  jge doneSwitchKey
		;set it to 0
		mov word ptr offsets[0], 0
		mov word ptr offsets[2], 0
	  jmp doneSwitchKey
	PageDownPressed:
		mov dx, word ptr offsets[2]
		mov ax, word ptr offsets[0]
		add ax, 256
		adc dx, 0
		;now dx:ax is offsets+256
		cmp dx, word ptr file_size[2]
	  ja doneSwitchKey
	  jb incOffset
		cmp ax, word ptr file_size[0]
	  jae doneSwitchKey
		incOffset:
		add word ptr offsets[0], 256
		adc word ptr offsets[2], 0
	  jmp doneSwitchKey
	HomePressed:
		mov word ptr offsets[0], 0
		mov word ptr offsets[2], 0
	  jmp doneSwitchKey
	EndPressed:
		;dx:ax = file_size
		mov ax, word ptr file_size[0]
		mov dx, word ptr file_size[2]
		;dx:ax-=lastPageSize
		sub ax, word ptr lastPageSize[0]
		sbb dx, word ptr lastPageSize[2]
		;offsets = dx:ax
		mov word ptr offsets[0], ax
		mov word ptr offsets[2], dx
	  jmp doneSwitchKey
	doneSwitchKey:
		ret
closeFile:
		mov ah, 3Eh
		mov bx, handle
		int 21h
		ret
debug:
		;used for DEBUG
		mov dx, offset debugInfo
	    mov ah, 09h
	    int 21h
	    call newline
	    ret
code ends
	end main

