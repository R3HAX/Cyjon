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


VARIABLE_WINDOW_MENU_SELECTED_TEXT_COLOR	equ	VARIABLE_COLOR_BLACK
VARIABLE_WINDOW_MENU_TEXT_COLOR			equ	VARIABLE_COLOR_WHITE
VARIABLE_WINDOW_MENU_COLOR			equ	VARIABLE_COLOR_BLACK
VARIABLE_WINDOW_MENU_BACKGROUND			equ	VARIABLE_COLOR_BACKGROUND_RED
VARIABLE_WINDOW_MENU_SELECTED_BACKGROUND	equ	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
VARIABLE_WINDOW_MENU_MARGIN			equ	2

variable_window_menu_info_position	dq	VARIABLE_EMPTY
variable_window_menu_width		dq	VARIABLE_EMPTY
variable_window_menu_selected		dd	VARIABLE_EMPTY
variable_window_menu_selected_last	dd	VARIABLE_EMPTY

; wejście:
;	rdi - wskaźnik do tablicy WINDOW_MENU
; wyjście:
;	rcx - numer rekordu wybranego
;
; pozostałe rejestry zachowane
library_window_menu:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	r8

	; wycieniuj ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SHADOW
	int	STATIC_KERNEL_SERVICE

	; --- oblicz szerokość menu --- ;
	xor	rcx,	rcx
	mov	rdx,	qword [rdi + WINDOW_MENU.entrys]
	mov	rsi,	qword [rdi + WINDOW_MENU.data]

.calculate:
	cmp	cl,	byte [rsi]
	ja	.calculate_continue

	; aktualizuj szerokość największego rekordu
	movzx	rcx,	byte [rsi]

.calculate_continue:
	movzx	rbx,	byte [rsi]
	add	rsi,	rbx
	add	rsi,	VARIABLE_BYTE_SIZE + VARIABLE_BYTE_SIZE

	dec	rdx
	jnz	.calculate

	mov	qword [variable_window_menu_width],	rcx

	call	library_window_menu_interface

	call	library_window_menu_show

	inc	dword [variable_window_menu_info_position + VARIABLE_QWORD_HIGH]
	inc	dword [variable_window_menu_info_position]

.mark_entry:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	push	qword [variable_window_menu_info_position]
	mov	ebx,	dword [variable_window_menu_selected]
	add	dword [rsp + VARIABLE_QWORD_HIGH],	ebx
	pop	rbx
	int	STATIC_KERNEL_SERVICE

	mov	eax,	dword [variable_window_menu_selected]
	call	library_window_menu_find_entry

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_WINDOW_MENU_SELECTED_TEXT_COLOR
	mov	edx,	VARIABLE_WINDOW_MENU_SELECTED_BACKGROUND
	int	STATIC_KERNEL_SERVICE

	call	library_window_menu_padding

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_HIDE
	int	STATIC_KERNEL_SERVICE

	call	library_window_menu_user

	cmp	rax,	VARIABLE_FULL
	je	.end

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	push	qword [variable_window_menu_info_position]
	mov	ebx,	dword [variable_window_menu_selected_last]
	add	dword [rsp + VARIABLE_QWORD_HIGH],	ebx
	pop	rbx
	int	STATIC_KERNEL_SERVICE

	mov	eax,	dword [variable_window_menu_selected_last]
	call	library_window_menu_find_entry

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_WINDOW_MENU_TEXT_COLOR
	mov	edx,	VARIABLE_WINDOW_MENU_BACKGROUND
	int	STATIC_KERNEL_SERVICE

	call	library_window_menu_padding

	jmp	.mark_entry

.end:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

; wejście:
;	rdi - wskaźnik do tablicy WINDOW_MENU
; wyjście:
;	brak
;
; wszystkie rejestry zachowane
library_window_menu_user:
.noKey:
	; pobierz znak z bufora klawiatury
	mov	ax,	VARIABLE_KERNEL_SERVICE_KEYBOARD_GET_KEY
	int	STATIC_KERNEL_SERVICE

	cmp	ax,	VARIABLE_EMPTY	
	je	.noKey

	cmp	ax,	VARIABLE_ASCII_CODE_ENTER
	je	.key_enter

	cmp	ax,	VARIABLE_ASCII_CODE_ESCAPE
	je	.key_escape

	cmp	ax,	0x8004
	je	.key_arrow_up

	cmp	ax,	0x8005
	jne	.noKey

	; key_arrow_down

	mov	rax,	qword [rdi + WINDOW_MENU.entrys]
	dec	rax

	; koniec listy?
	cmp	dword [variable_window_menu_selected],	eax
	je	.noKey	; zignoruj klawisz

	mov	eax,	dword [variable_window_menu_selected]
	inc	dword [variable_window_menu_selected]
	mov	dword [variable_window_menu_selected_last],	eax

	ret

.key_arrow_up:
	; początek listy?
	cmp	dword [variable_window_menu_selected],	VARIABLE_EMPTY
	je	.noKey	; zignoruj klawisz

	mov	eax,	dword [variable_window_menu_selected]
	dec	dword [variable_window_menu_selected]
	mov	dword [variable_window_menu_selected_last],	eax

	ret

.key_escape:
	mov	rax,	VARIABLE_FULL
	mov	rcx,	VARIABLE_FULL

	ret

.key_enter:
	mov	rax,	VARIABLE_FULL
	mov	ecx,	dword [variable_window_menu_selected]

	ret

; wejście:
;	rcx - rozmiar wypisanego tekstu
; wyjście:
;	brak
;
; wszystkie rejestry zachowane
library_window_menu_padding:
	; zachowaj oryginelne rejestry
	push	rax
	push	rcx
	push	r8

	cmp	rcx,	qword [variable_window_menu_width]
	je	.empty_padding

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	r8,	qword [variable_window_menu_width]
	sub	r8,	rcx
	mov	rcx,	r8
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

.empty_padding:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

; wejście:
;	rax - numer rekordu do odnalezienia
;	rdi - wskaźnik do tablicy WINDOW_MENU
; wyjście:
;	rcx - rozmiar wskaźnika w Bajtach
;	rsi - wskaźnik do rekordu
;
; pozostałe rejestry zachowane
library_window_menu_find_entry:
	; zachowaj oryginalne rejestry
	push	rax

	; tablica z rekordami
	mov	rsi,	qword [rdi + WINDOW_MENU.data]

.search:
	; właściwości pierwszego rekordu
	movzx	rcx,	byte [rsi]
	add	rsi,	VARIABLE_BYTE_SIZE + VARIABLE_BYTE_SIZE

	; szukać dalej?
	cmp	rax,	VARIABLE_EMPTY
	je	.found

	; następny rekord
	dec	rax
	add	rsi,	rcx

	jmp	.search

.found:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

; wejście:
;	rdi - wskaźnik do tablicy WINDOW_MENU
; wyjście:
;	brak
;
; wszystkie rejestry zachowane
library_window_menu_show:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	push	qword [variable_window_menu_info_position]
	inc	dword [rsp + VARIABLE_QWORD_HIGH]
	inc	dword [rsp]
	mov	rbx,	qword [rsp]
	int	STATIC_KERNEL_SERVICE

	mov	rsi,	qword [rdi + WINDOW_MENU.data]

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_WINDOW_MENU_TEXT_COLOR
	mov	edx,	VARIABLE_WINDOW_MENU_BACKGROUND

	mov	r8,	qword [rdi + WINDOW_MENU.entrys]

.next_line:
	movzx	rcx,	byte [rsi]	; name length
	add	rsi,	VARIABLE_BYTE_SIZE + VARIABLE_BYTE_SIZE	; name length + flags

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_WINDOW_MENU_TEXT_COLOR
	int	STATIC_KERNEL_SERVICE

	dec	r8
	jz	.no_more_lines

	add	rsi,	rcx

	; przesuń kursor do następnej linii
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [rsp + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [rsp]
	int	STATIC_KERNEL_SERVICE

	jmp	.next_line

.no_more_lines:
	add	rsp,	VARIABLE_QWORD_SIZE

	; przywróć oryginalne rejestry
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
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

	add	rcx,	VARIABLE_WINDOW_MENU_MARGIN

	; margines górny
	mov	ebx,	VARIABLE_WINDOW_MENU_COLOR
	mov	edx,	VARIABLE_WINDOW_MENU_BACKGROUND
	mov	r8,	VARIABLE_ASCII_CODE_DASH_DOUBLE_HORIZONTAL
	call	library_window_menu_background

	mov	rax,	qword [rdi + WINDOW_MENU.entrys]

	; tło okna komunikatu
	xor	r8,	r8

.background:
	call	library_window_menu_background

	dec	rax
	jnz	.background

	; margines dolny
	mov	r8,	VARIABLE_ASCII_CODE_DASH_DOUBLE_HORIZONTAL
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
