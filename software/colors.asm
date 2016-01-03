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
	xor	bl,	bl
	xor	dl,	dl

.loop:
	push	rcx

	push	rbx
	push	rdx
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	xor	bl,	bl
	mov	rcx,	1
	xor	dl,	dl
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE
	pop	rdx
	pop	rbx

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rcx,	0x0210	; system dziesiętny, uzupełnij do 2
	mov	r8,	rbx
	add	r8,	rdx
	int	STATIC_KERNEL_SERVICE

	pop	rcx

	inc	bl

	cmp	bl,	0x10
	jb	.loop

	xor	bl,	bl
	add	dl,	0x10

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rcx,	2
	mov	rsi,	text_new_line
	int	STATIC_KERNEL_SERVICE

	cmp	dl,	VARIABLE_EMPTY	
	ja	.loop

.end:
	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

text_new_line	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
