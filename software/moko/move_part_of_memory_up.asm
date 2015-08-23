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

move_memory_up:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx

.loop:
	; pobierz znak z pozycji źródła
	mov	dl,	byte [rsi]
	; załaduj w miejsce docelowe
	mov	byte [rdi],	dl

	; przesuń wskaźniki na następny (tak naprawdę poprzedni) znak
	dec	rsi
	dec	rdi

	; wykonaj dla pozostałych znaków w dokumencie
	loop	.loop

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret
