section .text

	global _start


_start:
	mov 	edx, welcomeMattLen 
	mov 	ecx, welcomeMatt
	mov 	ebx, stdout
	mov 	eax, sys_write
	int 0x80
	;;; welcome message from caveman

_get_pebs:
	;;;;;; print out a new line for beauty.
	mov edx, newlineLen
	mov ecx, newline
	mov ebx, stdout
	mov eax, sys_write
	int 0x80

	;;;; read the input from users, put it into pebblebuffer. 
	mov edx, 256
	mov ecx, pebblebuffer
	mov ebx, stdin
	mov eax, sys_read
	int 0x80

_checkinput:
	mov esi, ecx
	cmp AX, 0 				;;;; compare eax to zero, means no input or error. 
	jle _nopebbles 			;;;; jump to error message if 0 or less
	cmp AX, 0x0100 	;;; this is equivalent to 256, you should not ave more than 255 pebbles plus the sign iin front. 
	jge _pebbletoohigh    	;;;; jump to error message if above is true. 
	
_numpebs:
	dec AX					;;; subtract one for math symbol.
	dec AX					;;; subtract one for newline. 
	mov word [incount], AX	;;; move that to our 2 byte buffer incount
	mov DX, 0x0000			;;; zero out DX for use as our 2byte counter. 

_checkpebs:
	inc ecx 				;;; increase mem address by 1 word, to skip math sign.'
	inc DX					;;; add 1 in DX (lower word of EDX) for pebble count.
	cmp word DX, [incount]	;;;; compare DX and jmp if equal to incount (number of pebbles.)
	je _checkmath 			;;;; ^
	cmp byte [ecx], pebble  ;;;; this symbol (function) is to check all byte by byte to make sure all are pebbles
	jne _notapebble 		;;;; if one of them are not a pebble, go ahead to error. 
	jmp _checkpebs          ;;;; jump back up should exit label when DX = [incount]


_checkmath:
	mov ecx, esi		;;;; back to original pointer at the front of my input. 
	cmp byte [ecx], plus ;;;; check first byte for which sign it actual is.
	je _addpebs 		 ;;;; go to the function based on the sign, see below for the same thing for each sign.

	cmp byte [ecx], minus
	je _minuspebs

	cmp byte [ecx], mult
	je _multipebs

	cmp byte [ecx], divide
	je _dividepebs

	cmp byte [ecx], mod
	je _modpebs

	jmp _wrongmath

_addpebs:
	mov BX, [incount]				;;;;; move data at incount (amount of pebbles in two byte form. ) to BX.
	add word [outcount], BX			;;;; add BX to data at buffer [outcount]
	cmp word [outcount], 0x0100		;;;; check if outcount is greater than or equal to 256 after operation
	jge _pebbletoohigh				;;;; if so go to error.
	jmp _printall 					;;;; go to label to print out the pebbles based on outcount

_minuspebs:
	mov BX, [incount]				;;;; move data at incount (pebble num) to BX
	cmp word BX, [outcount]			;;; compare BX, if the number subtracted is bigger than what in our outcount, don't waste effort subtracting.
	jge _nopebbles 					;;;; jump to error if above is true. 
	sub word [outcount], BX 		;;; else do math. 
	cmp word [outcount], 0x0000    	;;; make sure math doesn't come out zero if so go to errors to report no pebbles.
	jle _nopebbles 					;;;; *
	jmp _printall 					;;; print pebbles otherwise. 

_multipebs:
	mov AX, [incount]  				;;;; putting incount in AX which gets multiplied to whatever is iin the mul line.
	mul word [outcount] 			;;; multiply outcount by AX, result gets put in AX:DX
	add AX, DX 						;;;; just add thm together. put in AX
	mov [outcount], AX 				;;;; move AX in outcount for result.
	cmp word [outcount], 0x0100  	;;; if result is greater than 255 jump to error
	jge _pebbletoohigh
	jmp _printall 					;;;;; print pebbles otherwise

_dividepebs:
	mov word BX, [incount]
	mov word AX, [outcount] 				;;;; put incount in eax, will put it in AX, this is where the divider goes. 
	mov DX, 0x0000				;;;; zero out edx, contain our result.  
	cmp word BX, [outcount] 		;;; AX is our divider. if divider is greater than outcount no thanks go to error.
	jg _nopebbles  					;;; ^
	div word [incount]				;;;; divide AX by incount, if were to need it, remainder is in DX. 
	mov [outcount], AX				;;; AX will contain the quotient after divide here. 
	jmp _printall

_modpebs:
	mov word BX, [incount]
	mov AX, [outcount] 				
	mov DX, 0x0000					;;;; zero out edx, contain our result.  
	cmp word BX, [outcount]  		;;; AX is our divider. if divider is greater than outcount no thanks go to error.
	jge _nopebbles  				;;; ^
	div word [incount] 			;;;; divide outcount by AX, if were to need it, remainder is in DX. 
	mov word [outcount], DX			;;;; like stated above, remainder should be what's in outpebbles	
	cmp word [outcount], 0x0000     ;;; check for zero, don't waste printing pebbles. 
	je _nopebbles
	jmp _printall

	
_printall: 
	mov ecx, outbuf 				;;;;; my buffer for priinting the pebbles out. 
	mov byte [ecx], equal			;;;; put an equal in the first byte.
	inc ecx 						;;;; move to the next byte, memory address gets a plus 1 here
	mov DX, 0x0000 					;;;; lets get that pebble counter out, zero out lower half of edx, cause were only working with 2 bytes.
	_printpebs:						;;; pebble addr loop to add all the pebbles
		mov byte [ecx], pebble 		;;; put the pebble in byte after whatever byte you inc ecx from. 
		add word DX, 0x0001			;;;; add 1 to DX
		inc ecx   					;;;;  move to next byte 
		cmp word DX, [outcount]  	;;; compare counter (DX) to outcount, if [outcount] is not equal to counter, keep putting them pebbles in. 
		jne _printpebs 				;;;; loopy de loop and pull, and your buffer is looking cool. 

_done:
	inc DX 				 			;;; the number of bytes to print is outcount, outcount which contains the number of characters to output is already there
									;;; increase by one so that you account for = sign. 
	mov ecx, outbuf 				;;; all the pebbles are in here. 
	mov ebx, stdout 				;;;; slap that bad boy on the terminal screen.
	mov eax, sys_write 				;;; ^
	int 80h
	dec eax							;;; bring total of bytes written back to our count without = sign. 						
	mov [outcount], eax 			;;;; now move it to our pebble count. 
	jmp _get_pebs 					;;; jump to the top and do it all again, the only persist thing should be our outcount buffer. 

;;;;;;; section for all error messages ;;;;;;;
_notapebble:
	mov word [outcount], 0x0000
	mov edx, notpebbleLen
	mov ecx, notpebble
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_pebs

_wrongmath:
	mov word [outcount], 0x0000
	mov edx, symwrongLen
	mov ecx, symwrong
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_pebs

_pebbletoohigh:
	mov word [outcount], 0x0000
	mov edx, toomuchpebsLen
	mov ecx, toomuchpebs
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_pebs

_nopebbles:
	mov word [outcount], 0x0000
	mov edx, nomopebsLen
	mov ecx, nomopebs
	mov ebx, stdout
	mov eax, sys_write
	int 80h
	jmp _get_pebs

section .data
	
	;;;; welcome message, caveman style ;;;
	welcomeMatt		db "Hello, Me do maths with pebbles"
	welcomeMattLen	equ	$ - welcomeMatt

	;;;;; errors to print ;;;;;;;
	toomuchpebs		db "ooh, aah, too much pebbles, need less"
	toomuchpebsLen	equ	$ - toomuchpebs

	notpebble		db "oooh, you give me not pebble, head hurt bad"
	notpebbleLen	equ $ - notpebble

	symwrong		db "I do nothing, cause give me nothing"
	symwrongLen		equ $ - symwrong

	nomopebs		db "I have no more pebbles, me scratch head"
	nomopebsLen		equ $ - nomopebs

	newline			db newl
	newlineLen		equ $ - newline

section .bss
	pebblebuffer	resb 256 ;;; reserve a 256 words for usage with input.
	outbuf		resb 256 ;;; reserve a 1 word for max output of 256 in decimal. 
	incount		resb 4
	outcount	resb 4

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
pebble		equ		6Fh
newl		equ		0Ah
equal		equ		3Dh
exit		equ		78h
zero		equ		00h
