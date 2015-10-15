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

key_arrow_right:
	mov	rsi,	qword [variable_cursor_indicator]
	cmp	byte [rsi],	VARIABLE_EMPTY
	je	start.noKey	; daleszej części dokumentu

	mov	rax,	qword [variable_cursor_position_on_line]
	cmp	rax,	qword [variable_line_count_of_chars]
	je	.change_line

	mov	eax,	dword [variable_screen_size]
	sub	eax,	1
	cmp	dword [variable_cursor_position],	eax
	jb	.cursor_ok

	inc	qword [variable_cursor_indicator]
	inc	qword [variable_cursor_position_on_line]
	inc	qword [variable_line_print_start]
	call	update_line_on_screen

	jmp	start.noKey

.cursor_ok:
	inc	qword [variable_cursor_indicator]
	inc	dword [variable_cursor_position]
	inc	qword [variable_cursor_position_on_line]

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	start.noKey

.change_line:

.end:
	jmp	start.noKey
