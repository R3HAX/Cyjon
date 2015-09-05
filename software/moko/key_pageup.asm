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

key_pageup:
	; sprawdź czy jest możliwość przewinięcia dokumentu o 20 linii
	mov	rax,	qword [screen_xy]
	shr	rax,	32
	sub	rax,	qword [interface_all_height]

	cmp	qword [show_line],	rax
	jb	.no	; jeślie nie, wyświetl dokument od poczatku

	; jeśli tak, wyświetl poprzednie 20 linii z dokumentu
	sub	qword [show_line],	rax

	; załaduj licznik
	mov	rcx,	qword [show_line]

	; szukaj adresu pozycji kursora wewnątrz dokumentu -------------
	call	address_of_shown_line

	; kontynuuj
	jmp	.continue

.no:
	; wyświetl pierwsze 20 linii dokumentu
	mov	qword [show_line],	VARIABLE_EMPTY

	; ustaw wskaźnik nowej pozycji kursora wewnątrz dokumentu-------
	xor	rsi,	rsi

	; ustaw pozycje kursora wewnątrz dokumentu
	mov	qword [cursor_position],	rsi

	; oblicz adres bezwzględny początku linii w dokumencie
	add	rsi,	qword [document_address_start]

.continue:
	; policz ilość znaków w aktualnej linii ------------------------
	call	count_chars_in_line

	; koryguja adres pozycji kursora wewnątrz dokumentu i zapisz wynik
	sub	rsi,	qword [document_address_start]
	mov	qword [cursor_position],	rsi

	; zapisz ilość znaków w aktualnej linii
	mov	qword [line_chars_count],	rcx

	; wyświetl aktualną część dokumentu
	call	print

	; ustaw kursor na początek ekranu
	mov	rax,	2
	shl	rax,	32
	mov	qword [cursor_yx],	rax
	call	set_cursor

	; koniec obsługi funkcji
	jmp	start.loop
