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

debug:
	mov	ax,	0x0105
	mov	ebx,	dword [variable_screen_size + 0x04]
	sub	rbx,	2
	shl	rbx,	32
	int	0x40

	push	rbx

	mov	rax,	0x0103
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	10
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	movzx	r8,	word [variable_cursor_position]
	int	0x40

	pop	rbx
	add	rbx,	4
	push	rbx

	mov	ax,	0x0105
	int	0x40

	mov	rax,	0x0103
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	10
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	movzx	r8,	word [variable_cursor_position + 0x04]
	int	0x40

	pop	rbx
	add	rbx,	4
	push	rbx

	mov	ax,	0x0105
	int	0x40

	mov	rax,	0x0103
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	10
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	r8,	qword [variable_line_show_from_char]
	int	0x40

	pop	rbx

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	ret
