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
	; wyświetl nawe jednostki i prośbę o nazwe konta
	mov	rax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL	; wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_login	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	int	STATIC_KERNEL_SERVICE

	; pobierz od użytkownika ciąg znaków
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	rcx,	16	; ilość pobieranych znaków
	mov	rdi,	text_login_cache	; gdzie przechować pobrane znaki
	call	library_input

	; wyświetl prośbę o podanie hasła
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL	; wszystkie znaki z ciągu
	mov	rsi,	text_password	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	int	STATIC_KERNEL_SERVICE

	; pobierz od użytkownika ciąg znaków
	mov	rbx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rcx,	16	; ilość pobieranych znaków
	mov	rdi,	text_password_cache	; gdzie przechować pobrane znaki
	call	library_input

	; przesuń kursor na początek linii
	mov	rcx,	VARIABLE_FULL	; wszystkie znaki z ciągu
	mov	rsi,	text_space	; wskaźnik do ciągu znaków zakończony terminatorem lub licznikiem
	int	STATIC_KERNEL_SERVICE

	; zakończ działanie procesu/programu
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

%include	'library/input.asm'
%include	'library/compare_string.asm'

variable_passwd_tmp		db	'toor'
variable_passwd_tmp_count	db	4

text_login				db	'localhost login: ', VARIABLE_ASCII_CODE_TERMINATOR
text_login_cache	times	16	db	VARIABLE_EMPTY
text_password				db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, 'Password: ', VARIABLE_ASCII_CODE_TERMINATOR
text_password_cache	times	16	db	VARIABLE_EMPTY
text_space				db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
