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
	; pierwszą inicjalizacje nie rozpoczynaj od czyszczenia ekranu
	jmp	.start

.reload:
	; wyczyść ekran
	mov	rax,	0x0100
	int	0x40	; wykonaj

.start:
	; wyświetl zaproszenie

	; procedura - wyświetl ciąg znaków na ekranie w miejscu kursora
	mov	rax,	0x0101
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	;kolor znaków
	mov	rbx,	VARIABLE_COLOR_BLUE_LIGHT
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_welcome
	int	0x40	; wykonaj

	;kolor znaków
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_separator
	int	0x40	; wykonaj

	;kolor znaków
	mov	rbx,	VARIABLE_COLOR_GRAY
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_version
	int	0x40	; wykonaj

	;=======================================================================
	; uruchom proces logowania do konsoli
	mov	rax,	0x0001
	mov	rcx,	qword [file_login_name_length]	; ilość znaków w nazwie pliku
	mov	rsi,	file_login	; wskaźnik do nazwy pliku
	int	0x40	; wykonaj

	; sprawdź czy proces zakończył pracę
	call	check

	;=======================================================================
	; uruchom powłokę systemu
	mov	rax,	0x0001
	mov	rcx,	qword [file_shell_name_length]	; ilość znaków w nazwie pliku
	mov	rsi,	file_shell
	int	0x40	; wykonaj

	; sprawdź czy proces zakończył pracę
	call	check

	; inicjalizuj ponownie powłokę
	jmp	.reload

; rcx - numer PID procesu do sprawdzenia
check:
	; zachowaj oryginalne rejestry
	push	rax

	; pobierz informację o procesie
	mov	rax,	0x0002	; sprawdź czy proces o numerze PID jest uruchomiony
	; rcx - numer PID procesu	

.wait:
	int	0x40	; wykonaj

	; sprawdź czy proces zakończył pracę / poprawne zalogowanie się do systemu
	cmp	rcx,	VARIABLE_EMPTY
	ja	.wait	; jeśli nie, czekaj dalej

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

text_welcome	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
		db	"     C y j o n   O S  ", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_separator	db	"   -------------------", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_version	db	"                v", VARIABLE_KERNEL_VERSION, VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

file_login		db	'login'
file_login_name_length	dq	5
file_shell		db	'shell'
file_shell_name_length	dq	5
