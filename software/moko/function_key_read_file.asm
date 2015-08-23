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

key_function_read:
	; obsłużono klawisz funkcyjny, wyłącz semafor
	mov	byte [semaphore_ctrl],	0x00

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	0x0105
	mov	ebx,	dword [screen_xy + 0x04]
	dec	ebx
	sub	ebx,	dword [interface_menu_height]
	shl	rbx,	32
	push	rbx	; zapamiętaj
	int	0x40	; wykonaj

	; zmień kolor linii zapytań
	mov	ax,	0x0102
	xor	rbx,	rbx	; czarne litery
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	rdx,	' '	; spacja
	mov	r8,	0xaaaaaa	; szare tło
	int	0x40	; wykonaj

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	0x0105
	mov	rbx,	qword [rsp]
	int	0x40	; wykonaj

	; wyświetl zapytanie
	mov	ax,	0x0101
	mov	rbx,	0x272727
	xor	rcx,	rcx	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	0xaaaaaa
	mov	rsi,	text_open_file
	int	0x40	; wykonaj

	; kolor wprowadzania tekstu
	mov	rbx,	0x272727
	; rozmiar polecenia do pobrania
	mov	ecx,	dword [screen_xy]
	sub	rcx,	9	; ilość znaków już wykorzystana w linii
	dec	rcx
	; domyślny kolor tła
	mov	rdx,	0xaaaaaa
	; gdzie przechować wprowadzony ciąg znaków
	mov	rdi,	file_name_cache
	; bufor nie zawiera danych
	mov	r8,	qword [file_name_count]
	; pobierz od użytkownika tekst
	call	library_input

	; sprawdź czy cokolwiek wpisano
	jc	.file_settled	; jeśli nie, koniec

.end:
	; ustaw kursor na początku wiersza informacyjnego
	mov	ax,	0x0105
	pop	rbx
	int	0x40	; wykonaj

	; wyczyść linie zapytań
	mov	ax,	0x0102
	mov	rbx,	0xaaaaaa
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	rdx,	' '	; spacja
	mov	r8,	0x272727
	int	0x40	; wykonaj

	; ustaw kursor na swoją pozycję
	call	set_cursor

	; zakończ obsługę skrótu
	jmp	start.loop

.file_settled:
	; wytnij z ciągu znaków podanych przez użytkownika pierwsze słowo
	call	library_find_first_word

	; sprawdź czy znaleziono pierwsze słowo
	jnc	.end	; jeśli nie, koniec obsługi skrótu

	; przesuń słowo na początek bufora nazwy pliku
	mov	rsi,	file_name_cache

	; ustaw na swoje miejsca
	xchg	rdi,	rsi
	; zapamiętaj rozmiar słowa na przyszłość
	mov	qword [file_name_count],	rcx
	; przesuń
	rep	movsb

	; załaduj plik do przestrzeni dokumentu
	mov	rax,	0x0301
	mov	rcx,	qword [file_name_count]
	mov	rsi,	file_name_cache	; wskaźnik do nazwy pliku
	mov	rdi,	qword [document_address_start]
	int	0x40	; wykonaj

	; sprawdź czy plik odczytano
	cmp	rax,	-1
	je	.end

	; ustal koniec załadowanego dokumentu
	mov	rdi,	rdx
	add	rdi,	qword [document_address_start]
	call	library_align_address_up_to_page

	; zapisz
	mov	qword [document_address_end],	rdi

	; wyczyść pozostałą część przestrzeni pamięci (strony)

	; ustal początek przestrzeni czyszczonej
	mov	rdi,	qword [document_address_start]
	add	rdi,	rdx

	; ustal rozmiar przestrzeni czyszczonej
	mov	rcx,	qword [document_address_end]
	sub	rcx,	rdi

	; wyczyść
	xor	rax,	rax
	rep	stosb

	; zapamiętaj rozmiar pliku
	push	rdx

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	0x0105
	mov	ebx,	dword [screen_xy + 0x04]
	dec	ebx
	sub	ebx,	dword [interface_menu_height]
	shl	rbx,	32
	int	0x40	; wykonaj

	; zmień kolor linii zapytań
	mov	ax,	0x0102
	xor	rbx,	rbx	; czarne litery
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	rdx,	' '	; spacja
	mov	r8,	0xaaaaaa	; szare tło
	int	0x40	; wykonaj

	; ustaw kursor w nagłówku
	mov	ax,	0x0105
	xor	rbx,	rbx
	int	0x40

	; zmień kolor linii zapytań
	mov	ax,	0x0102
	mov	rbx,	0xaaaaaa	; kolor znaków
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	rdx,	' '	; spacja
	mov	r8,	0x272727
	int	0x40	; wykonaj

	; ustaw kursor w nagłówku
	mov	ax,	0x0105
	mov	ebx,	1
	int	0x40	; wykonaj

	; wyświetl nawę pliku w nagłówku
	mov	ax,	0x0101
	mov	rbx,	0x272727
	mov	rcx,	qword [file_name_count]	; przywróć ilość znaków przypadających na nazwe pliku
	mov	rdx,	0xaaaaaa
	mov	rsi,	file_name_cache	; przywróć wskaźnik do nazwy pliku
	int	0x40	; wykonaj

	; inicjalizacja załadowanego dokumentu -------------------------

	; wyświetl zawartość dokumentu od pierwszej linii
	mov	qword [show_line],	0
	; aktualizuj zawartość ekranu
	call	print

	; ustaw kursor na poczatku dokumentu
	mov	qword [cursor_yx],	0x02
	shl	qword [cursor_yx],	32
	; aktualizuj pozycje kursora
	call	set_cursor

	; przywróć rozmiar dokumentu
	pop	rdx

	; zapisz rozmiar dokumentu
	mov	qword [document_chars_count],	rdx

	; oblicz rozmiar pierwszej linii
	mov	rsi,	qword [document_address_start]

	; zliczaj
	call	count_chars_in_line

	; zapisz wynik
	mov	qword [line_chars_count],	rcx

	; oblicz ilość linii w dokumencie

	; wyzeruj licznik
	mov	qword [document_lines_count],	0

.loop:
	; załaduj znak do akumulatora
	lodsb

	; koniec dokumentu?
	cmp	byte [rsi],	0x00
	je	start.loop	; zakończono inicjalizacje dokumentu

	; znak nowej linii?
	cmp	byte [rsi],	0x0A
	jne	.loop	; jeśli tak, zwiększ licznik

	; zwiększ ilość znaków przechowywanych w linii
	inc	qword [document_lines_count]

	; kontynuuj przeszukiwanie
	jmp	.loop

file_name_count		dq	0x0000000000000000
file_name_cache		times	80	db	0x00
					db	ASCII_CODE_TERMINATOR

text_open_file			db	'Open file: ', ASCII_CODE_TERMINATOR
