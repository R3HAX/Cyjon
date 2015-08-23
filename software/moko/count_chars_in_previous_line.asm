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

count_chars_in_previous_line:
	; wyczyść licznik znaków w linii
	xor	rcx,	rcx

.loop:
	; jeśli początek dokumentu, zakończ
	cmp	rsi,	qword [document_address_start]
	je	.end

	; jeśli znak nowej linii, koniec
	cmp	byte [rsi - 0x01],	0x0A
	je	.end

	; przesuń wskaźnik na poprzedni znak
	dec	rsi

	; zwiększ ilość znaków przechowywanych w poprzedniej linii
	inc	rcx

	; kontynuuj
	jmp	.loop

.end:
	; koryguj wskaźnik o adres początku dokumentu
	sub	rsi,	qword [document_address_start]

	; powrót z procedury
	ret
