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

;===============================================================================
; procedura ustawia częstotliwość wywołania przerwania sprzęrowego IRQ0
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
programmable_interval_timer:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	mov	rax,	1193182	; częstotliwość kryształu 1193182 Hz
	xor	rdx,	rdx	; czyścimy starszą część / resztę
	mov	rcx,	PIT_CLOCK	; częstotliwość w Hz
	div	rcx	; rdx:rax / rcx

	; zachowaj wynik
	push	rax

	; przygotuj kanał 0
	mov	al,	0x36	; kanał nr 0
	out	0x43,	al

	; przywróć wynik
	pop	rax

	; wprowadź dane do kanału 0
	out	0x40,	al	; młodsza część wyniku
	xchg	al,	ah
	out	0x40,	al	; starsza część wyniku

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
