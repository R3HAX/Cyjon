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
	mov	rdi,	variable_menu_specification

	mov	rax,	0x0000000500000005
	mov	qword [rdi + WINDOW_MENU.position],	rax
	mov	qword [rdi + WINDOW_MENU.entrys],	1
	mov	qword [rdi + WINDOW_MENU.data],	variable_menu
	call	library_window_menu

	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

%include	'library/window_menu.asm'

variable_menu_specification:	times	WINDOW_MENU.structure_size	db	VARIABLE_EMPTY

variable_menu:
	dq	8
	db	VARIABLE_EMPTY	; flagi
	db	'hostname'
