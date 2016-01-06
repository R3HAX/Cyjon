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

struc	WINDOW_MESSAGE_INFO
	.position	resq	1
	.width		resq	1
	.text_width	resq	1
	.text_pointer	resq	1
	.size		resb	1	; ignorowany/znacznik rozmiaru tablicy
endstruc	

VARIABLE_WINDOW_MESSAGE_INFO_TEXT_COLOR		equ	VARIABLE_COLOR_WHITE
VARIABLE_WINDOW_MESSAGE_INFO_COLOR		equ	VARIABLE_COLOR_BLACK
VARIABLE_WINDOW_MESSAGE_INFO_BACKGROUND		equ	VARIABLE_COLOR_BACKGROUND_RED
VARIABLE_WINDOW_MESSAGE_INFO_MARGIN		equ	2	; marginesy - dwa o grubości 1, z każdej strony

variable_window_message_info_cursor		dq	VARIABLE_EMPTY
variable_window_message_info_position		dq	VARIABLE_EMPTY
variable_window_message_info_button_width	dq	4
variable_window_message_info_button_pointer	db	" OK ", VARIABLE_ASCII_CODE_TERMINATOR

; wejście:
;	rdi - wskaźnik do tablicy WINDOW_MESSAGE_INFO
; wyjście:
;	rax - kod błędu
;		0 - ok
;		1 - słowo nie mieści się w oknie
;
; pozostałe rejestry zachowane
library_window_message_info:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rbp
	push	r8
	push	r9
	push	qword [rdi + WINDOW_MESSAGE_INFO.position]

	; wycieniuj ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SHADOW
	int	STATIC_KERNEL_SERVICE

	; zapamiętaj aktualną pozycję kursora
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_GET
	int	STATIC_KERNEL_SERVICE

	mov	qword [variable_window_message_info_cursor],	rbx

	; --- oblicz wysokość okna ---

	mov	rbp,	rsp	; licznik "złamań"
	mov	rsi,	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer]

	mov	r8,	qword [rdi + WINDOW_MESSAGE_INFO.width]
	sub	r8,	VARIABLE_WINDOW_MESSAGE_INFO_MARGIN
	mov	r9,	rsi
	add	r9,	qword [rdi + WINDOW_MESSAGE_INFO.text_width]

.calculate:
	call	library_window_message_info_find_line
	jnc	.error

	; zachowaj rozmiar linii
	push	rcx

	; przesuń wskaźnik na koniec linii
	add	rsi,	rcx

.white_char:
	; usuń białe znaki
	inc	rsi

	cmp	byte [rsi],	VARIABLE_ASCII_CODE_SPACE
	je	.white_char

	; jeśli ciąg zawiera znaki, przeliczaj dalej
	cmp	rsi,	r9
	jb	.calculate

	mov	r8,	rbp

	; zwróć ilość linii
	sub	rbp,	rsp
	shr	rbp,	3

	; --- wyświetl okno ---

	call	library_window_message_info_interface

	; --- wyświetl treść w oknie ---

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [variable_window_message_info_position]
	inc	dword [variable_window_message_info_position + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_window_message_info_position]
	int	STATIC_KERNEL_SERVICE

	mov	rsi,	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer]

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_WINDOW_MESSAGE_INFO_TEXT_COLOR
	mov	edx,	VARIABLE_WINDOW_MESSAGE_INFO_BACKGROUND

	sub	r8,	VARIABLE_QWORD_SIZE

.next_line:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_WINDOW_MESSAGE_INFO_TEXT_COLOR
	mov	rcx,	qword [r8]
	int	STATIC_KERNEL_SERVICE

	cmp	rbp,	VARIABLE_LAST_ITEM
	jz	.no_more_lines

	add	rsi,	rcx

.leave_white_char:
	; usuń białe znaki
	inc	rsi

	cmp	byte [rsi],	VARIABLE_ASCII_CODE_SPACE
	je	.leave_white_char

.no_more_lines:
	sub	r8,	VARIABLE_QWORD_SIZE
	add	rsp,	VARIABLE_QWORD_SIZE

	; przesuń kursor do następnej linii
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [variable_window_message_info_position + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_window_message_info_position]
	int	STATIC_KERNEL_SERVICE

	; sprawdź, czy pozostały linie do wyświetlenia
	dec	rbp
	jnz	.next_line

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_HIDE
	int	STATIC_KERNEL_SERVICE

.getKey:
	mov	ax,	VARIABLE_KERNEL_SERVICE_KEYBOARD_GET_KEY
	int	STATIC_KERNEL_SERVICE

	cmp	ax,	VARIABLE_ASCII_CODE_ENTER
	je	.end

	cmp	ax,	VARIABLE_ASCII_CODE_SPACE
	jne	.getKey

.end:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SHOW
	int	STATIC_KERNEL_SERVICE

	; przywróć oryginalną pozycję kursora
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_window_message_info_cursor]
	int	STATIC_KERNEL_SERVICE

	; brak błędów
	xor	rax,	rax
	
.error:
	; przywróć oryginalne rejestry
	pop	qword [rdi + WINDOW_MESSAGE_INFO.position]
	pop	r9
	pop	r8
	pop	rbp
	pop	rcx
	pop	rbx

	; powrót z biblioteki
	ret

; wejście:
;	rsi - wskaźnik do ciągu znaków, z którego wyciągnąć rozmiar linii
;	r8 - maksymalna ilość znaków na linię
;	r9 - wskaźnik końca ciągu znaków
; wyjście:
;	rcx - rozmiar linii mieszczącej się w limicie
;	rax - kod błędu operacji
;		0 - ok
;		1 - słowo nie mieści się w limicie
;
; pozostałe rejestry zachowane
library_window_message_info_find_line:
	push	rsi

	; przesuń wskaźnik na koniec teoretycznej linii
	add	rsi,	r8

	; sprawdź czy koniec ciągu tekstu
	cmp	rsi,	r9
	jb	.search	; nie, szukaj gdzie złamać linię

	; tak, wyświetl pozostałą część
	mov	rsi,	r9
	jmp	.found

.search:
	; sprawdź czy słowo nie mieści się w oknie
	cmp	rsp,	qword [rsp]
	je	.error

	; trafiliśmy na spacje? można złamać linię
	cmp	byte [rsi],	VARIABLE_ASCII_CODE_SPACE
	je	.found

	; przejdź do poprzedniego znaku
	dec	rsi

	jmp	.search

.found:
	; zwróć rozmiar złamanej linii
	mov	rcx,	rsi
	sub	rcx,	qword [rsp]

	; przywróć oryginalne rejestry
	pop	rsi

	; wynik pomyślny
	stc

	; powrót z procedury
	ret

.error:
	; zwróć kod błędu, "słowo nie mieści się w oknie"
	mov	rax,	1

	; przywróc oryginalne rejestry
	pop	rsi

	; brak wyniku
	clc

	; powrót z procedury
	ret

; wejście:
;	rdi - wskaźnik do tablicy WINDOW_MESSAGE_INFO
;	rbp - wysokość interfejsu w liniach
; wyjście:
;	brak
;
; wszystkie rejestry zachowane
library_window_message_info_interface:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rbp
	push	r8

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [rdi + WINDOW_MESSAGE_INFO.position]
	; zapamiętaj oryginalną pozycję
	mov	qword [variable_window_message_info_position],	rbx
	int	STATIC_KERNEL_SERVICE

	; margines górny
	mov	ebx,	VARIABLE_WINDOW_MESSAGE_INFO_COLOR
	mov	edx,	VARIABLE_WINDOW_MESSAGE_INFO_BACKGROUND
	mov	r8,	VARIABLE_ASCII_CODE_DASH_HORIZONTAL_BOLD
	call	library_window_message_info_background

.background:
	; tło okna komunikatu
	xor	r8,	r8
	call	library_window_message_info_background

	dec	rbp
	jnz	.background

	; margines dolny
	mov	r8,	VARIABLE_ASCII_CODE_DASH_HORIZONTAL_BOLD
	call	library_window_message_info_background

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
library_window_message_info_background:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	r8

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	rcx,	qword [rdi + WINDOW_MESSAGE_INFO.width]

	; specjalny typ tła?
	cmp	r8,	VARIABLE_EMPTY
	jne	.yes

	; domyślny
	mov	r8,	VARIABLE_ASCII_CODE_SPACE

.yes:
	int	STATIC_KERNEL_SERVICE

	; ustaw kursor na domyślnej pozycji w tle
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [rdi + WINDOW_MESSAGE_INFO.position + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [rdi + WINDOW_MESSAGE_INFO.position]
	int	STATIC_KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	r8
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
