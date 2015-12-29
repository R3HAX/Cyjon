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

	; pobierz argumenty
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_ARGS
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy istniały jakiekowiek
	cmp	rcx,	VARIABLE_EMPTY
	je	.end

	; wyświetl wszystkie na ekranie włącznie z nazwą wywołanego polecenia
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	rdi
	int	STATIC_KERNEL_SERVICE

	mov	rsi,	text_newline
	int	STATIC_KERNEL_SERVICE

.end:
	; koniec procesu
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

%include	'library/align_address_up_to_page.asm'

text_newline	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE,	VARIABLE_ASCII_CODE_TERMINATOR

end:
