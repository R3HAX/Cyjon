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

save_into_document:
	; sprawdź dostępność miejsca w dokumencie
	mov	rdi,	qword [variable_document_address_start]
	add	rdi,	qword [variable_document_chars_count]

	cmp	rdi,	qword [variable_document_address_end]
	jb	.space_available

	push	rax

	; poproś o dodatkową przestrzeń pod dokument
	mov	ax,	0x0003
	mov	rcx,	1
	int	0x40

	add	qword [variable_document_address_end],	VARIABLE_MEMORY_PAGE_SIZE

	pop	rax

.space_available:
	; wstaw znak na koniec dokumentu?
	mov	rdi,	qword [variable_document_address_start]
	add	rdi,	qword [variable_document_chars_count]
	cmp	rdi,	qword [variable_cursor_indicator]
	je	.at_end_of_document

	; wstaw znak gdzieś w dokumencie

	; utwórz miejsce dla znaku w dokumencie
	mov	rcx,	rdi
	mov	rsi,	rdi
	dec	rsi
	sub	rcx,	qword [variable_cursor_indicator]

	push	rax

.looper:
	mov	al,	byte [rsi]
	mov	byte [rdi],	al
	sub	rdi,	1
	sub	rsi,	1
	sub	rcx,	1
	jnz	.looper

	pop	rax

	jmp	.save_char

.at_end_of_document:
	; zapisz znak do dokumentu
	mov	rdi,	qword [variable_cursor_indicator]
.save_char:
	stosb

	ret

screen_update:
	inc	qword [variable_line_chars_count]
	inc	qword [variable_cursor_indicator]

	cmp	ax,	VARIABLE_ASCII_CODE_NEWLINE
	je	.enter

	inc	qword [variable_cursor_in_line]
	jmp	.char

.enter:
	mov	qword [variable_cursor_in_line],	VARIABLE_EMPTY

.char:
	inc	qword [variable_document_chars_count]

	; sprawdź pozycje kursora
	mov	ebx,	dword [variable_screen_size]
	dec	ebx

	cmp	ebx,	dword [variable_cursor_position]
	je	.cursor_at_end_of_screen

	inc	qword [variable_cursor_position]

	jmp	.cursor_ok

.cursor_at_end_of_screen:
	inc	qword [variable_line_show_from_char]

.cursor_ok:
	mov	ax,	0x0105
	mov	ebx,	dword [variable_cursor_position + 0x04]
	shl	rbx,	32
	int	0x40

	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	qword [variable_cursor_in_line]
	sub	rcx,	qword [variable_line_show_from_char]
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	qword [variable_cursor_indicator]
	sub	rsi,	rcx
	int	0x40

	mov	rcx,	qword [variable_cursor_in_line]
	sub	rcx,	qword [variable_line_show_from_char]
	sub	ecx,	dword [variable_cursor_position]
	jz	.nothing_left

.nothing_left:
	; wyczyść pozostałą część linii, jeśli jest
	mov	ax,	0x0104
	int	0x40

	mov	ecx,	dword [variable_screen_size]
	dec	rcx
	sub	ecx,	ebx
	jz	start.debug

	mov	ax,	0x0102
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	r8,	" "
	int	0x40

	mov	ax,	0x0105
	mov	rbx,	qword [variable_cursor_position]
	int	0x40

	jmp	start.debug
