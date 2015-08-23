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

key_arrow_up:
	; oblicz poczatek linii aktualnej
	mov	rsi,	qword [document_address_start] 
	add	rsi,	qword [cursor_position]
	mov	ecx,	dword [cursor_yx]
	sub	rsi,	rcx

	; sprawdź czy znajdujemy się na początku dokumentu
	cmp	rsi,	qword [document_address_start]
	je	start.loop	; nie można przestawić kursora o jedną linię w górę

	; oblicz początek i rozmiar poprzedniej linii ------------------

	; pomiń znak nowej linii
	dec	rsi

	; zliczaj
	call	count_chars_in_previous_line

	; zapisz rozmiar poprzedniej linii
	mov	qword [line_chars_count],	rcx

	; zapisz pozycje kursora wewnątrz dokumentu
	mov	qword [cursor_position],	rsi

	; sprawdź czy można ustawić kursor w tej samej kolumnie
	cmp	dword [cursor_yx],	ecx
	jbe	.ok	; jeśli tak, zmnień tylko wiersz

	; ustaw kursor na końcu poprzedniej linii
	mov	dword [cursor_yx],	ecx

	; przesuń pozycje kursora wewnątrz dokumentu na koniec poprzedniej linii
	add	qword [cursor_position],	rcx

	; kontynuuj
	jmp	.updated

.ok:
	; przesuń pozycje kursora wewnątrz dokumentu w miejsce kursora
	mov	ecx,	dword [cursor_yx]
	add	qword [cursor_position],	rcx

.updated:
	; sprawdź czy kursor znajduje się na początku ekranu (wiersz 0)
	cmp	dword [cursor_yx + 0x04],	0x02
	ja	.no	; jeśli nie, zmień numer wiersza

	; kursor znajduje się na początku ekranu, zmień numer wiersza od którego wyświetlamy dokument na wcześniejszy
	dec	qword [show_line]

	; aktualizuj zawartość ekranu
	call	print

	; koniec obsługi klawisza
	jmp	start.loop

.no:
	; ustaw nową pozycję kursora
	dec	dword [cursor_yx + 0x04]

	; aktualizuj pozycje kursora
	call	set_cursor

	; koniec obsługi klawisza
	jmp	start.loop
