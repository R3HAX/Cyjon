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
	mov	rcx,	VARIABLE_PIT_CLOCK_HZ	; częstotliwość w Hz
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

cyjon_cmos_date_get:
	push	rax
	push	rbx

.loop:
	; pobierz prawidłowy czas
	mov	byte [variable_cmos_date_get_semaphore],	0x00

	; sekunda
	mov	al,	0x00
	out	VARIABLE_CMOS_PORT_OUT,	al	; wyślij
	in	al,	VARIABLE_CMOS_PORT_IN	; odbierz
	; sprawdź czy nastąpiła modyfikacja
	cmp	al,	byte [variable_cmos_second]
	je	.minute	; jeśli brak zmian, kontynuuj

	; zapisz
	mov	byte [variable_cmos_second],	al
	; modyfikacja!
	mov	byte [variable_cmos_date_get_semaphore],	0x01

.minute:
	; minuta
	mov	al,	0x02
	out	VARIABLE_CMOS_PORT_OUT,	al
	in	al,	VARIABLE_CMOS_PORT_IN
	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_minute]
	je	.hour	; jeśli brak zmian, kontynuuj

	; zapisz
	mov	byte [variable_cmos_minute],	al
	; modyfikacja!
	mov	byte [variable_cmos_date_get_semaphore],	0x01

.hour:
	; godzina
	mov	al,	0x04
	out	VARIABLE_CMOS_PORT_OUT,	al
	in	al,	VARIABLE_CMOS_PORT_IN
	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_hour]
	je	.day	; jeśli brak zmian, kontynuuj

	; zapisz
	mov	byte [variable_cmos_hour],	al
	; modyfikacja!
	mov	byte [variable_cmos_date_get_semaphore],	0x01

.day:
	; dzień
	mov	al,	0x07
	out	VARIABLE_CMOS_PORT_OUT,	al
	in	al,	VARIABLE_CMOS_PORT_IN
	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_day_of_month]
	je	.week	; jeśli brak zmian, kontynuuj

	; zapisz
	mov	byte [variable_cmos_day_of_month],	al
	; modyfikacja!
	mov	byte [variable_cmos_date_get_semaphore],	0x01

.week:
	; tydzien
	mov	al,	0x06
	out	VARIABLE_CMOS_PORT_OUT,	al
	in	al,	VARIABLE_CMOS_PORT_IN
	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_day_of_week]
	je	.month	; jeśli brak zmian, kontynuuj

	; zapisz
	mov	byte [variable_cmos_day_of_week],	al
	; modyfikacja!
	mov	byte [variable_cmos_date_get_semaphore],	0x01

.month:
	; miesiąc
	mov	al,	0x08
	out	VARIABLE_CMOS_PORT_OUT,	al
	in	al,	VARIABLE_CMOS_PORT_IN
	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_month]
	je	.year	; jeśli brak zmian, kontynuuj

	; zapisz
	mov	byte [variable_cmos_month],	al
	; modyfikacja!
	mov	byte [variable_cmos_date_get_semaphore],	0x01

.year:
	; rok
	mov	al,	0x09
	out	VARIABLE_CMOS_PORT_OUT,	al
	in	al,	VARIABLE_CMOS_PORT_IN
	; sprawdź czy wystąpiła modyfikacja
	cmp	al,	byte [variable_cmos_year]
	je	.end	; jeśli brak zmian, kontynuuj

	; zapisz
	mov	byte [variable_cmos_year],	al
	; modyfikacja!
	mov	byte [variable_cmos_date_get_semaphore],	0x01

.end:
	; sprawdź czy czas z CMOS jest stabilny
	cmp	byte [variable_cmos_date_get_semaphore],	0x00
	jne	cyjon_cmos_date_get.loop	; jeśli nie, pobierz czas ponownie

	; konwersja czasu z BCD na Binarny
	bt	word [variable_cmos_register_b],	2
	jc	.noBCD

	; zamień sekundy w format Binarny
	mov	bl,	byte [variable_cmos_second]
	; konwertuj
	call	cyjon_translate_number_BCD_binary
	; zapisz
	mov	byte [variable_cmos_second],	bl

	; zamień minuty w format Binarny
	mov	bl,	byte [variable_cmos_minute]
	; konwertuj
	call	cyjon_translate_number_BCD_binary
	; zapisz
	mov	byte [variable_cmos_minute],	bl

	; sprawdź czy tryb 24 godzinny
	bt	word [variable_cmos_register_b],	1
	jc	.convert	; 24 godzinny, brak modyfikacji

	; sprawdź godzinę AM/PM
	bt	word [variable_cmos_hour],	7
	jnc	.convert	; AM, brak modyfikacji

	; popołudnie, modyfikuj
	add	byte [variable_cmos_hour],	0x10

.convert:
	; zamień godziny w format Binarny
	mov	bl,	byte [variable_cmos_hour]
	; konwertuj
	call	cyjon_translate_number_BCD_binary
	; zapisz
	mov	byte [variable_cmos_hour],	bl

	; zamień dzień w format Binarny
	mov	bl,	byte [variable_cmos_day_of_month]
	; konwertuj
	call	cyjon_translate_number_BCD_binary
	; zapisz
	mov	byte [variable_cmos_day_of_month],	bl

	; zamień miesiąc w format Binarny
	mov	bl,	byte [variable_cmos_month]
	; konwertuj
	call	cyjon_translate_number_BCD_binary
	; zapisz
	mov	byte [variable_cmos_month],	bl

	; zamień rok w format Binarny
	mov	bl,	byte [variable_cmos_year]
	; konwertuj
	call	cyjon_translate_number_BCD_binary
	; zapisz
	mov	byte [variable_cmos_year],	bl

.noBCD:
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

cyjon_translate_number_BCD_binary:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	mov	al,	bl
	; usuń starszą cyfrę
	and	al,	00001111b
	; zapamiętaj młodszą cyfrę
	push	rax

	mov	al,	bl
	; przesuń starszą cyfrę w miejsce młodszej
	shr	al,	4
	; zamień na system dziesiętny
	mov	cl,	10
	; wykonaj
	mul	cl
	; przywróć młodszą cyfrę
	pop	rcx
	; dodaj do starszej
	add	al,	cl
	; zapamiętaj format Binarny
	mov	bl,	al

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	;powrót z procedury
	ret

; flaga prawidłowego pobrania czasu
variable_cmos_date_get_semaphore	db	0x00

; cmos
variable_cmos_hour			dw	0x0000
variable_cmos_minute			db	0x00
variable_cmos_second			db	0x00
variable_cmos_day_of_week		db	0x00
variable_cmos_day_of_month		db	0x00
variable_cmos_month			db	0x00
variable_cmos_year			db	0x00	; 00..99
variable_cmos_register_b		dw	0x0000
