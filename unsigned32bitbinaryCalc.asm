section .text

	global _start


_start:
	mov 	edx, welcomeMattLen 
	mov 	ecx, welcomeMatt
	mov 	ebx, stdout
	mov 	eax, sys_write
	int 0x80
	;;; welcome message for calc

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
	mov ecx, numbuf		  	;;;; going to place numbuf in ecx
	cmp eax, 0 				;;;; compare eax to zero, means no input or error. 
	jle _belowzerobin		
	cmp eax, 3 				;;; 3 means that there is only one bit to do something with.
	je _justonenum 			;;; jump to label handling that.
	inc ecx					;;; increase ecx so that you are at the first bit from the left.
	_checkbin: 					;;; serve two functions here, iterate through each byte for 1 and 0
		cmp byte [ecx], one 	;;; compare agains ascii
		jne _zerocheck 			;;; if not equal go to zero
		inc ecx  				;;;; move to next memory address
		jmp _checkbin 			;;; move back to jump to look at it again
	_zerocheck: 				;;; check for zero
		cmp byte [ecx], zero 	;;; do a comparison
		jne _newlinecheck 		;;; if not 0 go to newline check
		inc ecx 				;;; if zero move to next memory address.
		jmp _checkbin 			;;; and move back up to loop.
	_newlinecheck: 				;;;; check for newline here
		cmp byte [ecx], newl    ;;; compare for newline, ecx is now at the end of numbuf.
		je _binaddition 		;;; jmp to next label if newline			
		jmp _notbin 			;;; jump to error if none of these conditions are true. 


_binaddition:
	dec ecx 					;;; current memory at ecx is pointed at newline, decrease to point at bit at the end.
	cmp byte [ecx], one 		;;; compare for one.
	jne _skipaddone 			;;; if not one, skip adding the 1 bit
	add dword [tmpbuf], 1 		;;; add one bit in tmpbuf, tmpbuf will be our value that will indicate the current bits value.
								;;; 1, 2, 4, 8, etc, etc
	_skipaddone: 				;;; ebx is going to be our counter
		mov ebx, 1 				;;; put 1 in counter 
		dec ecx 				;;; go to next bit shift right in memory.
	_domath: 					;;;; coordinate the ascii to fix the bits where they are to the bit they turn into. 
		cmp byte [ecx], one 	;;;; if ascii one add 1 multiplied by what the  bit's value is. 1 2 4 8 16 etc.... etc....located in ebx
		je _ifone 				
		cmp byte [ecx], zero 	;;; if ascii zero jump to label
		je _ifzero 				
		cmp ecx, numbuf 		;;; compare ecx to the original memory address at the start of our ascii
		je _checkmath 			;;; if so we know we are done. 


_ifone:
	mov eax, 2 					;;; multiply ebx by 2 here.
	mul ebx 				
	add eax, edx 				;;; result is in eax, edx
	mov ebx, eax 				;;; add together for the product, place the next value to multiply by. 
	add dword [tmpbuf], eax 	;;; add to whatever current value is to tmpbuf our decimal/hex num
	dec ecx 			  		;;; move back a mem address
	jmp _domath 				;;; go back to domath loop

_ifzero: 						;;; does the same thing for ifone skipping the addition of the bit value
	mov eax, 2 					;;; because it's a zero. 
	mul ebx
	add eax, edx
	mov ebx, eax
	dec ecx
	jmp _domath


_justonenum: 					;;; if we only had one bit, it would be either 0 or one, if it's 0 error out. 
	inc ecx 
	cmp byte [ecx], zero
	je _belowzerobin
	mov dword [tmpbuf], 1 		;;; if 1 place into tmpbuf.

_checkmath:
	mov edx, [tmpbuf] 			;;; move tmpbuf into edx
	mov [inallcount], edx       ;;;; move edx, into inallcount
	mov ecx, numbuf				;;;; back to original pointer at the front of my input. 
	cmp byte [ecx], plus 	;;;; check first byte for which sign it actual is.
	je _addbin		 		;;;; go to the function based on the sign, see below for the same thing for each sign.

	cmp byte [ecx], minus
	je _minusbin

	cmp byte [ecx], mult
	je _multibin

	cmp byte [ecx], divide
	je _dividebin

	cmp byte [ecx], mod
	je _modbin

	jmp _wrongmath
									;;;;; we do all the same things we do in the previous calculator except we are using the whole register for unsigned values.
_addbin:							;;;; ignore comments from caveman calculator.
	mov  ebx, [inallcount]					
	add  [outcount], ebx				;
	cmp  dword [outcount], 0xFFFFFFFF		
	jl _overbin					
	jmp _printall 						

_minusbin:
	mov ebx, [inallcount]				
	cmp  ebx, [outcount]			
	jge _belowzerobin 					
	sub  [outcount], ebx 		 
	cmp  dword [outcount], 0    	
	jge _belowzerobin 					
	jmp _printall 					

_multibin:
	mov eax, [inallcount]  				
	mul dword [outcount] 			
	add eax, edx 						
	mov [outcount], eax 				
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

	
_printall: 						;;;; now that math is done, time to convert bits to ascii one's and zeros
	mov byte [oneflag], 0  		;;;; going to use a flag so we can ignore the leading zeros, we won't start counting length until that is turned on.
	mov dword edx, [outcount] 	;;; send the math result here.
	mov dword [tmpbuf], edx 	;;; move result into tmpbuf, reusing this one again. 
	mov ecx, outbuf 			;;; move our memory address to the beginning of our output.
	mov byte [ecx], equal 		;;; put equal sign in there. 
	inc ecx 					;;;; move to the next bit on the right. forwards to backwards this time. 
	mov dword [divcount], 0xFFFFFFFF  		;;;; This is the max value that we can do, we will divide each by two and subtract from outcount, 
	mov ebx, 0 					;;;; our counter for the length of bytes.
	_filloutbuf:  				;;; our main loop for adding to tmpbuf.
		cmp dword [outcount], 0 	;;;; if the last bit is 0 go here. 
		je _addlast0
		cmp dword [outcount], 1 	;;; if the last bit is 1 go here. 
		je _addlast1
		mov dword eax, [outcount] 	;;; move outcount to eax,
		cmp dword eax, [divcount]   ;;;; compare outcount to divcount
		jbe _zerofill 				;;;; add a 0, it will only actually add an ascii zero once a 1 has been seen. if outcount is less than divcount it's a zero. 
		jmp _onefill  				;;;; add a 1, the oneflag will go from 0 to 1 if not already so, and ascii zeros will now be added to the buffer.


_onefill: 							;;;; function for adding an ascii one if divcount is less than outcount
	mov dword eax, [divcount] 		;;;; I will check to see if oneflag has been flipped to indicate add 1 to divcount, this is because FFFFFFFF can't have 1 added to it
	sub dword [outcount], eax 		;;; cheater way is just to do it after you've divided it in half. 7FFFFFFF will turn to 80000000
									;;; subtract divcount from outcount 
	push ecx 						;;; running out of registers here, let me just push the mem address to the stack
	mov edx, 0 						;;; zero out edx
	mov eax, [divcount] 			;;;; but divcount into eax
	mov ecx, 2 						;;; move a 2 here indicating divide eax by ecx
	div ecx 						;;; result is in eax:edx
	_firstadd:
		cmp byte [oneflag], 0
		jne _notfirstadd
		inc eax 					;;;; add 1 to the first divide one. 
	_notfirstadd:
		mov dword [divcount], eax 	;;; put the half as the new divcount 
		pop ecx 					;;; alright gib mem address back please!
		mov byte [ecx], one 		;;; put an ascii one in the mem address
		inc ecx 					;;; move to next mem address
		mov byte [oneflag], 1 		;;; put the oneflag to true. 
		inc ebx 					;;; add 1 to our counter for the length to print. 
		jmp _filloutbuf 			;;; go back up to loop 

_zerofill:
	push ecx 						;;; save mem address so I can use ecx
	mov edx, 0 						;;; zero out edx
	mov eax, [divcount] 			;;;; still do the divide but add a zero ascii if oneflag is true.
	mov ecx, 2 			
	div ecx
	mov dword [divcount], eax
	pop ecx 
	cmp byte [oneflag], 0
	je _notoneflag 					;;; if oneflag is false, you don't want to increase the length to print out.
	mov byte [ecx], zero 			;;; if true, actually add the zero, the first bit printed out is always an ascii one.
	inc ecx 						;;;; move to next mem address
	inc ebx 						;;; increase our length counter
	jmp _filloutbuf 				;;; back to loop

_notoneflag:
	jmp _filloutbuf 				;;; get here if 0 and oneflag is 0 or false. this is so you don't have all those leading zeros printed out. 
	
_addlast0:
	inc ebx 						;;; if the last bit to print out is a 1 add a 1 and go to print. (number is odd)
	mov byte [ecx], zero
	jmp _done

_addlast1:
	inc ebx 						;;;; if last bit to print is a zero (or even number print an ascii zero. )
	mov byte [ecx], one

_done:
	mov edx, [tmpbuf]
	mov [outcount], edx 			;;; set outcount to original to use. 
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






