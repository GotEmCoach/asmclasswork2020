

;;;;;;;;;;;;;;;;;;;;;;; macros because i'm lazy and proud of it ;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro write_output 2
	
	mov edx, %2
	mov ecx, %1
	mov ebx, stdout			
	mov eax, sys_write
	int 80h

%endmacro

%macro read_input 2

	mov edx, %2
	mov ecx, %1
	mov ebx, stdin
	mov eax, sys_read
	int 80h

%endmacro

section .text

	global _start

_start: 
	read_input verybigbuf, 16777216 ;;;;;;; get our input however big. 

_inputcheck: 			;;;; check so it's not zero, error down below if so.
	cmp eax, 0
	je _noinput

_initializetheMACHINE: 			
	mov ebx, 0
									;;; you either see another one anyways. 
	mov [totalchars], eax			;;; save the amount of characters that were read in.
	inc dword [totalchars]
	push success		 			;;; push this on the stack to be the first thing, I know at the end 
									;;; if we are good by checking for success message.
	mov ebx, 1						;;; intiate our counter with a 1, cause the first byte is checked after. 
_checkBytebyByte:
	cmp byte [ecx], brackbeg 		;;; check for [
	je _brackpush					;;; pop it lock it, don't drop it though. 
	cmp byte [ecx], parenbeg		;;;; check for (
	je _parenpush
	cmp byte [ecx], curlybeg		;;; check for {
	je _curlypush
	cmp byte [ecx], brackend 		;;; check stack at called function for open [
	je _brackpop
	cmp byte [ecx], parenend 		;;; check stack at called fucntion for open (
	je _parenpop
	cmp byte [ecx], curlyend 		;;; check stack at called function for open {
	je _curlypop
	cmp byte [ecx], sinquote 		;;; jump to single quote looped loop
	je _singlequoteon
	cmp byte [ecx], dubquote 		;;;; jump to double quote looped loop
	je _doublequoteon						
	cmp [totalchars], ebx 			;;; ebx is our counter, going to use this so that I can give better error checks. 
	je _exitchecks 					;;; if you reach the end, lets check the stack for anything left.
	inc ebx
	inc ecx							;;; if we are not at the end at this point, +1 to our counter.
	jmp _checkBytebyByte 			;;; jmp back up to check the next byte. 


_singlequoteon:
	inc ecx							;;; no reason to put this bad boi on the stack, just look for next one.
	inc ebx							;;; you are ignoring everything but another one anyways.
	cmp byte [ecx], sinquote
	je _singlequoteoff
	cmp [totalchars], ebx 			;;; we still have the counter going, if we reach the end, no bueno. 
	je _nomatchsinquote 			;;; go to error, not liable for any hurt feelings. 
	jmp _singlequoteon
	_singlequoteoff:
		inc ecx
		jmp _checkBytebyByte

_doublequoteon:
	inc ecx 							;;;;;; this will continue to loop until another quote is met. 
	inc ebx								;;;; it will continue matching after it finds one, 
	cmp byte [ecx], dubquote			;;; if none is found error out.
	je _doublequoteoff
	cmp [totalchars], ebx
	je _nomatchdubquote
	jmp _doublequoteon
	_doublequoteoff:
		inc ecx
		jmp _checkBytebyByte

_brackpush:
	push ecx 							;;; push [ on the stack
	inc ecx
	inc ebx
	jmp _checkBytebyByte	

_parenpush: 							;;;; push a ( on the stack
	push ecx
	inc ecx
	inc ebx
	jmp _checkBytebyByte


_curlypush:
	push ecx
	inc ecx 							;;;;;; push a { on the stack
	inc ebx
	jmp _checkBytebyByte

_brackpop:
	mov eax, ecx 			;;;; move current byte location to eax
	pop ecx 				;;; pop to see what's on top of the stack
	cmp byte [ecx], brackbeg 		;;;; compare the top of the stack to a open [
	jne _rightsymbrack   					;;;  jump to error if not the case.
	mov ecx, eax 			;;; otherwise you have taken it off the stack and you can overwrite the pop
							;;;; with current location. 
	inc ecx 				;;; next byte please
	inc ebx 				;;;; +1 counter
	jmp _checkBytebyByte 	;; back to good ole loop

_rightsymbrack:
	push eax
	write_output rightsymbol, rightsymbolLen
	mov byte [tmpbuf], brackend
	write_output tmpbuf, 1
	jmp _nomatch

_parenpop:
	mov eax, ecx 			;;;; move current byte location to eax
	pop ecx 				;;; pop to see what's on top of the stack
	cmp byte [ecx], parenbeg 		;;;; compare the top of the stack to a open (
	jne _rightsymparen				;;;  jump to error if not the case.
	mov ecx, eax 			;;; otherwise you have taken it off the stack and you can overwrite the pop
							;;;; with current location. 
	inc ecx 				;;; next byte please
	inc ebx 				;;; +1 counter
	jmp _checkBytebyByte 	;;; back to good ole loop at top

_rightsymparen:
	push eax
	write_output rightsymbol, rightsymbolLen
	mov byte [tmpbuf], parenend
	write_output tmpbuf, 1
	jmp _nomatch

_curlypop:
	mov eax, ecx 			;;;; move current byte location to eax
	pop ecx 				;;; pop to see what's on top of the stack
	cmp byte [ecx], curlybeg 		;;;; compare the top of the stack to a open {
	jne _rightsymcurly   					;;;  jump to error if not the case.

	mov ecx, eax 			;;; otherwise you have taken it off the stack and you can overwrite the pop
							;;;; with current location. 
	inc ecx 				;;; next byte please
	inc ebx 				;;;; +1 counter
	jmp _checkBytebyByte 	;;; back to good ole loop at top

_rightsymcurly:
	push eax
	write_output rightsymbol, rightsymbolLen ;;;; the right symbol that should of been entered here
	mov byte [tmpbuf], curlyend
	write_output tmpbuf, 1
	jmp _nomatch

_exitchecks:
	pop ecx
	cmp ecx, success 				;;;; this function will display success if everything was correct. 
	je _shoutsuccess
	write_output ecx, 1
	jmp _notfinished

_nomatch:
	write_output wrongsymbol, wrongsymbolLen
	pop eax 						
	write_output eax, 1
	jmp _exit    ;;;; exit after you display the wrong symbol that was inputted. 


_shoutsuccess: 
	write_output success, successLen

_exit:
	mov ebx, 0
	mov eax, 1
	int 0x80





;;;;;;;;;;;;;;;;;;;;;;;;;;;; errors, abort ABORT, MAYDAY, MAYDAY ;;;;;;;;;;;;;;;;;;;
_noinput:
	write_output noin, noinLen
	jmp _exit

_nomatchsinquote:
	write_output sinnomatch, sinnomatchLen
	jmp _exit

_nomatchdubquote:
	write_output dubnomatch, dubnomatchLen
	jmp _exit

_nomatchmsg:
	write_output nomatch, nomatchlen
	jmp _exit

_notfinished:
	write_output notfinished, notfinishedlen
	jmp _exit

section .data
	noin 		db "No input was given, do you not trust me <insert wincing hurt guy meme here>",newl
	noinLen		equ $ - noin

	sinnomatch 	db "OOOOFFFFF, you didn't match that last single quote before input finished",newl
	sinnomatchLen	equ $ - sinnomatch

	dubnomatch 	db "Dang, you must of failed grammer class. Missing ending double quote.",newl
	dubnomatchLen	equ $ - dubnomatch

	rightsymbol	db "The right symbol was: "
	rightsymbolLen equ $ - rightsymbol

	wrongsymbol db "you instead placed: "
	wrongsymbolLen	equ $ - wrongsymbol

	nomatch	db "That did not match, you are the weakest link, GOODBYE!",newl
	nomatchlen	equ $ - nomatch

	notfinished db "You still had more brackets, curlys, or parens to close",newl
	notfinishedlen equ $ - notfinished

	success		db "Yay, you did it.",newl
	successLen	equ $ - success
section .bss

	verybigbuf resb 	 16777216 ;;; about 33 MB of reserved space, too much?
	tmpbuf			resb 1			;;; wordbuf for words in no matchy statement.
	totalchars		resb 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;; DNS Server because me dumb human. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

brackbeg		equ		5bh
brackend		equ		5dh
parenbeg		equ		28h
parenend		equ 	29h
curlybeg		equ 	7bh
curlyend		equ		7dh
dubquote		equ 	22h
sinquote 		equ 	27h
flagon 			equ 	01h
flagoff			equ		00h
sys_read 		equ 	03h
sys_write		equ		04h
stdin			equ		00h
stdout			equ		01h
stderr			equ		02h
newl			equ     0Ah





