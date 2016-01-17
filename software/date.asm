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

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; procedura pobierz czas systemu
	mov	ax,	VARIABLE_KERNEL_SERVICE_SYSTEM_DATE
	int	STATIC_KERNEL_SERVICE

	; godzina i data pochodzi z CMOSu, zawsze ustawiam tam czas międzynarodowy GMT
	; zadaniem systemu jest go modyfikować względem strefy czasu w danym państwie

	; format:
	;     _/ dzień tygodnia 1 - niedziela, 7 - sobota
	;     |  _/ dzień miesiąca
	;     |  |  _/ miesiąc 1 - styczeń, 12 - grudzień
	;     |  |  |  _/ rok, ostatnie dwie cyfry
	;     |  |  |  |  _/ godzina
	;     |  |  |  |  |  _/ minuta
	;     |  |  |  |  |  |  _/ sekunda
	;     |  |  |  |  |  |  |  _/ bit 0 - tryb 24 godzinny, jeśli ustawiony
	;     |  |  |  |  |  |  |  |
	; 0x 00 00 00 00 00 00 00 00

	push	rbx

	; pobierz dzień tygodnia ---------------------------------------
	movzx	r8,	byte [rsp + 0x07]

	; licz od zera
	dec	r8

	; oblicz adres rekordu w tablicy nazw tygodnia
	mov	eax,	6
	mul	r8	; oblicz

	; załaduj wskaźnik do wyliczonego tekstu
	mov	rsi,	tablica_dzien_tygodnia
	add	rsi,	rax	; dodaj przesunięcie ("numer" rekordu)

	; wypisz tekst na ekranie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	cl,	VARIABLE_FULL
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE

	; pobierz dzień miesiąca ---------------------------------------
	movzx	r8,	byte [rsp + 0x06]

	; wyświetl liczbę
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	cx,	10	; system dziesiętny
	int	STATIC_KERNEL_SERVICE

	; pobierz miesiąc ----------------------------------------------
	movzx	r8,	byte [rsp + 0x05]

	; licz od zera
	dec	r8

	; oblicz adres rekordu w tablicy miesięcy
	mov	eax,	6
	mul	r8	; oblicz

	; załaduj wskaźnik do wyliczonego tekstu
	mov	rsi,	tablica_miesiac
	add	rsi,	rax	; dodaj przesunięcie ("numer" rekordu)

	; wypisz tekst na ekranie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE

	; pobierz rok --------------------------------------------------
	movzx	r8,	byte [rsp + 0x04]

	; koryguj o tysiąclecie
	add	r8,	2000

	; wyświetl liczbę
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rcx,	10	; system dziesiętny
	int	STATIC_KERNEL_SERVICE

	; wyświetl separator -------------------------------------------

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	tekst_separator
	int	STATIC_KERNEL_SERVICE

	; pobierz godzine ----------------------------------------------
	movzx	r8,	byte [rsp + 0x03]

	; wyświetl liczbę
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rcx,	0x020A	; system dziesiętny
	int	STATIC_KERNEL_SERVICE

	; wyświetl dwukropek -------------------------------------------

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	tekst_dwukropek
	int	STATIC_KERNEL_SERVICE

	; pobierz minute ----------------------------------------------
	movzx	r8,	byte [rsp + 0x02]

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	int	STATIC_KERNEL_SERVICE

	; wyświetl dwukropek -------------------------------------------

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	tekst_dwukropek
	int	STATIC_KERNEL_SERVICE

	; pobierz sekunde ----------------------------------------------
	movzx	r8,	byte [rsp + 0x01]

	; wyświetl liczbę
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	int	STATIC_KERNEL_SERVICE

	; wyświetl informacje o strefie czasowej -----------------------
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	tekst_czas_miedzynarodowy
	int	STATIC_KERNEL_SERVICE

	; procedura zakończenia działania procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

tekst_separator	db	', ', VARIABLE_ASCII_CODE_TERMINATOR
tekst_dwukropek	db	':', VARIABLE_ASCII_CODE_TERMINATOR

tablica_dzien_tygodnia	db	'Sun, ', VARIABLE_ASCII_CODE_TERMINATOR
			db	'Mon, ', VARIABLE_ASCII_CODE_TERMINATOR
			db	'Tue, ', VARIABLE_ASCII_CODE_TERMINATOR
			db	'Wed, ', VARIABLE_ASCII_CODE_TERMINATOR
			db	'Thu, ', VARIABLE_ASCII_CODE_TERMINATOR
			db	'Fri, ', VARIABLE_ASCII_CODE_TERMINATOR
			db	'Sat, ', VARIABLE_ASCII_CODE_TERMINATOR

tablica_miesiac		db	' Jan ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Feb ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Mar ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Apr ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' May ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Jun ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Jul ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Aug ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Sep ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Oct ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Nov ', VARIABLE_ASCII_CODE_TERMINATOR
			db	' Dec ', VARIABLE_ASCII_CODE_TERMINATOR

tekst_czas_miedzynarodowy	db	' UTC', VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
