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

key_enter:
	; załaduj znak nowej linii
	mov	ax,	VARIABLE_ASCII_CODE_NEWLINE
	call	save_into_document

	;inc	qword [variable_line_chars_count]
	inc	qword [variable_cursor_indicator]
	;inc	qword [variable_cursor_in_line]
	inc	qword [variable_document_chars_count]

	mov	ax,	0x0105
	mov	ebx,	dword [variable_cursor_position + 0x04]
	shl	rbx,	32
	int	0x40

	mov 	rsi,	qword [variable_cursor_indicator]
	dec	rsi

	call	count_chars_in_previous_line

	cmp	ecx,	dword [variable_screen_size]
	jb	.size_ok

	mov	ecx,	dword [variable_screen_size]
	dec	rcx

.size_ok:
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40

	; wyczyść pozostałą część linii, jeśli jest
	mov	ax,	0x0104
	int	0x40

	mov	ecx,	dword [variable_screen_size]
	dec	rcx
	sub	ecx,	ebx
	jz	.nothing_left

	mov	ax,	0x0102
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	r8,	" "
	int	0x40

.nothing_left:
	inc	dword [variable_cursor_position + 0x04]
	mov	dword [variable_cursor_position],	VARIABLE_EMPTY

	; przewiń pozostałe linie dokumentu na ekranie o jedną w dół
	mov	ax,	0x0109
	xor	bl,	bl
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	dword [variable_cursor_position + 0x04]
	sub	ecx,	VARIABLE_INTERFACE_MENU_HEIGHT
	mov	edx,	dword [variable_cursor_position + 0x04]
	;inc	edx

	int	0x40

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	$
