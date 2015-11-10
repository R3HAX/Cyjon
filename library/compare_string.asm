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

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; procedura ustawia domyślną macierz klawiszy (małe znaki)
; IN:
;	rcx	- ilość znaków do porównania
;	rsi	- adres ciągu pierwszego
;	rdi	- adres ciągu drugiego
; OUT:
;	CF	- jeśli obydwa ciągi poprawne
;
; wszystkie rejestry zachowane
library_compare_string:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

.loop:
	; załaduj znak z ciągu do rejestru al, zwieksz rejestr rsi o 1
	lodsb

	; sprawdź czy znak jest identyczny z znakiem z drugiego ciągu
	cmp	al,	byte [rdi]
	je	.ok

	; wyłącz flagę CF
	clc

.end:
	; przywróc oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

.ok:
	; przesuń wskaźnik rdi w drugim ciągu znaków na następną pozycję
	inc	rdi

	; kontynuuj
	loop	.loop

	; ustaw flagę CF
	stc

	; zakończ procedurę
	jmp	.end
