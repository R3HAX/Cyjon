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
	cmp	dword [variable_cursor_position],	VARIABLE_EMPTY
	ja	.position_ok

	cmp	qword [variable_line_print_start],	VARIABLE_EMPTY
	je	.change_line

	dec	qword [variable_line_print_start]
	dec	qword [variable_cursor_indicator]
	dec	qword [variable_cursor_position_on_line]
	call	update_line_on_screen

	jmp	start.noKey

.change_line:
	jmp	start.noKey

.position_ok:
	dec	qword [variable_cursor_indicator]
	dec	dword [variable_cursor_position]
	dec	qword [variable_cursor_position_on_line]

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

.end:
	jmp	start.noKey
