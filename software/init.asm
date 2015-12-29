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

%define	VARIABLE_PROGRAM_VERSION	"v0.2"

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	ecx,	VARIABLE_FULL
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_init
	int	STATIC_KERNEL_SERVICE

	; pierwszą inicjalizacje nie rozpoczynaj od czyszczenia ekranu
	jmp	.start

.reload:
	; wyczyść ekran
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CLEAN	; procedura czyszcząca ekran
	xor	rbx,	rbx	; od początku ekranu
	xor	rcx,	rcx	; cały ekran
	int	STATIC_KERNEL_SERVICE

.start:
	; wyświetl zaproszenie

	; procedura - wyświetl ciąg znaków na ekranie w miejscu kursora
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ecx,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	;kolor znaków
	mov	ebx,	VARIABLE_COLOR_LIGHT_BLUE
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_welcome
	int	STATIC_KERNEL_SERVICE

	;kolor znaków
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_separator
	int	STATIC_KERNEL_SERVICE

	;kolor znaków
	mov	ebx,	VARIABLE_COLOR_LIGHT_GRAY
	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	mov	rsi,	text_version
	int	STATIC_KERNEL_SERVICE

	;=======================================================================
	; uruchom proces logowania do konsoli
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_NEW
	mov	ecx,	dword [file_login_name_length]	; ilość znaków w nazwie pliku
	xor	rdx,	rdx	; brak argumentów
	mov	rsi,	file_login	; wskaźnik do nazwy pliku
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy proces zakończył pracę
	call	check

	;=======================================================================
	; uruchom powłokę systemu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_NEW
	mov	ecx,	dword [file_shell_name_length]	; ilość znaków w nazwie pliku
	xor	rdx,	rdx	; brak argumentów
	mov	rsi,	file_shell
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy proces zakończył pracę
	call	check

	; inicjalizuj ponownie powłokę
	jmp	.reload

; rcx - numer PID procesu do sprawdzenia
check:
	; zachowaj oryginalne rejestry
	push	rax

	; pobierz informację o procesie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_CHECK
	; rcx - numer PID procesu	

.wait:
	int	STATIC_KERNEL_SERVICE

	; sprawdź czy proces zakończył pracę / poprawne zalogowanie się do systemu
	cmp	rcx,	VARIABLE_EMPTY
	ja	.wait	; jeśli nie, czekaj dalej

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

text_init	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
		db	"INIT: ", VARIABLE_PROGRAM_VERSION, " ready.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_welcome	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
		db	"     W a t a h a . n e t", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_separator	db	"   -----------------------", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_version	db	"              Cyjon v", VARIABLE_KERNEL_VERSION, VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

file_login		db	'login'
file_login_name_length	dq	5
file_shell		db	'shell'
file_shell_name_length	dq	5
