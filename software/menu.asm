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

	push	rbx

	; ktoś zna lepszy sposób?
	mov	qword [variable_screen_cursor],	rbx
	shr	dword [variable_screen_cursor],	VARIABLE_DIVIDE_BY_2
	shr	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH],	VARIABLE_DIVIDE_BY_2
	sub	qword [variable_screen_cursor], 4	; połowa szerokości menu (bez marginesów)
	sub	qword [variable_screen_cursor + VARIABLE_QWORD_HIGH],	1	; połowa ilości rekordow (bez marginesów)
	mov	rax,	qword [variable_screen_cursor]

	mov	qword [rdi + WINDOW_MENU.position],	rax
	mov	qword [rdi + WINDOW_MENU.entrys],	3
	mov	rax,	variable_menu
	mov	qword [rdi + WINDOW_MENU.data],	rax
	call	library_window_menu

	; ustaw kursor na początku ostatniej linii
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	dword [rsp],	VARIABLE_EMPTY
	dec	dword [rsp + VARIABLE_QWORD_HIGH]
	pop	rbx
	int	STATIC_KERNEL_SERVICE

	; program kończy działanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

%include	'library/window_menu.asm'

variable_screen_cursor		dq	VARIABLE_EMPTY
variable_menu_specification:	times	WINDOW_MENU.structure_size	db	VARIABLE_EMPTY

variable_menu:
	db	5
	db	VARIABLE_EMPTY
	db	'first'
	db	6
	db	VARIABLE_EMPTY	; flagi
	db	'second'
	db	5
	db	VARIABLE_EMPTY
	db	'third'
