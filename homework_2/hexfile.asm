;2015-12-30 18:00:00 ~
data segment
	_PageUp       dw	4900h
	_PageDown     dw	5100h
	_Home         dw	4700h
	_End          dw	4F00h
	_Esc          dw	011Bh
	filename      db    101
			      db    ?
			      db    101 dup(0)
	buf           db    256 dup(?)
	notice        db    'Please input filename:$'
	errorOpenFile db    'Cannot open file!$'
	handle        dw    ?
	key           dw    ?
	bytes_in_buf  dw    ?
	debugInfo     db    '---------DEBUG----------!$'
	file_size     dd    ?
	offsets       dd    ?
	n             dd    ?
data ends
mystack segment
	    dw 100h dup(?)
mystack ends
code segment
	assume cs:code, ds:data, ss:mystack
	main:
	    mov ax, data
	    mov ds, ax
	    call showNotice
	    call inputFileName
	    call openFile
	    call checkIfOpenFileFailed
	    call getFileSize
	    call mainLoops
	    call closeFile
	    mov ah, 4ch
	    int 21h
	   	;Below is the subFunctions
closeFile:
		mov ah, 3Eh
		mov bx, handle
		int 21h
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
		;maybe omitted
		mov dx, data
		mov ds, dx
		;maybe omitted
		mov dx, offset buf
		int 21h
		ret
show_this_page:
		;TODO

		ret
switchKey:
		;TODO
		mov ah, 0
		int 16h

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
		;TODO division
		jmp doneSwitchKey
	doneSwitchKey:
		ret
mainLoops:
		;init offset
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
getFileSize:
		mov ah, 42h
		mov al, 2
		mov bx, handle
		mov cx, 0
		mov dx, 0
		int 21h
		mov word ptr file_size[2], dx
		mov word ptr file_size[0], ax
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
checkIfOpenFileFailed:
		jc  errorOpening
		mov handle, ax
		ret
openFile:
		;NOTICE:filename should be end by 0 or $
		mov ah,3Dh
		mov al,0
		mov dx, offset filename+2
		int 21h
		ret
inputFileName:
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
showNotice:
	    ;output notice
	    mov dx, offset notice
	    mov ah, 09h
	    int 21h
	    call newline
	    ret
debug:
		;DEBUG
		mov dx, offset debugInfo
	    mov ah, 09h
	    int 21h
	    call newline
	    ret
newline:
		;output enter
	    mov ah, 2
	    mov dl, 0Dh
	    int 21h
	    ;output newline
	    mov ah, 2
	    mov dl, 0Ah
	    int 21h
	    ret
code ends
	end main
