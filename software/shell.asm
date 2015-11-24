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

; zestaw imiennych wartości stałych
%include	"config.asm"

%define	VARIABLE_SHELL_VERSION	"w0.47"

; adresacja względna
[DEFAULT REL]

; 64 bitowy kod programu
[BITS 64]

; adres logiczny kodu programu
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

prestart:
	; wyświetl wstępną informacje przy pierwszym uruchomieniu programu
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_help
	int	0x40	; wykonaj
	
start:
	; wyświetl znak zachęty
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_prompt
	int	0x40	; wykonaj

.loop:
	; pobierz od użytkownika polecenie
	mov	rbx,	VARIABLE_COLOR_DEFAULT	; kolor domyślny
	mov	rcx,	256	; maksymalny rozmiar polecenia do pobrania
	mov	rdi,	command_cache	; gdzie przechować wprowadzony ciąg znaków
	xor	r8,	r8	; bufor nie zawiera danych
	call	library_input	; wykonaj

	; czy użytkownik wpisał cokolwiek?
	jc	.text

.restart:
	; wyświetl znak zachęty od nowej linii
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_prompt_with_newline
	int	0x40	; wykonaj

	; kontynuuj
	jmp	.loop

.text:
	; zachowaj ilość znaków w buforze
	mov	qword [command_cache_size],	rcx

	; przejdź do nowej linii
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rsi,	text_newline
	int	0x40	; wykonaj

	; przywróć ilość znaków w buforze
	mov	rcx,	qword [command_cache_size]

	; znajdź pierwsze słowo (polecenie) do wykonania/uruchomienia
	call	library_find_first_word

	; bufor zawiera słowo?
	jnc	start	; jeśli nie, wyświetl znak zachęty od nowej linii

	; sprawdź czy polecenie wewnętrzne 'clear' ---------------------
	mov	rsi,	command_clear
	xchg	cl,	byte [command_clear_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_clear_count]

	; nie znaleziono?
	jnc	.noClear

	; wyczyść ekran
	mov	ax,	0x0100	; procedura czyści ekran
	int	0x40	; wykonaj

	; restart powłoki
	jmp	start

.noClear:
	; sprawdź czy próba wywołania Incepcji :D ----------------------
	mov	rsi,	command_shell
	xchg	cl,	byte [command_shell_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_shell_count]

	; nie znaleziono?
	jnc	.noShell

	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_inception
	int	0x40	; wykonaj

	; restart powłoki
	jmp	start

.noShell:
	; sprawdź czy próba wywołania zablokowanego programu -----------
	mov	rsi,	command_init
	xchg	cl,	byte [command_init_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_init_count]

	; nie znaleziono?
	jnc	.noInit

	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_blocked
	int	0x40	; wykonaj

	; restart powłoki
	jmp	start

.noInit:
	; sprawdź czy próba wywołania zablokowanego programu -----------
	mov	rsi,	command_login
	xchg	cl,	byte [command_login_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_login_count]

	; nie znaleziono?
	jnc	.noLogin

	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_login
	int	0x40	; wykonaj

	; restart powłoki
	jmp	start

.noLogin:
	; sprawdź czy polecenie wewnętrzne 'exit' ----------------------
	mov	rsi,	command_exit
	xchg	cl,	byte [command_exit_count]
	call	library_compare_string	; sprawdź
	xchg	cl,	byte [command_exit_count]

	; jeśli nie, kontynuuj
	jnc	.noExit

	; wyloguj z powłoki systemu
	xor	rax,	rax
	int	0x40	; wykonaj

.noExit:
	; uruchom program o podanej nazwie
	mov	ax,	0x0001
	mov	rsi,	rdi	; załaduj wskaźnik nazwy pliku
	; przekaż listę argumentów do uruchamianego procesu
	mov	rdi,	command_cache
	mov	rdx,	qword [command_cache_size]
	int	0x40	; wykonaj

	; sprawdź czy uruchomiono nowy proces
	cmp	rcx,	VARIABLE_EMPTY
	ja	.process

	; wyświetl informację o braku danego programu na partycji systemowej
	mov	ax,	0x0101	; procedura wyświetlająca ciąg znaków zakończony TERMINATOREM lub sprecyzowaną ilością
	mov	rcx,	-1	; wyświetl wszystkie znaki z ciągu
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_ups
	int	0x40	; wykonaj

	; pobierz następne polecenie od użytkownika
	jmp	start

.process:
	; sprawdź czy proces istnieje
	mov	ax,	0x0002	; procedura przeszukuje tablice procesów za podanym identyfikatorem w rejestrze RCX

.wait:
	; sprawdź
	int	0x40	; wykonaj

	; sprawdź czy proces zakończył pracę
	cmp	rcx,	VARIABLE_EMPTY
	ja	.wait

	; rozpocznij od nowa pracę powłoki
	jmp	start

%include	'library/input.asm'
%include	'library/find_first_word.asm'
%include	'library/compare_string.asm'

command_cache	times	256	db	0x00
				db	VARIABLE_ASCII_CODE_TERMINATOR
command_cache_size		dq	VARIABLE_EMPTY

text_help			db	"Type 'help' for more info.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_prompt_with_newline	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE
text_prompt			db	"localhost / $ ", VARIABLE_ASCII_CODE_TERMINATOR
text_newline			db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_ups			db	"Command not found.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_inception			db	'Inception, good movie.', VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_blocked			db	"No, you can't.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_login			db	"Online.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

command_clear			db	'clear'
command_clear_count		db	5
command_shell			db	'shell'
command_shell_count		db	5
command_init			db	'init'
command_init_count		db	4
command_login			db	'login'
command_login_count		db	5
command_exit			db	'exit'
command_exit_count		db	4
