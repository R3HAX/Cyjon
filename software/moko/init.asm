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

; 64 Bitowy kod programu
[BITS 64]

initialization:
	; tworzenie dokumentu rozpocznij za kodem programu od adresu pełnej strony
	mov	rdi,	stop
	call	library_align_address_up_to_page

	; zapisz adres początku dokumentu
	mov	qword [document_address_start],	rdi
	; zapisz adres końca dokumentu
	mov	qword [document_address_end],	rdi
	add	qword [document_address_end],	0x1000

	; poproś o przestrzeń o rozmiarze 4096 Bajtów pod danym adresem
	mov	rcx,	1	; 1x4096

	; zarezerwuj miejsce (rejestracja w tablicy stronicowania programu)
	mov	ax,	0x0003
	int	0x40	; wykonaj

	; pobierz informacje o ekranie
	mov	rax,	0x0106
	int	0x40

	; zapisz rozmiar ekranu w znakach
	mov	qword [screen_xy],	rbx

.reload:
	; wyświetl interfejs -------------------------------------------

	; wyświetlaj cały ciąg znaków zakończony terminatorem
	xor	rcx,	-1

	; wyczyść ekran
	mov	ax,	0x0100
	int	0x40	; wykonaj

	; nagłówek - nazwa dokumentu aktualnie obrabianego, ew. rozmiar dokumentu w Bajtach/KiB/MiB, numer wiersza/kolumny, status dokumentu [zmodyfikowany]

	; ustaw tło nagłówka
	mov	ax,	0x0102
	mov	rbx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
	mov	r8,	' '	; spacja
	mov	rdx,	VARIABLE_COLOR_DEFAULT
	int	0x40	; wykonaj

	; zresetuj kursor
	mov	ax,	0x0105
	mov	rbx,	0x0000000000000001
	int	0x40	; wykonaj

	; wyświetl informacje w nagłówku
	mov	ax,	0x0101	; wypisz tekst
	mov	rbx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rdx,	VARIABLE_COLOR_DEFAULT

	; sprawdź czy plik posiada nazwę
	cmp	qword [file_name_count],	0x00
	je	.new_file

	mov	rcx,	qword [file_name_count]
	mov	rsi,	file_name_cache
	jmp	.settled

.new_file:
	mov	rcx,	-1
	mov	rsi,	text_header

.settled:
	int	0x40	; wykonaj

	; wyświetl stopke ----------------------------------------------

	; przesuń kursor w miejsce stopki
	mov	ax,	0x0105
	; ostatni wiersz, kolumna 0
	mov	ebx,	dword [screen_xy + 0x04]
	dec	rbx
	shl	rbx,	32
	; wykonaj
	int	0x40

	; wyświetl skrót X =============================================
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_DEFAULT	; czare tło
	mov	rsi,	text_shortcut_exit
	int	0x40	; wykonaj

	; wyświetl opis skrótu
	xchg	rbx,	rdx
	mov	rsi,	text_exit
	int	0x40	; wykonaj
	
;	; wyświetl skrót R =============================================
;	xchg	rbx,	rdx
;	mov	rsi,	text_shortcut_open
;	int	0x40	; wykonaj
;
;	; wyświetl opis skrótu
;	xchg	rbx,	rdx
;	mov	rsi,	text_open
;	int	0x40	; wykonaj
;
;	; wyświetl skrót O =============================================
;	xchg	rbx,	rdx
;	mov	rsi,	text_shortcut_save
;	int	0x40	; wykonaj
;
;	; wyświetl opis skrótu
;	xchg	rbx,	rdx
;	mov	rsi,	text_save
;	int	0x40	; wykonaj
;
;	; wyświetl skrót K =============================================
;	xchg	rbx,	rdx
;	mov	rsi,	text_shortcut_cut
;	int	0x40	; wykonaj
;
;	; wyświetl opis skrótu
;	xchg	rbx,	rdx
;	mov	rsi,	text_cut
;	int	0x40	; wykonaj

	; sprawdź czy ustawić kursor na początek ekranu
	cmp	byte [semaphore_reinit],	0x00
	je	.end	; nie, to jest reinicjalizacja

	; inicjalizuj początkową pozycje kursora na ekranie
	mov	rax,	0x0000000200000000
	mov	qword [cursor_yx],	rax

	; ustaw kursor na początek tworzonego/edytowanego dokumentu
	mov	ax,	0x0105
	mov	rbx,	qword [cursor_yx]
	int	0x40	; wykonaj

	; inicjalizacja zakończona
	mov	byte [semaphore_reinit],	0x00
	
.end:
	; powrót z procedury
	ret

semaphore_reinit	db	0x01

document_address_start	dq	0x0000000000000000
document_address_end	dq	0x0000000000000000

interface_all_height	dq	4	; -1
interface_height	dq	3	; -1
interface_menu_height	dq	1	
screen_xy		dq	0x0000000000000000

text_header	db	'New file', 0x00

;text_shortcut_open	db	'^r', 0x00
;text_open	db	' Open  ', 0x00
;text_shortcut_save	db	'^o', 0x00
;text_save	db	' Save  ', 0x00
text_shortcut_exit	db	'^x', 0x00
text_exit	db	' Exit  ', 0x00
;text_shortcut_cut	db	'^k',	0x00
;text_cut	db	' Cut  ', 0x00
;text_shortcut_paste	db	'^u', 0x00
;text_paste	db	' UnCut  ', 0x00
