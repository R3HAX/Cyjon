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

key_backspace:
	mov	rsi,	qword [variable_cursor_indicator]
	cmp	rsi,	qword [variable_document_address_start]
	je	start.noKey

	call	save_into_document

	sub	qword [variable_cursor_indicator],	VARIABLE_DECREMENT
	sub	qword [variable_document_count_of_chars],	VARIABLE_DECREMENT

	cmp	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	je	.change_line

	sub	qword [variable_cursor_position_on_line],	VARIABLE_DECREMENT
	sub	qword [variable_line_count_of_chars],	VARIABLE_DECREMENT

	cmp	dword [variable_cursor_position],	VARIABLE_EMPTY
	je	.change_line_start

	sub	dword [variable_cursor_position],	VARIABLE_DECREMENT
	jmp	.cursor_moved

.change_line_start:
	sub	qword [variable_line_print_start],	VARIABLE_DECREMENT

.cursor_moved:
	call	update_line_on_screen

	jmp	start.noKey

.change_line:
	mov	rsi,	qword [variable_cursor_indicator]
	call	count_chars_in_previous_line

	sub	dword [variable_cursor_position + 0x04],	VARIABLE_DECREMENT
	sub	qword [variable_document_count_of_lines],		VARIABLE_DECREMENT

	add	qword [variable_line_count_of_chars],	rcx
	mov	qword [variable_cursor_position_on_line],	rcx

	mov	eax,	dword [variable_screen_size]
	sub	eax,	VARIABLE_DECREMENT

.cursor_fix:
	cmp	rcx,	rax
	jbe	.cursor_fixed

	sub	rcx,	rax
	add	qword [variable_line_print_start],	rax
	jmp	.cursor_fix

.cursor_fixed:
	mov	dword [variable_cursor_position],	ecx
	call	update_line_on_screen

	; przesuń dolną część ekranu do góry
	

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

.end:
	jmp	start.noKey
