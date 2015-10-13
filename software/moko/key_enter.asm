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

	inc	qword [variable_cursor_indicator]
	inc	qword [variable_document_chars_count]
	inc	qword [variable_line_count]
	inc	qword [variable_line_current]
	mov	qword [variable_line_show_from_char],	VARIABLE_EMPTY
	mov	qword [variable_cursor_in_line],	VARIABLE_EMPTY
	mov	qword [variable_cursor_in_line_was],	VARIABLE_EMPTY

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
	;mov	ax,	0x0104
	;int	0x40

	mov	ebx,	dword [variable_screen_size]
	sub	ebx,	ecx
	jz	.nothing_left

	mov	ax,	0x0102
	mov	rcx,	VARIABLE_COLOR_DEFAULT
	xchg	rbx,	rcx
	mov	r8,	" "
	int	0x40

.nothing_left:
	mov	eax,	dword [variable_screen_size + 0x04]
	sub	rax,	VARIABLE_INTERFACE_MENU_HEIGHT
	dec	rax
	mov	ebx,	dword [variable_cursor_position + 0x04]
	cmp	eax,	ebx
	je	.no_cursor_move_down

	inc	dword [variable_cursor_position + 0x04]

.no_cursor_move_down:
	mov	dword [variable_cursor_position],	VARIABLE_EMPTY

	cmp	eax,	ebx
	je	.screen_scroll_up

	; przewiń pozostałe linie dokumentu na ekranie o jedną w dół
	mov	ax,	0x0109
	xor	bl,	bl
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	ecx,	dword [variable_cursor_position + 0x04]
	sub	ecx,	VARIABLE_INTERFACE_MENU_HEIGHT
	mov	edx,	dword [variable_cursor_position + 0x04]
	int	0x40

.screen_scroll_done:
	mov 	rsi,	qword [variable_cursor_indicator]
	call	count_chars_in_line
	mov	qword [variable_line_chars_count],	rcx
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40

	mov	ebx,	dword [variable_screen_size]
	sub	ebx,	ecx
	jz	.nothing_left

	mov	ax,	0x0102
	mov	rcx,	VARIABLE_COLOR_DEFAULT
	xchg	rbx,	rcx
	mov	r8,	" "
	int	0x40

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	start.noKey

.screen_scroll_up:
	; przewiń pozostałe linie dokumentu na ekranie o jedną w dół
	mov	ax,	0x0109
	mov	bl,	1
	mov	edx,	VARIABLE_INTERFACE_HEADER_HEIGHT + 1
	mov	ecx,	dword [variable_screen_size + 0x04]
	sub	rcx,	VARIABLE_INTERFACE_HEIGHT
	int	0x40

	;dec	dword [variable_cursor_position + 0x04]

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	.screen_scroll_done
