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
	; wyświetl zaproszenie

	; procedura - wyświetl ciąg znaków na ekranie w miejscu kursora
	mov	rax,	0x0101
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	BACKGROUND_COLOR_DEFAULT


	;kolor znaków
	mov	rbx,	COLOR_BLUE
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_welcome
	int	0x40	; wykonaj

	;kolor znaków
	mov	rbx,	COLOR_DEFAULT
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_separator
	int	0x40	; wykonaj

	;kolor znaków
	mov	rbx,	COLOR_GRAY
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_version
	int	0x40	; wykonaj

	; pozostała część w trakcie przepisywania

	; zatrzymaj dalsze wykonywanie kodu programu
	jmp	$

text_welcome	db	ASCII_CODE_ENTER, ASCII_CODE_NEWLINE
		db	"     C y j o n   O S  ", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_separator	db	"   -------------------", ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_version	db	"                v", KERNEL_VERSION, ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
