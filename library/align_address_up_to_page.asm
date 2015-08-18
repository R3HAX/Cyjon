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

;=======================================================================
; inicjalizuje podstawowe zmienne dotyczące właściwości trybu graficznego
; IN:
;	rdi - wyrównuje wskaźnik adresu do pełnej strony 4 KiB
; OUT:
;	rdi
;
; pozostałe rejestry zachowane
library_align_address_up_to_page:
	; utwórz zmienną lokalną
	push	rdi

	; usuń młodszą część adresu
	and	di,	0xF000
	; sprawdź czy adres jest identyczny z zachowaną na stosie
	cmp	rdi,	qword [rsp]
	je	.end	; jeśli tak, koniec

	; przesuń adres o jedną ramkę do przodu
	add	rdi,	0x1000

.end:
	; usuń zmienną lokalną
	add	rsp,	0x08

	; powrót z procedury
	ret
