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
[ORG REAL_HIGH_MEMORY_ADDRESS]

start:
	; ustaw wskaźnik na tablice
	mov	rsi,	command_table + 0x08	; pomiń pierwszą wartość

	; pobierz rozmiar komórki 'polecenie'
	mov	r8,	qword [rsi - 0x08]

	; procedura - wyświetl ciąg znaków na ekranie w miejscu kursora
	mov	ax,	0x0101

	; domyślny kolor tła
	mov	rdx,	BACKGROUND_COLOR_DEFAULT

.loop:
	; sprawdź czy koniec tablicy?
	cmp	qword [rsi],	VARIABLE_EMPTY
	je	.end	; tak

	; wyświetl polecenie
	mov	ebx,	COLOR_WHITE
	mov	rcx,	r8	; rozmiar ciągu znaków
	int	0x40	; wykonaj

	; zachowaj wskaźnik
	push	rsi

	; przesuń wskaźnik na opis polecenia
	mov	rsi,	qword [rsi + r8]

	; wyświetl opis polecenia
	mov	ebx,	COLOR_DEFAULT
	mov	rcx,	-1	; wyświetl cały ciąg
	int	0x40	; wykonaj

	; przywróć wskaźnik
	pop	rsi

	; przesuń wskaźnik na następny rekord
	add	rsi,	r8	; rozmiar komórki 'polecenie'
	add	rsi,	0x08	; rozmiar wskaźnika do ciągu opisu

	; kontynuuj
	jmp	.loop

.end:
	; wyjdź z programu
	xor	ax,	ax
	int	0x40	; wykonaj

command_table:
	dq	7	; rozmiar komórki 'polecenie'

	db	'clear  '
	dq	text_clear

;	db	'date   '
;	dq	text_date

	db	'exit   '
	dq	text_exit

	db	'help   '
	dq	text_help

;	db	'ls     '
;	dq	text_ls

;	db	'moko   '
;	dq	text_moko

	db	'uptime '
	dq	text_uptime

	; koniec tablicy
	dq	0x0000000000000000

text_clear	db	"- clean console screen,", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_date	db	"- display the current time,", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_exit	db	"- logout,", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_help	db	"- yes, it's me,", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_ls		db	"- show files owned by user,", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_moko	db	"- system text editor,", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_uptime	db	"- tells how long the system has been running.", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
