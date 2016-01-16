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
	; wyświetl nagłówek tablicy
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	cl,	VARIABLE_FULL
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_row
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	cx,	0x0210	; uzupełnienie do 2, podstawa 16
	mov	r8,	0
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	cx,	1
	mov	r8,	0xB3	; |
	int	STATIC_KERNEL_SERVICE

	mov	si,	256	; ilość znaków w tablicy ASCII
	mov	di,	16	; ilość kolumn do wyświetlenia

	; numer następnego wiersza
	mov	r9,	0x10

	; początek tablicy ASCII
	xor	r8,	r8

.loop:
	; wyświetl znak
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	cl,	1
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	cmp	r8,	VARIABLE_ASCII_CODE_NEWLINE
	je	.special

	cmp	r8,	VARIABLE_ASCII_CODE_ENTER
	je	.special

	cmp	r8,	VARIABLE_ASCII_CODE_BACKSPACE
	je	.special

	int	STATIC_KERNEL_SERVICE

.continue:
	inc	r8

	; przesuń kursor na następną kolumnę
	push	r8
	mov	r8,	' '
	int	STATIC_KERNEL_SERVICE
	pop	r8

	; sprawdź czy koniec wiersza
	dec	di
	jnz	.in_row

	; przesuń kursor na nastepny wiersz
	push	rax
	push	rcx
	push	r8
	push	rsi

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	cl,	2
	mov	rsi,	text_newline
	int	STATIC_KERNEL_SERVICE

	cmp	word [rsp],	0x01
	je	.end

	mov	rsi,	text_hex
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	cx,	0x0210
	mov	r8,	r9
	int	STATIC_KERNEL_SERVICE

	add	r9,	0x10

	pop	rsi
	pop	r8
	pop	rcx
	pop	rax

	; przesuń kursor na pierwszą kolumnę
	push	r8
	mov	r8,	0xB3	; |
	int	STATIC_KERNEL_SERVICE
	pop	r8

	mov	di,	16

.in_row:
	; sprawdź czy koniec znaków ASCII
	dec	si
	jnz	.loop

.end:
	; koniec procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

.special:
	push	r8
	mov	r8,	' '
	int	STATIC_KERNEL_SERVICE
	pop	r8

	jmp	.continue

text_row		db	'    ', 0xB3, '0 1 2 3 4 5 6 7 8 9 A B C D E F', VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
	times 4		db	0xC4
			db	0xC5
	times 31	db	0xC4
			db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
text_hex		db	'0x', VARIABLE_ASCII_CODE_TERMINATOR
text_newline		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
