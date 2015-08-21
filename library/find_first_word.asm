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
; procedura pobiera od użytkownika ciąg znaków zakończony klawiszem ENTER o sprecyzowanej długości
; IN:
;	rcx - rozmiar bufora
;	rdi - wskaźnik do bufora przechowującego pobrane znaki
; OUT:
;	rcx - rozmiar pierwszego znalezionego "słowa"
;	rdi - wskaźnik bezwzględnym w ciągu do znalezionego słowa
;
; pozostałe rejestry zachowane
library_find_first_word:
	; zachowaj oryginalne rejestry
	push	rax

.find:
	; pomiń spacje przed słowem
	cmp	byte [rdi],	0x20
	je	.leave

	; pomiń znak tabulacji
	cmp	byte [rdi],	0x09
	je	.leave

	; znaleziono piwerszy znak należący do słowa
	jmp	.char

.leave:
	; przesuń wskaźnik bufora na następny znak
	inc	rdi

	; kontynuuj
	loop	.find

.char:
	; sprawdź czy w bufor coś zawiera
	cmp	rcx,	0
	je	.not_found	; jeśli pusty

	; oblicz rozmiar słowa

	; zachowaj adres początku słowa
	push	rdi

	; wyczyść licznik
	xor	rax,	rax

.count:
	; sprawdź czy koniec słowa (space)
	cmp	byte [rdi],	0x20
	je	.ready

	; sprawdź czy koniec słowa (tab)
	cmp	byte [rdi],	0x09
	je	.ready

	; przesuń wskaźnik na następny znak w buforze polecenia
	inc	rdi

	; zwiększ licznik znaków przypadających na znalezione polecenie
	inc	rax

	; zliczaj dalej
	loop	.count

.ready:
	; ustaw rozmiar słowa w znakach
	mov	rcx,	rax

	; przywróć adres początku słowa
	pop	rdi

	; ustaw flagę
	stc

	; koniec
	jmp	.end

.not_found:
	; nie znaleziono słowa w ciągu znaków
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret
