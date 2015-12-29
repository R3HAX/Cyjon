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

; kolory, stałe
%include	'config.asm'

VARIABLE_MINUTE_SECONDS	equ	60
VARIABLE_HOUR_SECONDS	equ	VARIABLE_MINUTE_SECONDS * 60
VARIABLE_DAY_SECONDS	equ	VARIABLE_HOUR_SECONDS * 24

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; procedura - pobierz uptime systemu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SYSTEM_UPTIME
	int	STATIC_KERNEL_SERVICE

	; domyślny kolor czcionki i tła
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	; zapamiętaj
	push	rcx

	; wyświetl wstęp
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rcx,	VARIABLE_FULL
	mov	rsi,	text_up
	int	STATIC_KERNEL_SERVICE

	; przywróć
	pop	rax

	; oblicz ilość dni
	mov	rcx,	VARIABLE_DAY_SECONDS
	xor	rdx,	rdx	; wyczyść resztę / starszą część
	div	rcx

	; zapamiętaj resztę z dzielenia
	push	rdx

	; sprawdź czy wyświetlić
	cmp	rax,	VARIABLE_EMPTY
	je	.less_than_a_day

	; ustaw licznik
	mov	r8,	rax

	; wyświetl liczbę
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rcx,	10	; system dziesiętny
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE

	; sprawdź pisownię dzień/dni
	cmp	r8,	1
	ja	.few_days

	; wyświetl jeden dzień
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	text_day
	int	STATIC_KERNEL_SERVICE

	; kontynuuj
	jmp	.less_than_a_day

.few_days:
	; wyświetl ' days, '
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	text_days
	int	STATIC_KERNEL_SERVICE

.less_than_a_day:
	; załaduj resztę z dzielenia
	pop	rax

	; przelicz na godziny
	mov	rcx,	VARIABLE_HOUR_SECONDS	; sekund * minut
	xor	rdx,	rdx	; wyczyść starszą część / resztę
	div	rcx

	; zapamiętaj resztę z dzielenia
	push	rdx

	; sprawdź czy wyświetlić godzinę
	cmp	rax,	VARIABLE_EMPTY
	je	.less_than_a_hour	; nie

	; wyświetl godzinę
	mov	r8,	rax
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rcx,	10	; system dziesiętny
	int	STATIC_KERNEL_SERVICE

	; wyświetlono godzinę
	mov	byte [variable_semaphore],	VARIABLE_TRUE

.less_than_a_hour:
	; załaduj resztę z dzielenia
	pop	rax

	; przelicz na minuty
	mov	rcx,	VARIABLE_MINUTE_SECONDS	; sekund
	xor	rdx,	rdx	; wyczyść starszą część / resztę
	div	rcx

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
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	int	STATIC_KERNEL_SERVICE

.no_hour:
	; ustaw licznik
	pop	r8

	; wyświetl liczbę
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rcx,	10	; system dziesiętny
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE

	; była wyświetlana godzina?
	cmp	byte [variable_semaphore],	VARIABLE_TRUE
	je	.end

	; wyświetl ' min'
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_min
	int	STATIC_KERNEL_SERVICE

.end:
	; zakończ wyświetlanie informacji o pamięci ram - nową linią i karetką
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	text_end
	int	STATIC_KERNEL_SERVICE

	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

variable_semaphore	db	VARIABLE_EMPTY

text_up			db	'up ', VARIABLE_ASCII_CODE_TERMINATOR

text_caution		db	':0' ;)
text_day		db	' day, ', VARIABLE_ASCII_CODE_TERMINATOR
text_days		db	' days, ', VARIABLE_ASCII_CODE_TERMINATOR
text_min		db	' min', VARIABLE_ASCII_CODE_TERMINATOR
text_end		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
