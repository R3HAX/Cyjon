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
	mov	rsi,	qword [variable_cursor_indicator]
	mov	rcx,	qword [variable_cursor_in_line]
	sub	rsi,	rcx

	mov	qword [variable_cursor_indicator],	rsi

	cmp	qword [variable_line_show_from_char],	VARIABLE_EMPTY
	je	.line_ok

	mov	ax,	0x0105
	mov	ebx,	dword [variable_cursor_position + 0x04]
	shl	rbx,	32
	int	0x40

	cmp	ecx,	dword [variable_screen_size]
	jb	.size_ok

	mov	ecx,	dword [variable_screen_size]
	dec	rcx

.size_ok:
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40

	mov	ebx,	dword [variable_screen_size]
	sub	ebx,	ecx
	jz	.line_ok

	mov	ax,	0x0102
	mov	rcx,	VARIABLE_COLOR_DEFAULT
	xchg	rbx,	rcx
	mov	r8,	" "
	int	0x40

.line_ok:
	dec	rsi
	call	count_chars_in_previous_line

	mov	qword [variable_cursor_indicator],	rsi

	cmp	ecx,	dword [variable_screen_size]
	jb	.cursor_ok

	mov	ecx,	dword [variable_screen_size]

.cursor_ok:
	mov	dword [variable_cursor_position],	ecx
	mov	qword [variable_cursor_in_line],	rcx

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	$
