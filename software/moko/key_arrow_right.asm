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

key_arrow_right:
	; sprawdź czy jesteśmy na końcu dokumentu
	mov	rsi,	qword [cursor_position]
	cmp	rsi,	qword [document_chars_count]
	je	start.loop	; brak możliwości przesunięcia kursora

	; sprawdź czy jesteśmy na końcu linii
	add	rsi,	qword [document_address_start]
	cmp	byte [rsi],	0x0A
	je	.line_end	; przesuń kursor na początek nowej linii

	; przesuń kursor w prawo
	inc	dword [cursor_yx]

.end:
	; aktualizuj pozycje kursora
	call	set_cursor

	; przesuń pozycję kursora w dokumencie o jeden znak w prawo
	inc	qword [cursor_position]

	; koniec obsługi klawisza
	jmp	start.loop

.line_end:
	; przesuń wskaźnik na początek następnej linii
	inc	rsi

	; oblicz rozmiar następnej linii
	call	count_chars_in_line

	; zapisz
	mov	qword [line_chars_count],	rcx

	; sprawdź czy jesteśmy na końcu ekranu
	mov	rax,	qword [screen_xy]
	shr	rax,	32
	sub	rax,	qword [interface_height]
	cmp	dword [cursor_yx + 0x04],	eax
	jb	.move

	; zmień numer linii wyświetlanej
	inc	qword [show_line]

	; aktualizuj zawartość dokumentu na ekranie
	call	print

	; nie zmieniaj wiersza dla kursora
	jmp	.no_change

.move:
	; przesuń kursor o jeden wiersz w dół
	inc	dword [cursor_yx + 0x04]

.no_change:
	; ustaw kursor na początku wiersza
	mov	dword [cursor_yx],	0

	; kontynuuj
	jmp	.end
