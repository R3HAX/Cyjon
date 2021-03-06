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

struc	ENTRY
	.knot_id			resq	1
	.record_size			resw	1
	.chars				resb	1
	.type				resw	1
	.name				resb	1
endstruc

VARIABLE_ENTRY_TYPE_FILE	equ	0x8000
VARIABLE_ENTRY_TYPE_DIR		equ	0x4000

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
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE

	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_ARGS
	int	STATIC_KERNEL_SERVICE

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
	add	rsp,	VARIABLE_QWORD_SIZE
	pop	rdi

.no_args:
	; wczytaj plik
	mov	ax,	VARIABLE_KERNEL_SERVICE_FILESYSTEM_ROOT_DIR
	int	STATIC_KERNEL_SERVICE

	; przystępujemy do wyświetlenia zawartości

	; ustaw dane przerwania
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING	; al - narzędzia ekranu, ah - procedura - wyświetl ciąg tekstu znajdujący się pod adresem logicznym w rejestrze rsi, zakończony terminatorem (0x00)

	; oblicz koniec "tablicy" katalogu głównego użyszkodnika
	add	rdx,	rdi

	; ustaw wskaźnik poczatku tablicy
	mov	rsi,	rdi

.loop:
	; sprawdź czy koniec rekordów
	cmp	qword [rsi + ENTRY.record_size],	VARIABLE_EMPTY
	je	.end

	; sprawdź czy nazwa pliku rozpoczyna się od "kropki"
	cmp	byte [rsi + ENTRY.name],	"."
	jne	.show_it	; jeśli tak, pomiń wyświetlenie danego pliku

	cmp	byte [variable_semaphore_all],	VARIABLE_EMPTY
	je	.leave

.show_it:
	; pobierz rozmiar nazwy pliku w znakach
	movzx	rcx,	byte [rsi + ENTRY.chars]

	; rozpoznaj atrybut katalogu i dostosuj kolor wyświetlanego tekstu
	cmp	word [rsi + ENTRY.type],	VARIABLE_ENTRY_TYPE_DIR
	je	.catalog

	; załaduj kolor dla zwykłego pliku
	mov	ebx,	VARIABLE_COLOR_DEFAULT

	; skocz do procedury wyświetlenia
	jmp	.print

.catalog:
	; załaduj kolor dla katalogu
	mov	ebx,	VARIABLE_COLOR_LIGHT_BLUE

.print:
	push	rdx
	push	rsi

	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	; przesuń wskaźnik na ciąg znaków przedstawiający nazwe pliku
	add	rsi,	ENTRY.name
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; wyświetl odstęp pomięczy nazwami
	mov	cl,	VARIABLE_FULL	; wyświetl wszystkie znaki z ciągu zakończonego terminatorem
	mov	rsi,	text_separate
	int	STATIC_KERNEL_SERVICE

	pop	rsi
	pop	rdx

.leave:
	; oblicz adres następnego rekordu w tablicy
	movzx	rcx,	word [rsi + ENTRY.record_size]
	; przesuń wskaźnik na następny rekord
	add	rsi,	rcx

	; wyświetl pozostałe pliki zawarte w tablicy
	jmp	.loop

.end:
	; zakończ wyświetlanie zawartości katalogu głównego użyszkodnika nową linią i karetką
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_new_line
	int	STATIC_KERNEL_SERVICE	; wykonaj

	; program kończy działanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE	; wykonaj

%include	'library/find_first_word.asm'
%include	'library/compare_string.asm'

variable_semaphore_all	db	VARIABLE_EMPTY

text_option_all	db	'-a'
text_separate	db	'  ', VARIABLE_ASCII_CODE_TERMINATOR
text_new_line	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

end:
