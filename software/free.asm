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
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_header
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SYSTEM_MEMORY
	int	STATIC_KERNEL_SERVICE

	push	rbx
	push	rcx
	push	rdx

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rcx,	10	; system dziesiętny
	mov	r8,	rbx
	shl	r8,	2	; *4 KiB
	mov	ebx,	VARIABLE_COLOR_WHITE
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_kib
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_GET
	int	STATIC_KERNEL_SERVICE

	push	rbx

	mov	dword [rsp],	23	; used column
	mov	rbx,	qword [rsp]

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	r8,	qword [rsp + 0x18]
	sub	r8,	qword [rsp + 0x10]
	shl	r8,	2	; *4 KiB
	mov	ebx,	VARIABLE_COLOR_WHITE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_kib
	int	STATIC_KERNEL_SERVICE

	mov	dword [rsp],	38	; free column
	mov	rbx,	qword [rsp]

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	r8,	qword [rsp + 0x10]
	shl	r8,	2	; *4 KiB
	mov	ebx,	VARIABLE_COLOR_WHITE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_kib
	int	STATIC_KERNEL_SERVICE

	mov	dword [rsp],	53	; shared column
	mov	rbx,	qword [rsp]

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	r8,	qword [rsp + 0x08]
	shl	r8,	2	; *4 KiB
	mov	ebx,	VARIABLE_COLOR_WHITE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_kib
	int	STATIC_KERNEL_SERVICE

	mov	rsi,	text_paragraph
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

text_header	db	"        total          used           free           shared", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
text_mem	db	"Memory: ", VARIABLE_ASCII_CODE_TERMINATOR
text_kib	db	" KiB", VARIABLE_ASCII_CODE_TERMINATOR
text_paragraph	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
