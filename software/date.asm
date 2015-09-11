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
	; procedura pobierz czas systemu
	mov	ax,	0x0301
	int	0x40	; wykonaj

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

	; wyczyść licznik
	xor	rcx,	rcx

	push	rbx

	; pobierz dzień tygodnia ---------------------------------------
	movzx	r8,	byte [rsp + 0x07]

	; licz od zera
	dec	r8

	; oblicz numer rekordu w tablicy nazw tygodnia
	mov	rax,	6
	mul	r8	; oblicz

	; załaduj wskaźnik do wyliczonego tekstu
	mov	rsi,	tablica_dzien_tygodnia
	add	rsi,	rax	; dodaj przesunięcie ("numer" rekordu)

	; wypisz tekst na ekranie
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40	; wykonaj

	; pobierz dzień miesiąca ---------------------------------------
	movzx	r8,	byte [rsp + 0x06]

	; wyświetl liczbę
	mov	ax,	0x0103
	mov	rcx,	10
	int	0x40	; wykonaj

	; pobierz miesiąc ----------------------------------------------
	movzx	r8,	byte [rsp + 0x05]

	; licz od zera
	dec	r8

	; oblicz numer rekordu w tablicy miesięcy
	mov	rax,	6
	mul	r8	; oblicz

	; załaduj wskaźnik do wyliczonego tekstu
	mov	rsi,	tablica_miesiac
	add	rsi,	rax	; dodaj przesunięcie ("numer" rekordu)

	; wypisz tekst na ekranie
	mov	ax,	0x0101
	mov	rcx,	-1	; wyświetl cały tekst
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	0x40	; wykonaj

	; pobierz rok --------------------------------------------------
	movzx	r8,	byte [rsp + 0x04]

	; koryguj o tysiąclecie
	add	r8,	2000

	; wyświetl liczbę
	mov	ax,	0x0103
	mov	rcx,	10
	int	0x40	; wykonaj

	; wyświetl separator -------------------------------------------

	; wyświetl separator bez cyfry wiodącej
	mov	rcx,	2

	; sprawdź, czy wyświetlić cyfrę wiodącą?
	cmp	byte [rsp + 0x03],	9
	ja	.godzina	; godzina powyżej

	; koryguj, wyświetl separator z cyfrą wiodącą
	inc	rcx

.godzina:
	; wyświetl tekst
	mov	ax,	0x0101
	mov	rsi,	tekst_separator
	int	0x40	; wykonaj

	; pobierz godzine ----------------------------------------------
	movzx	r8,	byte [rsp + 0x03]

	; wyświetl liczbę
	mov	ax,	0x0103
	mov	rcx,	10
	int	0x40	; wykonaj

	; wyświetl dwukropek -------------------------------------------

	; wyświetl dwukropek bez cyfry wiodącej
	mov	rcx,	1

	; sprawdź, czy wyświetlić cyfrę wiodącą?
	cmp	byte [rsp + 0x02],	9
	ja	.minuta	; minuta powyżej

	; koryguj, wyświetl dwukropek z cyfrą wiodącą
	inc	rcx

.minuta:
	; wyświetl tekst
	mov	ax,	0x0101
	mov	rsi,	tekst_dwukropek
	int	0x40	; wykonaj

	; pobierz minute ----------------------------------------------
	movzx	r8,	byte [rsp + 0x02]

	; wyświetl liczbę
	mov	ax,	0x0103
	mov	rcx,	10
	int	0x40	; wykonaj

	; wyświetl dwukropek -------------------------------------------

	; wyświetl dwukropek bez cyfry wiodącej
	mov	rcx,	1

	; sprawdź, czy wyświetlić cyfrę wiodącą?
	cmp	byte [rsp + 0x01],	9
	ja	.sekunda	; sekunda powyżej

	; koryguj, wyświetl dwukropek z cyfrą wiodącą
	inc	rcx

.sekunda:
	; wyświetl tekst
	mov	ax,	0x0101
	mov	rsi,	tekst_dwukropek
	int	0x40	; wykonaj

	; pobierz sekunde ----------------------------------------------
	movzx	r8,	byte [rsp + 0x01]

	; wyświetl liczbę
	mov	ax,	0x0103
	mov	rcx,	10
	int	0x40	; wykonaj

	; wyświetl informacje o strefie czasowej -----------------------
	mov	ax,	0x0101
	mov	rcx,	-1
	mov	rsi,	tekst_czas_miedzynarodowy
	int	0x40	; wykonaj

	; procedura zakończenia działania procesu
	xor	ax,	ax
	int	0x40	; wykonaj

tekst_separator	db	', 0'
tekst_dwukropek	db	':0'

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
