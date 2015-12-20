; Copyright (C) 2013-2016 Wataha.net
; All Rights Reserved
;
; LICENSE Creative Commons BY-NC-ND 4.0
; See LICENSE.TXT
;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

struc	ENTRY
	.knot_id			resq	1
	.record_size			resw	1
	.chars				resb	1
	.type				resw	1
	.name				resb	1
endstruc

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	mov	rdi,	end
	and	di,	0xF000
	add	rdi,	0x1000

	mov	ax,	0x0005
	int	0x40

	cmp	rcx,	VARIABLE_EMPTY
	je	.no_args

	; usuń nazwę procesu z linii argumentów
	sub	rcx,	rax	; oraz skróć rozmiar linii agrumentów o wyciętą nazwę procesu
	add	rdi,	rax

	call	library_find_first_word
	jnc	.no_args

	; nie mam jeszcze przekazywania z powłoki informacji o aktualnie przeglądanym katalogu
	mov	ax,	0x0402	; touch file
	mov	rbx,	0x8000	; plik
	mov	rdx,	0	; w katalogu /
	mov	rsi,	rdi
	int	0x40	; wykonaj

.no_args:
	; program kończy działanie
	xor	ax,	ax
	int	0x40	; wykonaj

%include	"library/find_first_word.asm"

end:
