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

key_function_save:
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
	mov	r8,	BACKGROUND_COLOR_DEFAULT	; szare tło
	int	0x40	; wykonaj

	; ustaw kursor w wierszu informacyjnym
	mov	ax,	0x0105
	mov	rbx,	qword [rsp]
	int	0x40	; wykonaj

	; wyświetl zapytanie
	mov	ax,	0x0101
	mov	rbx,	COLOR_DEFAULT
	xor	rcx,	rcx	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	mov	rsi,	text_save_as
	int	0x40	; wykonaj

	; kolor wprowadzania tekstu
	mov	rbx,	COLOR_DEFAULT
	; rozmiar polecenia do pobrania
	mov	ecx,	dword [screen_xy]
	sub	rcx,	9	; ilość znaków już wykorzystana w linii
	dec	rcx
	; domyślny kolor tła
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
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
	mov	rbx,	COLOR_DEFAULT
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	rdx,	' '	; spacja
	mov	r8,	BACKGROUND_COLOR_DEFAULT
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

	; zapamiętaj rozmiar na przyszłość
	mov	qword [file_name_count],	rcx

.now:
	mov	rdx,	qword [document_chars_count]
	mov	rsi,	file_name_cache
	mov	rdi,	qword [document_address_start]
	; zapisz plik na partycji użytkownika
	mov	rax,	0x0302
	int	0x40

	; ustaw kursor w wierszu zapytań
	mov	ax,	0x0105
	pop	rbx
	int	0x40	; wykonaj

	; wyczyść linie zapytań
	mov	ax,	0x0102
	mov	rbx,	COLOR_DEFAULT
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	rdx,	' '	; spacja
	mov	r8,	BACKGROUND_COLOR_DEFAULT
	int	0x40	; wykonaj

	; sprawdź czy użytkownik chciał wyjść z programu po zapisie
	cmp	byte [semaphore_exit],	0x01
	je	key_function_exit.now	; tak

	; ustaw kursor w nagłówku
	mov	ax,	0x0105
	xor	rbx,	rbx
	int	0x40

	; wyczyść nagłówek
	mov	ax,	0x0102
	xor	rbx,	rbx	; czarne litery
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	rdx,	' '	; spacja
	mov	r8,	BACKGROUND_COLOR_DEFAULT	; szare tło
	int	0x40	; wykonaj

	; ustaw kursor w nagłówku
	mov	ax,	0x0105
	mov	rbx,	0x0000000000000001
	int	0x40	; wykonaj

	; wyświetl nawę pliku w nagłówku
	; wyświetl zapytanie
	mov	ax,	0x0101
	mov	rbx,	COLOR_DEFAULT
	mov	rcx,	qword [file_name_count]	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	mov	rsi,	file_name_cache
	int	0x40	; wykonaj

	; ustaw kursor na swoją pozycję
	call	set_cursor

	; wyłącz flagę zmodyfikowanego pliku
	mov	byte [semaphore_modified],	0x00

	; kontynuuj przeszukiwanie
	jmp	start.loop

text_save_as			db	'Save as: ', ASCII_CODE_TERMINATOR
