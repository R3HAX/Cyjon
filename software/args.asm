; Copyright (C) 2013-2015 Wataha.net
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

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; zapisz listę przesłanych argumentów w dane miejsce
	mov	rdi,	end
	call	library_align_address_up_to_page

	mov	ax,	0x0005
	int	0x40

	cmp	rcx,	VARIABLE_EMPTY
	je	.end

	mov	ax,	0x0101
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	rdi
	int	0x40

	mov	rsi,	text_newline
	int	0x40

.end:
	xor	ax,	ax
	int	0x40

%include	'library/align_address_up_to_page.asm'

text_newline	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE,	VARIABLE_ASCII_CODE_TERMINATOR

end:
