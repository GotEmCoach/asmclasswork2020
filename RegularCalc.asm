section .text

	global _start


_start:
	mov 	edx, welcomeMattLen 
	mov 	ecx, welcomeMatt
	mov 	ebx, stdout
	mov 	eax, sys_write
	int 0x80
	;;; welcome message from caveman

_get_bin:
	;;;;;; print out a new line for beauty.
	mov edx, newlineLen
	mov ecx, newline
	mov ebx, stdout
	mov eax, sys_write
	int 0x80

	;;;; read the input from users, put it into numbuf. 
	mov edx, 256
	mov ecx, numbuf
	mov ebx, stdin
	mov eax, sys_read
	int 0x80

_checkinput:
	mov ecx, numbuf
	cmp eax, 0 				;;;; compare eax to zero, means no input or error. 
	jle _belowzerobin				;;;; jump to error message if 0 or less
	cmp eax, 3
	je _justonenum
	inc ecx
	_checkbin:
		cmp byte [ecx], one
		jne _zerocheck
		inc ecx
		jmp _checkbin
	_zerocheck:
		cmp byte [ecx], zero
		jne _newlinecheck
		inc ecx
		jmp _checkbin
	_newlinecheck:
		cmp byte [ecx], newl
		je _binaddition
		jmp _notbin


_binaddition:
	dec ecx
	cmp byte [ecx], one
	jne _skipaddone
	add dword [tmpbuf], 1
	_skipaddone:
		mov ebx, 1
		dec ecx
	_domath:
		cmp byte [ecx], one
		je _ifone
		cmp byte [ecx], zero
		je _ifzero
		cmp ecx, numbuf
		je _checkmath


_ifone:
	mov eax, 2
	mul ebx
	add eax, edx
	mov ebx, eax
	add dword [tmpbuf], eax
	dec ecx
	jmp _domath

_ifzero:
	mov eax, 2
	mul ebx
	add eax, edx
	mov ebx, eax
	dec ecx
	jmp _domath


_justonenum:
	inc ecx
	cmp byte [ecx], zero
	je _belowzerobin
	mov dword [tmpbuf], 1

_checkmath:
	mov edx, [tmpbuf]
	mov [inallcount], edx
	mov ecx, numbuf		;;;; back to original pointer at the front of my input. 
	cmp byte [ecx], plus ;;;; check first byte for which sign it actual is.
	je _addbin		 ;;;; go to the function based on the sign, see below for the same thing for each sign.

	cmp byte [ecx], minus
	je _minusbin

	cmp byte [ecx], mult
	je _multibin

	cmp byte [ecx], divide
	je _dividebin

	cmp byte [ecx], mod
	je _modbin

	jmp _wrongmath

_addbin:
	mov  ebx, [inallcount]					;;;;; move data at incount (amount of pebbles in two byte form. ) to BX.
	add  [outcount], ebx				;;;; add BX to data at buffer [outcount]
	cmp  dword [outcount], 0xFFFFFFFF		;;;; check if outcount is greater than or equal to 256 after operation
	jl _overbin					;;;; if so go to error.
	jmp _printall 						;;;; go to label to print out the pebbles based on outcount

_minusbin:
	mov ebx, [inallcount]				;;;; move data at incount (pebble num) to BX
	cmp  ebx, [outcount]			;;; compare BX, if the number subtracted is bigger than what in our outcount, don't waste effort subtracting.
	jge _belowzerobin 					;;;; jump to error if above is true. 
	sub  [outcount], ebx 		;;; else do math. 
	cmp  dword [outcount], 0    	;;; make sure math doesn't come out zero if so go to errors to report no pebbles.
	jge _belowzerobin 					;;;; *
	jmp _printall 					;;; print pebbles otherwise. 

_multibin:
	mov eax, [inallcount]  				;;;; putting incount in AX which gets multiplied to whatever is iin the mul line.
	mul dword [outcount] 			;;; multiply outcount by AX, result gets put in AX:DX
	add eax, edx 						;;;; just add thm together. put in AX
	mov [outcount], eax 				;;;; move AX in outcount for result.
	cmp dword [outcount], 0xFFFFFFFF  	;;; if result is greater than 255 jump to error
	jg _overbin
	jmp _printall 					;;;;; print pebbles otherwise

_dividebin:
	mov  ebx, [inallcount]
	mov  eax, [outcount] 				;;;; put incount in eax, will put it in AX, this is where the divider goes. 
	mov edx, 0				;;;; zero out edx, contain our result.  
	cmp  ebx, [outcount] 		;;; AX is our divider. if divider is greater than outcount no thanks go to error.
	jg _belowzerobin  					;;; ^
	div dword [inallcount]				;;;; divide AX by incount, if were to need it, remainder is in DX. 
	mov [outcount], eax				;;; AX will contain the quotient after divide here. 
	jmp _printall

_modbin:
	mov  ebx, [inallcount]
	mov eax, [outcount] 				
	mov edx, 0					;;;; zero out edx, contain our result.  
	cmp  ebx, [outcount]  		;;; AX is our divider. if divider is greater than outcount no thanks go to error.
	jge _belowzerobin				;;; ^
	div dword [inallcount] 			;;;; divide outcount by AX, if were to need it, remainder is in DX. 
	mov  [outcount], edx			;;;; like stated above, remainder should be what's in outpebbles	
	cmp dword [outcount], 0     ;;; check for zero, don't waste printing pebbles. 
	je _belowzerobin
	jmp _printall

	
_printall:
	mov byte [oneflag], 0
	mov dword edx, [outcount]
	mov dword [tmpbuf], edx
	mov ecx, outbuf
	mov byte [ecx], equal
	inc ecx
	mov dword [divcount], 0xFFFFFFFF
	mov ebx, 0
	_filloutbuf:
		cmp dword [outcount], 0
		je _addlast0
		cmp dword [outcount], 1
		je _addlast1
		mov dword eax, [outcount]
		cmp dword eax, [divcount]
		jbe _zerofill
		jmp _onefill


_onefill:
	mov dword eax, [divcount]
	sub dword [outcount], eax
	push ecx
	mov edx, 0
	mov eax, [divcount]
	mov ecx, 2
	div ecx
	_firstadd:
		cmp byte [oneflag], 0
		jne _notfirstadd
		inc eax
	_notfirstadd:
		mov dword [divcount], eax
		pop ecx
		mov byte [ecx], one
		inc ecx
		mov byte [oneflag], 1
		inc ebx
		jmp _filloutbuf

_zerofill:
	push ecx
	mov edx, 0
	mov eax, [divcount]
	mov ecx, 2
	div ecx
	mov dword [divcount], eax
	pop ecx
	cmp byte [oneflag], 0
	je _notoneflag
	mov byte [ecx], zero
	inc ecx
	inc ebx
	jmp _filloutbuf

_notoneflag:
	jmp _filloutbuf
	
_addlast0:
	inc ebx
	mov byte [ecx], zero
	jmp _done

_addlast1:
	inc ebx
	mov byte [ecx], one

_done:
		 				 			;;; the number of bytes to print is outcount, outcount which contains the number of characters to output is already ther
	mov edx, ebx
	mov ecx, outbuf 				;;; all the pebbles are in here. 
	mov ebx, stdout 				;;;; slap that bad boy on the terminal screen.
	mov eax, sys_write 				;;; ^
	int 80h
	dec eax							;;; bring total of bytes written back to our count without = sign. 						
	jmp _get_bin 					;;; jump to the top and do it all again, the only persist thing should be our outcount buffer. 

;;;;;;; section for all error messages ;;;;;;;
_notbin:
	mov dword [outcount], 0
	mov edx, notbinaryLen
	mov ecx, notbinary
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_bin

_overbin:
	mov dword [outcount], 0
	mov edx, over32bitLen
	mov ecx, over32bit
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_bin

_belowzerobin:
	mov dword [outcount], 0
	mov edx, belowzeroLen
	mov ecx, belowzero
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_bin

_wrongmath:
	mov dword [outcount], 0
	mov edx, invalidsignLen
	mov ecx, invalidsign
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_bin

section .data
	
	;;;; welcome message, caveman style ;;;
	welcomeMatt		db "Welcome to my unsigned 32 bit calculator"
	welcomeMattLen	equ	$ - welcomeMatt

	newline			db newl
	newlineLen		equ $ - newline

	;;;;; errors to print ;;;;;;;
	notbinary		db "You sir, have entered a non binary number."
	notbinaryLen	equ $ - notbinary

	over32bit		db "you are over the 32 bit limit, settle down there guy."
	over32bitLen	equ $ - over32bit

	belowzero		db "you cannot subtract more than you already have."
	belowzeroLen	equ $ - belowzero

	invalidsign		db "you have not used a correct sign."
	invalidsignLen	equ $ - invalidsign



section .bss
	numbuf		resb 34
	outbuf		resb 33 ;;; same as above but for output.
	inallcount	resb 4 
	incount		resb 2 ;; this will store value in 4 byte buffer.
	outcount	resb 4 ;; same as above.
	tmpbuf		resb 5
	countbuf	resb 1
	tmpnum		resb 2
	oneflag		resb 1
	divcount	resb 5
;;; definitions for ease here ;;;
sys_read 	equ 	03h
sys_write	equ		04h
stdin		equ		00h
stdout		equ		01h
stderr		equ		02h
mod			equ		25h
mult		equ		2Ah
plus		equ		2Bh
minus		equ		2Dh
divide		equ		2Fh
newl		equ		0Ah
equal		equ		3Dh
exit		equ		78h
one 		equ 	31h
zero 		equ 	30h






