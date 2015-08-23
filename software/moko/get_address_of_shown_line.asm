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

address_of_shown_line:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx

	; wskaźnik poczatku dokumentu
	mov	rsi,	qword [document_address_start]

	; sprawdź czy pierwsza linia
	cmp	rcx,	0
	je	.end	; adresem jest początek dokumentu

.loop:
	; pobierz znak z adresu wskaźnika, zwieksz rsi o 1
	lodsb

	; sprawdź czy znak jest nową linią
	cmp	al,	0x0A
	jne	.loop	; jeśli nie, szukaj dalej

	; znaleziono znak nowej linii, mniejsz ilość pozostałych do odnalezienia i kontynuuj szukanie
	loop	.loop

.end:
	; przywróc oryginalne rejestry
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
