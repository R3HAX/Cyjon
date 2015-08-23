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

key_arrow_down:
	;oblicz koniec linii aktualnej
	mov	rsi,	qword [cursor_position]
	mov	ecx,	dword [cursor_yx]
	sub	rsi,	rcx
	add	rsi,	qword [line_chars_count]

	; sprawdź czy znajdujemy się na końcu dokumentu
	cmp	rsi,	qword [document_chars_count]
	je	start.loop	; nie można przestawić kursora o jedną linię w dół

	; oblicz rozmiar następnej linii -------------------------------

	; pomiń znak nowej linii
	inc	rsi

	; zapisz pozycje kursora wewnątrz dokumentu
	mov	qword [cursor_position],	rsi

	; przygotuj adres pozycji kursora do obliczeń
	add	rsi,	qword [document_address_start]

	; zliczaj
	call	count_chars_in_line

	; zapisz rozmiar następnej linii
	mov	qword [line_chars_count],	rcx

	; sprawdź czy można ustawić kursor w tej samej kolumnie
	cmp	dword [cursor_yx],	ecx
	jbe	.right_position	; jeśli tak, zmnień tylko wiersz

	; ustaw kursor na końcu następnej linii
	mov	dword [cursor_yx],	ecx

	; przesuń pozycje kursora wewnątrz dokumentu na koniec następnej linii
	add	qword [cursor_position],	rcx

	; kontynuuj
	jmp	.coretted

.right_position:
	; przesuń pozycje kursora wewnątrz dokumentu w miejsce kursora
	mov	ecx,	dword [cursor_yx]
	add	qword [cursor_position],	rcx

.coretted:
	; sprawdź czy kursor znajduje się na końcu ekranu (wiersz 0)
	mov	rax,	qword [screen_xy]
	shr	rax,	32
	sub	rax,	qword [interface_height]
	cmp	dword [cursor_yx + 0x04],	eax
	jb	.no	; jeśli nie, zmień numer wiersza

	; kursor znajduje się na początku ekranu, zmień numer wiersza od którego wyświetlamy dokument na wcześniejszy
	inc	qword [show_line]

	; aktualizuj zawartość ekranu
	call	print

	; koniec obsługi klawisza
	jmp	start.loop

.no:
	; ustaw nową pozycję kursora
	inc	dword [cursor_yx + 0x04]

	; aktualizuj pozycje kursora
	call	set_cursor

	; koniec obsługi klawisza
	jmp	start.loop
