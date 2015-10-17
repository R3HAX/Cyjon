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

key_arrow_left:
	cmp	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY
	ja	.position_ok

	cmp	qword [variable_line_print_start],	VARIABLE_EMPTY
	je	.change_line

	dec	qword [variable_line_print_start]
	dec	qword [variable_cursor_indicator]
	dec	qword [variable_cursor_position_on_line]
	call	update_line_on_screen

	jmp	start.noKey

.change_line:
	cmp	dword [variable_cursor_position + 0x04], VARIABLE_INTERFACE_HEADER_HEIGHT
	je	.scroll_down

	; pomiń znak nowej linii
	sub	qword [variable_cursor_indicator],	0x01
	mov	rsi,	qword [variable_cursor_indicator]
	call	count_chars_in_previous_line

	sub	dword [variable_cursor_position + 0x04],	0x01
	mov	qword [variable_line_count_of_chars],	rcx
	mov	qword [variable_cursor_position_on_line],	rcx

	cmp	ecx,	dword [variable_screen_size]
	jb	.line_size_ok

	mov	eax,	dword [variable_screen_size]
	sub	eax,	0x01
	sub	rcx,	rax
	mov	qword [variable_line_print_start],	rcx
	mov	dword [variable_cursor_position],	eax
	call	update_line_on_screen

	jmp	start.noKey

.line_size_ok:
	mov	dword [variable_cursor_position],	ecx
	call	update_line_on_screen

	jmp	start.noKey

.scroll_down:
	cmp	qword [variable_document_line_start],	VARIABLE_EMPTY
	je	.end

	; cdn.

	jmp	start.noKey

.position_ok:
	cmp	dword [variable_cursor_position],	VARIABLE_EMPTY
	je	.no_cursor

	sub	dword [variable_cursor_position],	0x01
	jmp	.new_line_start

.no_cursor:
	sub	qword [variable_line_print_start],	0x01

.new_line_start:
	sub	qword [variable_cursor_indicator],	0x01
	sub	qword [variable_cursor_position_on_line],	0x01

	call	update_line_on_screen

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

.end:
	jmp	start.noKey
