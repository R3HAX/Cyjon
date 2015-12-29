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
	mov	rdi,	end
	and	di,	0xF000
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE

	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_ARGS
	int	STATIC_KERNEL_SERVICE

	cmp	rcx,	VARIABLE_EMPTY
	je	.no_args

	; usuń nazwę procesu z linii argumentów
	sub	rcx,	rax	; oraz skróć rozmiar linii agrumentów o wyciętą nazwę procesu
	add	rdi,	rax

	call	library_find_first_word
	jnc	.no_args

	; nie mam jeszcze przekazywania z powłoki informacji o aktualnie przeglądanym katalogu
	mov	ax,	VARIABLE_KERNEL_SERVICE_FILESYSTEM_TOUCH
	mov	rbx,	VARIABLE_FILESYSTEM_TYPE_FILE	; plik
	mov	rdx,	0	; w katalogu /
	mov	rsi,	rdi
	int	STATIC_KERNEL_SERVICE	; wykonaj

.no_args:
	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE	; wykonaj

%include	"library/find_first_word.asm"

end:
