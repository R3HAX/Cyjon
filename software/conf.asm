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
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SIZE
	int	STATIC_KERNEL_SERVICE

	mov	qword [variable_screen_size],	rbx

	shr	dword [variable_screen_size],	1
	shr	dword [variable_screen_size + VARIABLE_QWORD_HIGH],	1
	sub	dword [variable_screen_size + VARIABLE_QWORD_HIGH],	7

	mov	rcx,	qword [variable_window_width]
	shr	rcx,	1
	sub	dword [variable_screen_size],	ecx

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_screen_size]
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_WHITE
	mov	rcx,	qword [variable_window_width]
	mov	edx,	VARIABLE_COLOR_BACKGROUND_RED
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_screen_size]
	inc	rbx
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_WHITE
	mov	rcx,	qword [variable_window_header_width]
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_RED
	mov	rsi,	text_window_header
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_screen_size]
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [variable_window_width]
	mov	edx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_screen_size]
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [variable_window_width]
	mov	edx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_screen_size]
	inc	rbx
	int	STATIC_KERNEL_SERVICE

	; oblicz rozmiar linii mieszczący się w oknie
	mov	r8,	qword [variable_window_width]
	sub	r8,	2	; marginesy

	mov	rsi,	text_window_message

.find_another_line:
	cmp	byte [rsi],	VARIABLE_EMPTY
	je	.message_ready

	cmp	qword [variable_window_message_width],	VARIABLE_EMPTY
	je	.error	; brak wiadomości?

	; znajdz największą ilość słów mieszczących się w linii
	call	find_line
	jnc	.message_ready

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_BACKGROUND_BLACK
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_screen_size]
	int	STATIC_KERNEL_SERVICE

	push	rcx
	push	r8

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [variable_window_width]
	mov	edx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_screen_size]
	inc	rbx
	int	STATIC_KERNEL_SERVICE

	pop	r8
	pop	rcx

	add	rsi,	rcx

.char_space:
	cmp	byte [rsi],	VARIABLE_ASCII_CODE_SPACE
	jne	.no_space

	inc	rsi
	inc	rcx
	jmp	.char_space

.no_space:
	sub	qword [variable_window_message_width],	rcx
	jmp	.find_another_line

.message_ready:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_screen_size]
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [variable_window_width]
	mov	edx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_screen_size]
	add	rbx,	qword [variable_window_width]
	sub	rbx,	qword [variable_window_button_width]
	dec	rbx
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_WHITE
	mov	rcx,	qword [variable_window_button_width]
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_BLACK
	mov	rsi,	text_button_ok
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	inc	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_screen_size]
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [variable_window_width]
	mov	edx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	text_new_line
	int	STATIC_KERNEL_SERVICE

	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

.error:

find_line:
	push	rsi

	; przesuń wskaźnik na koniec teoretycznej linii
	add	rsi,	r8

	; łut szczęścia?
	cmp	byte [rsi],	VARIABLE_ASCII_CODE_SPACE
	je	.found

	cmp	qword [variable_window_message_width],	r8
	jbe	.found

.loop:
	dec	rsi

	cmp	rsi,	qword [rsp]
	je	.nothing	; słowo za duże by zmieścić w sugerowanym oknie

	; koniec tekstu?
	cmp	byte [rsi],	VARIABLE_ASCII_CODE_TERMINATOR
	je	.found

	cmp	byte [rsi],	VARIABLE_ASCII_CODE_SPACE
	jne	.loop

.found:
	mov	rcx,	rsi

	pop	rsi

	sub	rcx,	rsi
	stc

	ret

.nothing:
	pop	rsi

	clc

	ret

%include	"library/find_first_word.asm"

variable_screen_size	dq	VARIABLE_EMPTY

variable_window_width	dq	32

variable_window_header_width	dq	5
text_window_header		db	"About"
variable_window_message_width	dq	154
text_window_message		db	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer pharetra purus nec elit eleifend lobortis. Quisque vel egestas massa, non placerat lorem.", VARIABLE_ASCII_CODE_TERMINATOR
variable_window_button_width	dq	8
text_button_ok			db	"   Ok   ", VARIABLE_ASCII_CODE_TERMINATOR
text_new_line			db	VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_TERMINATOR
