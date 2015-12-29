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

key_function_write:
	; obsłużono klawisz funkcyjny, wyłącz semafor
	mov	byte [variable_semaphore_key_ctrl],	VARIABLE_FALSE

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	ebx,	VARIABLE_INTERFACE_INTERACTIVE
	shl	rbx,	32	; przesuń do pozycji wiersza
	push	rbx	; zapamiętaj
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; zmień kolor linii zapytań
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [rsp]
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; wyświetl pytanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	rcx,	VARIABLE_FULL	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	rsi,	text_save_file
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; rozmiar polecenia do pobrania
	mov	ecx,	dword [variable_screen_size]
	sub	ecx,	dword [text_open_file_chars]	; ilość znaków już wykorzystana w linii
	dec	ecx

	; gdzie przechować wprowadzony ciąg znaków
	mov	rdi,	file_name_buffor
	; rozmiar bufora (jeśli zawiera jakiekolwiek dane)
	mov	r8,	qword [file_name_chars_count]
	; pobierz od użytkownika tekst
	call	library_input
	jc	.file_name

.end:
	; ustaw kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	pop	rbx
	int	STATIC_KERNEL_SERVICE

	; wyczyść linię zapytań
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; ustaw kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_cursor_position]
	int	STATIC_KERNEL_SERVICE

	; zakończ obługę funkcji
	jmp	start.noKey

.file_name:
	; szukaj słowa
	call	library_find_first_word
	jnc	.end

	; przesuń słowo na początek bufora nazwy pliku
	mov	rsi,	file_name_buffor

	; ustaw na swoje miejsca
	xchg	rdi,	rsi
	; zapamiętaj rozmiar słowa na przyszłość
	mov	qword [file_name_chars_count],	rcx
	; przesuń
	rep	movsb

	mov	rax,	VARIABLE_KERNEL_SERVICE_FILESYSTEM_SAVE_FILE
	mov	rbx,	0	; katalog /   [nie mamy jeszcze obsługi przekazywania argumentów specjalnych (np. aktualny katalog, rozmiar wewnętrzny terminala, zmienne globalne)]
	mov	rcx,	qword [file_name_chars_count]
	mov	rdx,	qword [variable_document_count_of_chars]
	mov	rsi,	file_name_buffor
	mov	rdi,	qword [variable_document_address_start]
	int	STATIC_KERNEL_SERVICE

	; ustaw kursor w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	xor	rbx,	rbx
	int	STATIC_KERNEL_SERVICE

	; wyczyść nagłówek
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; ustaw kursor w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	1
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; wyświetl nawę pliku w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [file_name_chars_count]	; przywróć ilość znaków przypadających na nazwe pliku
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	rsi,	file_name_buffor	; przywróć wskaźnik do nazwy pliku
	int	STATIC_KERNEL_SERVICE	; wykonaj

	jmp	.end

text_save_file			db	'Save as: ', VARIABLE_ASCII_CODE_TERMINATOR
text_save_file_chars		dd	9
