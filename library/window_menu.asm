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

; 64 Bitowy kod programu
[BITS 64]

struc	WINDOW_MENU
	.position	resq	1
	.entrys		resq	1
	.data		resq	1
	.structure_size	resb	1	; ignorowany/znacznik rozmiaru tablicy
endstruc

VARIABLE_WINDOW_MENU_COLOR		equ	VARIABLE_COLOR_WHITE
VARIABLE_WINDOW_MENU_BACKGROUND		equ	VARIABLE_COLOR_BACKGROUND_LIGHT_RED

variable_window_menu_info_position	dq	VARIABLE_EMPTY

library_window_menu:
	; wycieniuj ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SHADOW
	int	STATIC_KERNEL_SERVICE

	; --- oblicz szerokość menu ---

	call	library_window_menu_interface

	ret

; wejście:
;	rdi - wskaźnik do tablicy WINDOW_MENU
;	rcx - szerokość menu
; wyjście:
;	brak
;
; wszystkie rejestry zachowane
library_window_menu_interface:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rbp
	push	r8

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [rdi + WINDOW_MENU.position]
	; zapamiętaj oryginalną pozycję
	mov	qword [variable_window_menu_info_position],	rbx
	int	STATIC_KERNEL_SERVICE

	; margines górny
	mov	ebx,	VARIABLE_WINDOW_MENU_COLOR
	mov	edx,	VARIABLE_WINDOW_MENU_BACKGROUND
	mov	r8,	VARIABLE_ASCII_CODE_DASH_HORIZONTAL_BOLD
	call	library_window_menu_background

.background:
	; tło okna komunikatu
	xor	r8,	r8
	call	library_window_menu_background

	dec	rbp
	jnz	.background

	; margines dolny
	mov	r8,	VARIABLE_ASCII_CODE_DASH_HORIZONTAL_BOLD
	call	library_window_menu_background

	; przywróć oryginalne rejestry
	pop	r8
	pop	rbp
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

; wejście:
;	r8 - typ tła, jeśli ZERO > domyslny (SPACJA)s
; wyjście:
;	brak
;
; wszystkie rejestry zachowane
library_window_menu_background:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	r8

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR

	; specjalny typ tła?
	cmp	r8,	VARIABLE_EMPTY
	jne	.yes

	; domyślny
	mov	r8,	VARIABLE_ASCII_CODE_SPACE

.yes:
	int	STATIC_KERNEL_SERVICE

	; ustaw kursor na domyślnej pozycji w tle
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [rdi + WINDOW_MENU.position + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [rdi + WINDOW_MENU.position]
	int	STATIC_KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	r8
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
