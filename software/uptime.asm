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

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; procedura - pobierz uptime systemu
	mov	ax,	0x0300
	int	0x40	; wykonaj

	; domyślny kolor czcionki i tła
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	; zapamiętaj
	push	rcx

	; wyświetl wstęp
	mov	ax,	0x0101
	mov	rcx,	-1
	mov	rsi,	text_up
	int	0x40	; wykonaj

	; przywróć
	pop	rax

	; oblicz ilość dni
	mov	rcx,	60 * 60 * 24	; sekund * minut * godzin
	xor	rdx,	rdx	; wyczyść resztę / starszą część
	div	rcx	; wykonaj

	; zapamiętaj resztę z dzielenia
	push	rdx

	; sprawdź czy wyświetlić
	cmp	rax,	0
	je	.less_than_a_day

	; ustaw licznik
	mov	r8,	rax

	; wyświetl liczbę
	mov	ax,	0x0103
	mov	rcx,	10	; system dziesiętny
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40	; wykonaj

	; sprawdź pisownię dzień/dni
	cmp	r8,	1
	ja	.few_days

	; wyświetl jeden dzień
	mov	ax,	0x0101
	mov	rsi,	text_day
	int	0x40	; wykonaj

	; kontynuuj
	jmp	.less_than_a_day

.few_days:
	; wyświetl ' days, '
	mov	ax,	0x0101
	mov	rsi,	text_days
	int	0x40	; wykonaj

.less_than_a_day:
	; załaduj resztę z dzielenia
	pop	rax

	; przelicz na godziny
	mov	rcx,	60 * 60	; sekund * minut
	xor	rdx,	rdx	; wyczyść starszą część / resztę
	div	rcx	; wykonaj

	; zapamiętaj resztę z dzielenia
	push	rdx

	; sprawdź czy wyświetlić godzinę
	cmp	rax,	0
	je	.less_than_a_hour	; nie

	; wyświetl godzinę
	mov	r8,	rax
	mov	ax,	0x0103
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rcx,	10	; system dziesiętny
	int	0x40

	; wyświetlono godzinę
	mov	byte [variable_semaphore],	0x01

.less_than_a_hour:
	; załaduj resztę z dzielenia
	pop	rax

	; przelicz na minuty
	mov	rcx,	60	; sekund
	xor	rdx,	rdx	; wyczyść starszą część / resztę
	div	rcx	; wykonaj

	; zapamiętaj wynik
	push	rax

	; wyświetl dwukropek -------------------------------------------

	; wyświetl dwukropek bez cyfry wiodącej
	mov	rcx,	1

	; sprawdź, czy wyświetlić cyfrę wiodącą?
	cmp	al,	9
	ja	.caution	; minuta powyżej

	; koryguj, wyświetl dwukropek z cyfrą wiodącą
	inc	rcx

.caution:
	cmp	byte [variable_semaphore],	VARIABLE_EMPTY
	je	.no_hour

	; wyświetl tekst
	mov	ax,	0x0101
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	int	0x40	; wykonaj

.no_hour:
	; ustaw licznik
	pop	r8

	; wyświetl liczbę
	mov	ax,	0x0103
	mov	rcx,	10	; system dziesiętny
	int	0x40	; wykonaj

	; była wyświetlana godzina?
	cmp	byte [variable_semaphore],	0x01
	je	.end

	; wyświetl ' min'
	mov	ax,	0x0101
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_min
	int	0x40	; wykonaj

.end:
	; zakończ wyświetlanie informacji o pamięci ram - nową linią i karetką
	mov	ax,	0x0101
	mov	rsi,	text_end
	int	0x40	; wykonaj

	; program kończy działanie
	xor	ax,	ax
	int	0x40	; wykonaj

variable_semaphore	db	VARIABLE_EMPTY

text_up			db	'up ', VARIABLE_ASCII_CODE_TERMINATOR

text_caution		db	':0' ;)
text_day		db	' day, ', VARIABLE_ASCII_CODE_TERMINATOR
text_days		db	' days, ', VARIABLE_ASCII_CODE_TERMINATOR
text_min		db	' min', VARIABLE_ASCII_CODE_TERMINATOR
text_end		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
