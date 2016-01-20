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

	; wyświetl podstawową informację o trybie graficznym
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_sound_blaster_16
	call	cyjon_screen_print_string

	ret

text_sound_blaster_16	db	' ISA Sound Blaster 16.', VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

; sound IRQ5
irq37:
	xchg	bx,	bx

	iretq
