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

; 64 bitowy kod programu
[BITS 64]

struc virtual_file_system_superblock
	.s_all_blocks_count		resq	1
	.s_fs_blocks_count		resq	1

	.s_knots_table			resq	1
	.s_knots_table_size		resq	1
endstruc

variable_partition_specification_system	times	4	dq	VARIABLE_EMPTY

virtual_file_systems:
	; zachowaj oryginalne rejestry
	push	r8

	; inicjalizuj wirtualny system plików dla systemu
	mov	r8,	variable_partition_specification_system
	call	virtual_file_system_initialization

	; inicjalizuj wirtualny system plików dla użytkownika
	mov	r8,	variable_partition_specification_home
	call	virtual_file_system_initialization

	; przywróć oryginalne rejestry
	pop	r8

	; powrót z procedury
	ret

;===============================================================================
; procedura zapisuje plik do wirtualnego systemu plików
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rdx - rozmiar pliku w Bajtach
;	rdi - wskaźnik przechowywania pliku w pamięci
;	rsi - wskaźnik do nazwy pliku
;	r8 - specyfikacja systemu plików
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_virtual_file_system_save_file:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; sprawdź czy istnieje plik o podanej nazwie w katalogu głównym
	call	cyjon_virtual_file_system_find_file
	jnc	.no	; brak pliku, utwórz nowy wpis do katalogu głównego

	; aktualizuj nowy rozmiar pliku w rekordzie tablicy knotów
	mov	qword [rdi + 0x08],	rdx

	; kontynuuj zapis pliku
	jmp	.continue

.no:
	; szukaj wolnego rekordu w katalogu głównym
	call	cyjon_virtual_file_system_find_free_knot

	; zapisz rozmiar pliku w Bajtach
	mov	qword [rdi + 0x08],	rdx

	; zapisz ilość znaków przypadających na nazwę pliku
	mov	qword [rdi + 0x10],	rcx

	; zapamiętaj adres wskaźnika
	push	rdi

	; przesuń wskaźnik na nazwe pliku w rekordzie
	add	rdi,	0x18

	; zapisz do rekordu nazwe pliku
	rep	movsb

	; przywróć adres wskaźnika
	pop	rax

	; pobierz adres pierwszego wolnego bloku/strony
	call	cyjon_page_allocate

	; ustaw na swoje miejsca
	xchg	rdi,	rax

	; zapisz do rekordu pierwszy blok danych zawartości pliku
	mov	qword [rdi],	rax

.continue:
	; załaduj adres przechowywanego pliku w pamięci
	mov	rsi,	qword [rsp]

	; załaduj numer pierwszego bloku danych pliku
	mov	rdi,	qword [rdi]

.save:
	; zachowaj adres przeznaczenia pliku
	push	rdi

	; sprawdź czy cały/pozostała część pliku mieści się w jednym bloku
	cmp	rdx,	4096 - 0x08
	jbe	.last_block

	; skopiuj część pliku do bloku danych
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE - 0x08
	; oblicz pozostałą część pliku do skopiowania
	sub	rdx,	rcx
	; koryguj o rozmiar
	shr	rcx,	3	; /8
	; kopiuj
	rep	movsq

	; sprawdź czy jest opisany następny blok do uzupełniania danymi pliku
	cmp	qword [rdi],	VARIABLE_EMPTY
	ja	.store

	; zachowaj adres bloku modyfikowanego
	push	rdi
	mov	rax,	rdi

	; zaalokuj następny blok pod dane pliku
	call	cyjon_page_allocate

	; ustaw na swoje miejsca
	xchg	rdi,	rax

	; załaduj informacje do aktualnego bloku
	stosq

	; przyrwóć adres aktualnie modyfikowanego bloku
	pop	rdi

.store:
	; przywróć adres przeznaczenia pliku
	pop	rdi

	; załaduj numer następnego bloku do modyfikacji
	mov	rdi,	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - 0x08]

	; sprawdź czy koniec danych pliku
	cmp	rdx,	VARIABLE_EMPTY
	je	.end

	; kontynuuj z pozostałymi blokami
	jmp	.save

.last_block:
	; skopiuj pozostałą część pliku
	mov	rcx,	rdx
	; kopiuj
.copy:
	mov	al,	byte [rsi]
	mov	byte [rdi],	al
	add	rsi,	VARIABLE_INCREMENT
	add	rdi,	VARIABLE_INCREMENT
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.copy

	; uzupełnij o pustą przestrzeń
	xor	rax,	rax
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE
	sub	rcx,	rdx
	; wyczyść
	rep	stosb

	; koniec zawartości pliku
	xor	rdx,	rdx

	; kontynuuj zapis
	jmp	.store

.end:
	; sprawdzić czy pozostały jakieś bloku do zwolnienia, gdy plik zaaktualizowany jest mniejszy

	; przywróc oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax
	
	; powrót z procedury
	ret

;===============================================================================
; procedura wyszukuje w katalogu głównym wolnego supła/węzła dla pliku
; IN:
;	r8 - specyfikacja systemu plików
; OUT:
;	rdi - adres bezwzględny znalezionego wolnego supła
;
; pozostałe rejestry zachowane
cyjon_virtual_file_system_find_free_knot:
	; zachowaj oryginalne rejestry
	push	rcx

	; załaduj adres poczatku tablicy supłów
	mov	rdi,	qword [r8 + virtual_file_system_superblock.s_knots_table]

.prepare:
	; ilość rekordów na blok
	mov	rcx,	73

.loop:
	; sprawdź czy ilość znaków w nazwie pliku jest równa zero
	cmp	qword [rdi + 0x10],	VARIABLE_EMPTY
	je	.found

	; przesuń wskaźnik na następny rekord
	add	rdi,	56

	; kontynuuj z kolejnymi rekordami
	loop	.loop

	; sprawdź czy tablica zawiera inne bloki danych
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.new	; jeśli tak, przeszukaj następny blok

	; pobierz adres następnego bloku tablicy
	mov	rdi,	qword [rdi]

	; kontynuuj poszukiwania
	jmp	.prepare

.new:
	; zapamiętaj
	mov	rcx,	rdi

	; zarezerwuj wolny blok
	call	cyjon_page_allocate
	; wyczyść
	call	cyjon_page_clear

	; dopisz do tablicy
	mov	qword [rcx],	rdi

	; kontynuuj poszukiwania
	jmp	.prepare
	
.found:
	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; procedura tworzy nowy system plików
; IN:
;	r8 - adres tablicy specyfikacji systemu plików
; OUT:
;	brak
;
; wszystkie rejestry zachowane
virtual_file_system_initialization:
	; zachowaj oryginalne rejestry
	push	rdi

	; przygotuj muejsce na tablice supłów
	call	cyjon_page_allocate
	call	cyjon_page_clear

	; aktualny rozmiar nośnika w blokach
	mov	qword [r8],	1	; tablica supłów

	; rozmair systemu plików w blokach
	mov	qword [r8 + virtual_file_system_superblock.s_fs_blocks_count],	1

	; zapisz adres tablicy supłów
	mov	qword [r8 + virtual_file_system_superblock.s_knots_table],	rdi

	; rozmiar tablicy supłów w blokach
	mov	qword [r8 + virtual_file_system_superblock.s_knots_table_size],	1

	; przywróć oryginalne rejestry
	pop	rdi

	; powrót z procedury
	ret

;===============================================================================
; procedura ładuje zawartość pliku do pamięci
; IN:
;	rsi - numer pierwszego bloku danych pliku
;	rdi - adres gdzie załadować plik
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_virtual_file_system_read_file:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

.prepare:
	; rozmiar bloku do skopiowania
	mov	rcx,	4096 - 8
	shr	rcx,	3	; /8

	; kopiuj
	rep	movsq

	; sprawdź czy koniec pliku
	cmp	qword [rsi],	VARIABLE_EMPTY
	je	.end

	; pobierz informacje o następnym bloku do załadowania
	mov	rsi,	qword [rsi]

	; kontynuuj z następnym blokiem
	jmp	.prepare

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; procedura przeszukuje katalogłówny systemu plików za wskazaną nazwą pliku
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rsi - ciąg znaków reprezentujący nazwę pliku
;	r8 - specyfikacja systemu plików
; OUT:
;	rdi - adres rekordu opisującego plik
;
; wszystkie rejestry zachowane
cyjon_virtual_file_system_find_file:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	push	rcx

	; zapamiętaj ilość znaków w nazwie pliku
	mov	rax,	rcx

	; wyzeruj numer rekordu

	; załaduj adres poczatku tablicy supłów
	mov	rdi,	qword [r8 + virtual_file_system_superblock.s_knots_table]

.prepare:
	; ilość rekordów na blok
	mov	rcx,	73

.loop:
	; sprawdź czy ilość znaków na nazwe pliku jest różna poszukiwanej
	cmp	qword [rdi + 0x10],	rax
	jne	.continue

	; przesuń wskaźnik na ciąg znaków nazwy pliku
	add	rdi,	0x18

	; koryguj zawartość zmiennej
	xchg	rcx,	rax

	; porównaj ciągi
	call	library_compare_string

	; koryguj zawartość zmiennej
	xchg	rcx,	rax

	; czy ciągi były takie same?
	jc	.found

	; koryguj wskaźnik na poczatek rekordu
	sub	rdi,	0x18

.continue:
	; przesuń wskaźnik na następny rekord
	add	rdi,	56

	; kontynuuj z kolejnymi rekordami
	loop	.loop

	; skończyły się rekordy z danego bloku
	mov	rdi,	qword [rdi]

	; sprawdź czy tablica zawiera inne bloki danych
	cmp	rdi,	VARIABLE_EMPTY
	ja	.prepare	; jeśli tak, przeszukaj następny blok

	; zwróć brak adresu rekordu szukanego pliku
	xor	rdi,	rdi

	; wyłącz flagę
	clc

	; koniec obsługi procedury
	jmp	.end
	
.found:
	; zwróć adres rekordu opisującego znleziony plik
	sub	rdi,	0x18

	; ustaw wlagę
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rax

	; powrót z procedury
	ret
