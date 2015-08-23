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

key_pagedown:
	; sprawdź czy dokument zawiera treść
	cmp	qword [document_chars_count],	0
	je	start.loop	; koniec obsługi klawisza

	; sprawdź czy można wyświetlić następne 20 lub mniej linii z dokumentu
	mov	rax,	qword [screen_xy]
	shr	rax,	32
	sub	rax,	qword [interface_all_height]

	; załaduj numer linii aktualnie wyświetlanej
	mov	rcx,	qword [show_line]
	; przesuń o rozmiar ekranu dalej
	add	rcx,	rax

	; sprawdź czy wyszliśmy poza dokument
	cmp	rcx,	qword [document_lines_count]
	ja	.after

	; pokaż następne 20 linii z dokumentu
	add	qword [show_line],	rax

.after:
	; przesuń kursor na ostatnią linię na ekranie
	mov	rcx,	qword [document_lines_count]
	sub	rcx,	qword [show_line]

	; sprawdź czy jest możliwość ustawienia kursora
	cmp	rcx,	rax
	jb	.continue	; kursor w obrębie ekranu

	; ustaw kursor na ostatniej linii
	mov	rcx,	rax
	dec	rcx

.continue:
	; dodaj przesunięcie do pozycji kursora
	mov	qword [cursor_yx],	2	; wiersz 0, kolumna 0
	shl	qword [cursor_yx],	32
	add	dword [cursor_yx + 0x04],	ecx

	; aktualizuj zawartość ekranu
	call	print

	; ustaw kursor w odpowiednie miejsce na ekranie
	call	set_cursor

	; koryguj numer linii
	add	rcx,	qword [show_line]

	; szukaj adresu pozycji kursora wewnątrz dokumentu
	call	address_of_shown_line

	; policz ilość znaków w aktualnej linii
	call	count_chars_in_line

	; koryguja adres pozycji kursora wewnątrz dokumentu i zapisz wynik
	sub	rsi,	qword [document_address_start]
	mov	qword [cursor_position],	rsi

	; zapisz ilość znaków w aktualnej linii
	mov	qword [line_chars_count],	rcx

	; koniec obsługi funkcji
	jmp	start.loop
