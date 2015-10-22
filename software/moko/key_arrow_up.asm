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
	cmp	dword [variable_cursor_position + 0x04],	VARIABLE_INTERFACE_HEADER_HEIGHT
	ja	.lines_available

	cmp qword [variable_document_line_start],	VARIABLE_EMPTY
	je	.end	; brak możliwości

	jmp	$

.lines_available:
	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	call	update_line_on_screen

	sub	dword [variable_cursor_position + 0x04],	VARIABLE_DECREMENT

	mov	rsi,	qword [variable_cursor_indicator]
	sub	rsi,	qword [variable_cursor_position_on_line]
	sub	rsi,	VARIABLE_DECREMENT
	call	count_chars_in_previous_line

	mov	qword [variable_cursor_indicator],	rsi
	mov	qword [variable_line_count_of_chars],	rcx

	mov	eax,	dword [variable_screen_size]
	sub	eax,	VARIABLE_DECREMENT

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY

.try_again:
	cmp	rcx,	rax
	jbe	.line_size_ok

	sub	rcx,	rax
	add	qword [variable_line_print_start],	rax
	add	qword [variable_cursor_indicator],	rax
	add	qword [variable_cursor_position_on_line],	rax
	jmp	.try_again

.line_size_ok:

	cmp	qword [variable_cursor_position_on_line],	rcx
	jb	.cursor_ok

	

.cursor_ok:
	mov	qword [variable_cursor_position_on_line],	rcx

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	call	update_line_on_screen

	jmp	$

.end:
	jmp	start.noKey
