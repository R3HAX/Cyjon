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

initialization:
	mov	rdi,	document_area
	call	library_align_address_up_to_page

	mov	qword [variable_document_address_start],	rdi
	mov	qword [variable_cursor_indicator],	rdi

	mov	qword [variable_document_address_end],	rdi
	add	qword [variable_document_address_end],	VARIABLE_MEMORY_PAGE_SIZE

	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_MEMORY_ALLOCATE
	mov	ecx,	VARIABLE_MEMORY_PAGE_SIZE / VARIABLE_MEMORY_PAGE_SIZE
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SIZE
	int	STATIC_KERNEL_SERVICE
	mov	qword [variable_screen_size],	rbx

	; wyświetl interfejs ---------------------------------------------------

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN
	xor	ebx,	ebx
	xor	ecx,	ecx
	int	STATIC_KERNEL_SERVICE

	; ustaw tło nagłówka
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	ecx,	dword [variable_screen_size]
	mov	edx,	VARIABLE_COLOR_DEFAULT
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE

	; ustaw kursor w nagłówku (nazwa pliku)
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	1
	int	STATIC_KERNEL_SERVICE

	; wyświetl nazwę pliku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_header_default
	int	STATIC_KERNEL_SERVICE

	; ustaw kursor w stopce (menu)
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	ebx,	VARIABLE_DECREMENT
	shl	rbx,	32
	int	STATIC_KERNEL_SERVICE

	push	rax

	; skrót X ==============================================================
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_exit_shortcut
	int	0x40

	; opis
	xchg	rbx,	rdx
	mov	rsi,	text_exit
	int	0x40

	; skrót R ==============================================================
	xchg	rbx,	rdx
	mov	rsi,	text_open_shortcut
	int	0x40

	; opis
	xchg	rbx,	rdx
	mov	rsi,	text_open
	int	0x40
	
	; inicjalizuj początkową pozycje kursora na ekranie
	pop	rax
	mov	rbx,	VARIABLE_CURSOR_POSITION_INIT
	int	0x40

	; sprawdź czy podano w argumentach plik do odczytu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_ARGS
	int	STATIC_KERNEL_SERVICE

	add	rdi,	VARIABLE_PROGRAM_ARGS_IGNORE_NAME
	sub	rcx,	VARIABLE_PROGRAM_ARGS_IGNORE_NAME
	jz	.end
	cmp	rcx,	VARIABLE_FULL
	je	.end

	mov	rax,	qword [variable_cursor_position]
	mov	qword [rsp],	rax
	jmp	key_function_read.file_name

.end:
	; powrót z procedury
	ret
