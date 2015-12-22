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

key_function_read:
	; obsłużono klawisz funkcyjny, wyłącz semafor
	mov	byte [variable_semaphore_key_ctrl],	VARIABLE_FALSE

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	ebx,	VARIABLE_INTERFACE_INTERACTIVE
	shl	rbx,	32	; przesuń do pozycji wiersza
	push	rbx	; zapamiętaj
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; zmień kolor linii zapytań
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [rsp]
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; wyświetl pytanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	rcx,	VARIABLE_FULL	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	rsi,	text_open_file
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; rozmiar polecenia do pobrania
	mov	ecx,	dword [variable_screen_size]
	sub	ecx,	dword [text_open_file_chars]	; ilość znaków już wykorzystana w linii
	dec	ecx

	; gdzie przechować wprowadzony ciąg znaków
	mov	rdi,	file_name_buffor
	; bufor nie zawiera danych
	mov	r8,	qword [file_name_chars_count]
	; pobierz od użytkownika tekst
	call	library_input
	jc	.file_name

.end:
	; ustaw kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	pop	rbx
	int	VARIABLE_KERNEL_SERVICE

	; wyczyść linię zapytań
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; ustaw kursor
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_cursor_position]
	int	VARIABLE_KERNEL_SERVICE

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

	; załaduj plik do przestrzeni dokumentu
	mov	rax,	VARIABLE_KERNEL_SERVICE_FILESYSTEM_READ_FILE
	mov	rbx,	0	; katalog /   [nie mamy jeszcze obsługi przekazywania argumentów specjalnych (np. aktualny katalog, rozmiar wewnętrzny terminala, zmienne globalne)]
	mov	rcx,	qword [file_name_chars_count]
	mov	rsi,	file_name_buffor
	mov	rdi,	qword [variable_document_address_start]
	int	VARIABLE_KERNEL_SERVICE

	cmp	rax,	VARIABLE_EMPTY
	je	.end	; lub wyświetl informację, pliku nie znaleziono i pozwól na poprawę nazwy (do zrobienia)

	; zapisz identyfikator załadowanego pliku
	mov	qword [file_identificator],	rax

	; ustal koniec załadowanego dokumentu
	mov	rdi,	rdx
	add	rdi,	qword [variable_document_address_start]
	call	library_align_address_up_to_page

	; zapisz
	mov	qword [variable_document_address_end],	rdi

	; wyczyść pozostałą część przestrzeni pamięci dokumentu (strony)
	; dmucham na zimne

	; ustal początek przestrzeni czyszczonej
	mov	rdi,	qword [variable_document_address_start]
	add	rdi,	rdx

	; ustal rozmiar przestrzeni czyszczonej
	mov	rcx,	qword [variable_document_address_end]
	sub	rcx,	rdi

	xor	al,	al

.loop:
	; wyczyść
	mov	byte [rdi],	al
	add	rdi,	VARIABLE_INCREMENT
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop

	; zapamiętaj rozmiar pliku w znakach
	mov	qword [variable_document_count_of_chars],	rdx

	; ustaw kursor w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	xor	rbx,	rbx
	int	VARIABLE_KERNEL_SERVICE

	; wyczyść nagłówek
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	ecx,	dword [variable_screen_size]	; szerokość ekranu w znakach
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	r8,	VARIABLE_ASCII_CODE_SPACE
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; ustaw kursor w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	1
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; wyświetl nawę pliku w nagłówku
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [file_name_chars_count]	; przywróć ilość znaków przypadających na nazwe pliku
	mov	rdx,	VARIABLE_COLOR_LIGHT_GRAY
	mov	rsi,	file_name_buffor	; przywróć wskaźnik do nazwy pliku
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; inicjalizacja załadowanego dokumentu -------------------------

	; wyświetl zawartość dokumentu od pierwszej linii
	mov	qword [variable_document_line_start],	VARIABLE_EMPTY
	; ustaw kursor na poczatku dokumentu
	mov	rax,	VARIABLE_CURSOR_POSITION_INIT
	mov	qword [variable_cursor_position],	rax
	mov	rax,	qword [variable_document_address_start]
	mov	qword [variable_cursor_indicator],	rax
	mov	qword [variable_cursor_position_on_line],	VARIABLE_EMPTY

	; oblicz rozmiar pierwszej linii
	mov	rsi,	qword [variable_document_address_start]
	call	count_chars_in_line
	mov	qword [variable_line_count_of_chars],	rcx
	; wyświetl linię od początku
	mov	qword [variable_line_print_start],	VARIABLE_EMPTY

	mov	qword [variable_document_count_of_lines],	VARIABLE_TRUE
	mov	rcx,	qword [variable_document_count_of_chars]

	push	rsi

.count_lines:
	cmp	byte [rsi],	VARIABLE_ASCII_CODE_NEWLINE
	jne	.check

	add	qword [variable_document_count_of_lines],	VARIABLE_INCREMENT

.check:
	add	rsi,	VARIABLE_INCREMENT
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.count_lines

	; wyczyść przestrzeń dokumentu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN	; procedura czyszcząca ekran
	mov	rbx,	VARIABLE_INTERFACE_HEADER_HEIGHT	; za nagłówkiem
	mov	ecx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	rcx,	VARIABLE_INTERFACE_HEIGHT	; tylko przestrzeń dokumentu
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	; ustaw kursor na początku przestrzeni dokumentu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	VARIABLE_CURSOR_POSITION_INIT
	int	VARIABLE_KERNEL_SERVICE	; wykonaj

	pop	rsi

	mov	ecx,	dword [variable_screen_size + VARIABLE_QWORD_HIGH]
	sub	rcx,	VARIABLE_INTERFACE_HEIGHT

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

.print:
	; załaduj znak
	movzx	r8,	byte [rsi]

	; koniec dokumentu?
	cmp	r8,	VARIABLE_ASCII_CODE_TERMINATOR
	je	.end

	; znak nowej linii?
	cmp	r8,	VARIABLE_ASCII_CODE_NEWLINE
	je	.new_line

	; wyświetl znak
	push	rcx
	mov	ecx,	VARIABLE_TRUE
	int	VARIABLE_KERNEL_SERVICE	; wykonaj
	pop	rcx

	add	rsi,	VARIABLE_INCREMENT

	; kontynuuj
	jmp	.print

.new_line:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; wyświetl spacje do końca linii
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rcx,	VARIABLE_FULL
	mov	rsi,	text_new_line
	int	VARIABLE_KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	add	rsi,	VARIABLE_INCREMENT

	; kontynuuj
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.print

	jmp	.end

file_identificator			dq	VARIABLE_EMPTY
file_name_chars_count			dq	VARIABLE_EMPTY
file_name_buffor	times	256	db	VARIABLE_EMPTY
					db	VARIABLE_ASCII_CODE_TERMINATOR

text_open_file				db	'Open file: ', VARIABLE_ASCII_CODE_TERMINATOR
text_open_file_chars			dd	11
