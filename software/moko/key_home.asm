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

key_home:
	; pobierz pozycje kursora - kolumna
	mov	rcx,	qword [variable_cursor_position_on_line]
	sub	qword [variable_cursor_indicator],	rcx

	mov	dword [variable_cursor_position],	VARIABLE_EMPTY
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY

	cmp	qword [variable_line_print_start],	VARIABLE_EMPTY
	je	.ok

	mov	qword [variable_line_print_start],	VARIABLE_EMPTY
	call	update_line_on_screen

.ok:
	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	start.noKey
