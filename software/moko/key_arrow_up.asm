; Copyright (C) 2013-2015 Wataha.net
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

key_arrow_up:
	; sprawdź czy można przesunąć kursor wyżej
	mov	eax,	dword [variable_cursor_position + 0x04]
	cmp	eax,	VARIABLE_INTERFACE_HEADER_HEIGHT
	je	.cursor_can_not_be_moved_up

	sub	dword [variable_cursor_position + 0x04],	1
	jmp	.cursor_moved

.cursor_can_not_be_moved_up:
	; sprawdź czy istnieje część dokumentu poza ekranem
	cmp	qword [variable_document_show_from_line],	VARIABLE_EMPTY
	je	.end	; nie, brak możliwości przesunięcia kursora do porzedniej linii

	; przewiń zawartość dokumentu na ekranie w dół
	mov	ax,	0x0109
	mov	bl,	0
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	rcx,	VARIABLE_INTERFACE_HEIGHT
	mov	rdx,	VARIABLE_INTERFACE_HEADER_HEIGHT	; pierwszą linię na ekranie dokumentu ostaw pustą
	int	0x40

	sub	qword [variable_document_show_from_line],	0x01

.cursor_moved:
	; ustaw kursor na początek linii ekranu
	mov	ax,	0x0105
	mov	ebx,	dword [variable_cursor_position + 0x04]
	shl	rbx,	32
	int	0x40

	; znajdź wskaźnik i oblicz rozmiar poprzedniej linii w dokumencie
	mov	rsi,	qword [variable_cursor_indicator]
	sub	rsi,	qword [variable_cursor_in_line]
	sub	rsi,	0x01	; pomiń znak nowej linii
	call	count_chars_in_previous_line

	; zapamiętaj
	push	rsi
	push	rcx

	; wyświetl "poprzednią" linię
	cmp	ecx,	dword [variable_screen_size]
	jb	.size_of_previous_line_ok

	mov	ecx,	dword [variable_screen_size]
	sub	rcx,	0x01

.size_of_previous_line_ok:
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40

	mov	eax,	dword [variable_screen_size]
	sub	rcx,	rax
	neg	rcx

	mov	ax,	0x0102
	mov	r8,	" "
	int	0x40

	; wyświetl "aktualną" linię
	mov	rcx,	qword [variable_line_chars_count]
	cmp	ecx,	dword [variable_screen_size]
	jb	.size_of_actual_line_ok

	mov	ecx,	dword [variable_screen_size]
	sub	rcx,	0x01

.size_of_actual_line_ok:
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	qword [variable_cursor_indicator]
	sub	rsi,	qword [variable_cursor_in_line]
	int	0x40

	mov	eax,	dword [variable_screen_size]
	sub	rcx,	rax
	neg	rcx

	mov	ax,	0x0102
	mov	r8,	" "
	int	0x40

	; sprawdź czy można ustawić kursor w linii wyżej na tym samym miejscu
	mov	ecx,	dword [variable_cursor_position]
	cmp	rcx,	qword [rsp]
	jbe	.size_of_line_ok

	mov	rcx,	qword [rsp]
	mov	dword [variable_cursor_position],	ecx

.size_of_line_ok:
	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	mov	dword [variable_cursor_in_line],	ecx

	; przywróc adresy i wartości lini "poprzedniej"
	pop	qword [variable_line_chars_count]
	pop	qword [variable_cursor_indicator]
	add	dword [variable_cursor_indicator],	ecx

.end:
	jmp	start.noKey
