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
	mov	rdi,	end
	and	di,	0xF000
	add	rdi,	0x1000

	mov	ax,	0x0005
	int	0x40

	cmp	rcx,	VARIABLE_EMPTY
	je	.no_args

	push	rdi

	push	rcx
	; pomiń pierwsze słowo "nazwa uruchomionego procesu"
	call	library_find_first_word

	sub	qword [rsp],	rcx
	add	rdi,	rcx
	mov	rcx,	qword [rsp]
	call	library_find_first_word

	mov	rsi,	text_option_all
	call	library_compare_string
	jnc	.no_option

	mov	byte [variable_semaphore_all],	VARIABLE_INCREMENT

.no_option:
	add	rsp,	0x08
	pop	rdi

.no_args:
	; pobierz rozmiar w Bajtach
	mov	ax,	0x0401
	mov	rbx,	0	; katalog główny
	int	0x40	; wykonaj

	; oblicz rozmiar wymaganego miejsca
	mov	rax,	rcx
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE
	div	rcx
	cmp	rdx,	VARIABLE_EMPTY
	je	.ok

	add	rax,	VARIABLE_INCREMENT

.ok:
	mov	rcx,	rax
	; zarezerwuj miejsce
	mov	ax,	0x0003
	int	0x40	; wykonaj

	; wczytaj plik
	mov	rax,	0x0400
	xor	rcx,	rcx	; katalog główny
	int	0x40

	; przystępujemy do wyświetlenia zawartości

	; ustaw dane przerwania
	mov	ax,	0x0101	; al - narzędzia ekranu, ah - procedura - wyświetl ciąg tekstu znajdujący się pod adresem logicznym w rejestrze rsi, zakończony terminatorem (0x00)

	; oblicz koniec "tablicy" katalogu głównego użyszkodnika
	add	rdx,	rdi

	; ustaw wskaźnik poczatku tablicy
	mov	rsi,	rdi

.loop:
	; sprawdź czy skończyła się tablica
	cmp	rsi,	rdx
	je	.end	; jeśli równe, koniec

	; sprawdź czy koniec rekordów
	cmp	qword [rsi + 0x08],	VARIABLE_EMPTY
	je	.end

	; sprawdź czy nazwa pliku rozpoczyna się od "kropki"
	cmp	byte [rsi + 0x0C],	"."
	jne	.show_it	; jeśli tak, pomiń wyświetlenie danego pliku

	cmp	byte [variable_semaphore_all],	VARIABLE_EMPTY
	je	.leave

.show_it:
	; pobierz rozmiar nazwy pliku w znakach
	movzx	rcx,	byte [rsi + 0x0A]

	; rozpoznaj atrybut katalogu i dostosuj kolor wyświetlanego tekstu
	cmp	byte [rsi + 0x0B],	0x02
	je	.catalog

	; załaduj kolor dla zwykłego pliku
	mov	ebx,	VARIABLE_COLOR_DEFAULT

	; skocz do procedury wyświetlenia
	jmp	.print

.catalog:
	; załaduj kolor dla katalogu
	mov	ebx,	VARIABLE_COLOR_BLUE

.print:
	push	rdx
	push	rsi

	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	; przesuń wskaźnik na ciąg znaków przedstawiający nazwe pliku
	add	rsi,	0x0C
	int	0x40	; wykonaj

	; wyświetl odstęp pomięczy nazwami
	mov	cl,	-1	; wyświetl wszystkie znaki z ciągu zakończonego terminatorem
	mov	rsi,	text_separate
	int	0x40	; wykonaj

	pop	rsi
	pop	rdx

.leave:
	; oblicz adres następnego rekordu w tablicy
	movzx	rcx,	word [rsi + 0x08]
	; przesuń wskaźnik na następny rekord
	add	rsi,	rcx

	; wyświetl pozostałe pliki zawarte w tablicy
	jmp	.loop

.end:
	; zakończ wyświetlanie zawartości katalogu głównego użyszkodnika nową linią i karetką
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_new_line
	int	0x40	; wykonaj

	; program kończy działanie
	xor	ax,	ax
	int	0x40	; wykonaj

%include	'library/find_first_word.asm'
%include	'library/compare_string.asm'

variable_semaphore_all	db	0x00

text_option_all	db	'-a'
text_separate	db	'  ', VARIABLE_ASCII_CODE_TERMINATOR
text_new_line	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

end:
