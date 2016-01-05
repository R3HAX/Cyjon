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

VARIABLE_CONF_WINDOW_MESSAGE_INFO_WIDTH_DEFAULT	equ	18

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]	

start:
	; wyczyść ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN
	int	STATIC_KERNEL_SERVICE

	; --- ustaw kursor na ostatniej linii ---

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SIZE
	int	STATIC_KERNEL_SERVICE

	push	rbx

	shr	rbx,	32
	dec	rbx
	shl	rbx,	32

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	int	STATIC_KERNEL_SERVICE

	; wyświetl komunikat na środku ekranu
	shr	dword [rsp],	1
	sub	dword [rsp],	VARIABLE_CONF_WINDOW_MESSAGE_INFO_WIDTH_DEFAULT / 2
	shr	dword [rsp + VARIABLE_QWORD_HIGH],	1
	; podnieś wyświetlane okno o rozmiar obydwu marginesów
	sub	dword [rsp + VARIABLE_QWORD_HIGH],	VARIABLE_WINDOW_MESSAGE_INFO_MARGIN

	pop	rax

	mov	rdi,	variable_table
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	VARIABLE_CONF_WINDOW_MESSAGE_INFO_WIDTH_DEFAULT
	mov	rax,	qword [text_window_message_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

.error:

variable_table	times	8	dq	VARIABLE_EMPTY
text_window_message_size	dq	31
text_window_message		db	"This is a simple message box.", VARIABLE_ASCII_CODE_TERMINATOR

%include	"library/window_message_info.asm"
