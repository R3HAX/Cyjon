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

	; --- wyświetl menu na środku ekranu --- ;

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SIZE
	int	STATIC_KERNEL_SERVICE

	; ktoś zna lepszy sposob?
	mov	qword [variable_screen_cursor],	rbx
	shr	qword [variable_screen_cursor],	VARIABLE_DIVIDE_BY_2
	shr	qword [variable_screen_cursor + VARIABLE_QWORD_HIGH],	VARIABLE_DIVIDE_BY_2
	sub	qword [variable_screen_cursor], 4	; połowa szerokości menu (bez marginesów)
	sub	qword [variable_screen_cursor + VARIABLE_QWORD_HIGH],	1	; połowa ilości rekordow (bez marginesów)
	mov	rax,	qword [variable_screen_cursor]

	mov	qword [rdi + WINDOW_MENU.position],	rax
	mov	qword [rdi + WINDOW_MENU.entrys],	1
	mov	rax,	variable_menu
	mov	qword [rdi + WINDOW_MENU.data],	rax
	call	library_window_menu

	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

%include	'library/window_menu.asm'

variable_screen_cursor		dq	VARIABLE_EMPTY
variable_menu_specification:	times	WINDOW_MENU.structure_size	db	VARIABLE_EMPTY

variable_menu:
	dq	8
	db	VARIABLE_EMPTY	; flagi
	db	'hostname'
