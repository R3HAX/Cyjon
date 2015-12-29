; Copyright (C) 2013-2016 Wataha.net
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

VARIABLE_ISA_SOUND_BLASTER_16_PORT	equ	0x0220

variable_sound_card_sb16_semaphore	db	VARIABLE_EMPTY

sound:
	; wyślij informacje o resecie do karty
	mov	al,	1
	mov	dx,	VARIABLE_ISA_SOUND_BLASTER_16_PORT
	add	dl,	6
	out	dx,	al

	; odczekaj chwile
	hlt

	; usuń informacje o resecie z karty
	xor	al,	al
	out	dx,	al

	; karta dźwiękowa powinna być już zresetowana, sprawdzamy
	mov	rcx,	65535

.check:
	; pobierz status urządzenia
	mov	dx,	VARIABLE_ISA_SOUND_BLASTER_16_PORT
	add	dx,	0x0e
	in	al,	dx

	; bit 7 włączony - jest odpowiedź
	or	al,	al
	jns	.nothing

	; pobierz odpowiedź z urządzenia
	sub	dl,	0x04
	in	al,	dx

	; karta gotowa?
	cmp	al,	0xaa
	je	.ready

.nothing:
	; karta niegotowa
	; sprawdź raz jeszcze
	dec	cx
	jnz	.check

	; brak karty dźwiękowej
	ret

.ready:
	; karta dźwiękowa zresetowana i gotowa do pracy
	mov	byte [variable_sound_card_sb16_semaphore],	VARIABLE_TRUE

	ret
