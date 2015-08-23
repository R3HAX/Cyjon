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

key_backspace:
	; sprawdź czy linia zawiera znaki
	cmp	byte [line_chars_count],	0x00
	je	start.loop	; jeśli nie, brak obsługi

	; sprawdź czy pozycja kursora jest na końcu dokumentu
	mov	rsi,	qword [cursor_position]
	cmp	rsi,	qword [document_chars_count]
	jne	.into

	; usuń znak z końca dokumentu
	add	rsi,	qword [document_address_start]
	mov	byte [rsi - 0x01],	0x00

	; kontynuuj
	jmp	.continue

.into:
	; koryguj adres źródłowy
	add	rsi,	qword [document_address_start]

	; sprawdź czy jesteśmy na początku linii
	cmp	byte [cursor_yx],	0x00
	je	start.loop	; jeśli tak, brak obsługi

	; przesuń wszystkie znaki za backspace o jeden znak w lewo

	; ustaw wskaźnik docelowy
	mov	rdi,	rsi
	; pozycja o jeden znak wcześniej
	dec	rdi

	; ustaw ilość znaków do przesunięcia
	mov	rcx,	qword [document_chars_count]
	sub	rcx,	qword [cursor_position]

.loop:
	; pobierz znak z aktualnego miejsca
	lodsb
	; zapisz do poprzedniego
	stosb
	; kontynuuj dla pozostałych znaków
	loop	.loop

	; ustaw znak końca dokumentu
	xor	al,	al
	stosb	; zapisz

.continue:
	; zmniejsz ilość znaków przechowywanych w dokumencie
	dec	qword [document_chars_count]

	; zmniejsz rozmiar aktualnej linii
	dec	byte [line_chars_count]

	; przesuń aktywną pozycję na poprzedni znak w dokumencie
	dec	qword [cursor_position]

	; przesuń kursor w lewo
	dec	byte [cursor_yx]

	; wyświetl nową zawartość dokumentu
	call	print

	; ustaw kursor na prawidłową pozycję
	call	set_cursor

	;powrót z funkcji
	jmp	start.loop
