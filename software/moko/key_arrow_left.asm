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

key_arrow_left:
	; czy kursor znajduje się na początku aktualnej linii?
	cmp	dword [cursor_yx],	0
	je	.change

	; przesuń aktualną pozycję w dokumencie o jeden znak wstecz
	dec	qword [cursor_position]

	; przesuń kursor w lewo
	dec	dword [cursor_yx]

	; ustaw
	call	set_cursor
	
	; kontynuuj
	jmp	start.loop

.change:
	; sprawdź czy jesteśmy na początku dokumentu
	cmp	qword [cursor_position],	0
	je	start.loop	; brak możliwości operowania kursorem

	; załaduj adres końca poprzedniej linii
	mov	rsi,	qword [document_address_start]
	add	rsi,	qword [cursor_position]
	; pomiń znak nowej linii
	dec	rsi

	; oblicz rozmiar i pocżątek poprzedniej linii
	call	count_chars_in_previous_line

	; zapisz ilość znaków w linii
	mov	qword [line_chars_count],	rcx

	; koryguj pozycje kursora wewnątrz dokumentu o ilość znaków w linii
	add	rsi,	rcx
	; zapisz pozycje kursora wewnątrz dokumentu
	mov	qword [cursor_position],	rsi

	; ustaw kursor na koniec poprzedniej linii ---------------------

	; sprawdź czy kursor znajduje się na początku ekranu
	cmp	dword [cursor_yx + 0x04],	0x02
	ja	.row

	; sprawdź czy można zmienić numer wyświetlanej linii
	cmp	qword [show_line],	0
	je	.leave

	; wyświetlaj dokument od poprzedniej linii
	dec	qword [show_line]

	; aktualizuj zawartość ekranu
	call	print

	; kontynuuj
	jmp	.leave

.row:
	; przesuń kursor o jedną linię w górę
	dec	dword [cursor_yx + 0x04]

.leave:
	; ustaw kursor na końcu linii
	mov	dword [cursor_yx],	ecx

	; aktualizuj pozycje kursora
	call	set_cursor

	; koniec
	jmp	start.loop
