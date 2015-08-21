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

variable_process_semaphore_init	db	0x00

variable_process_new		dq	0x0000000000000000
variable_process_close		dq	0x0000000000000000
variable_process_pid		dq	0x0000000000000000

;===============================================================================
; procedura uruchamia nowy proces, przydzielając pamięć i numer identyfikacyjny
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rsi - wskaźnik do nazwy pliku
; OUT:
;	rax - numer PID uruchomionego procesu
;
; pozostałe rejestry zachowane
cyjon_process_init:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r11

	; szukaj pliku na partycji systemowej
	call	cyjon_virtual_file_system_find_file
	jc	.leave	; znaleziono plik

	; pliku nie znaleziono
	xor	rax,	rax

	; koniec obsługi procedury
	jmp	.end

.ready:
	; odłóż na stos adres powrotu
	push	alive

	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r11

	; pobierz wskaźnik supła do uruchomienia
	mov	rdi,	qword [variable_process_new]

.leave:
	; pobierz rozmiar pliku w Bajtach
	mov	rcx,	qword [rdi + 0x08]
	; utwórz zmienną lokalną
	push	rcx

	; usuń młodszą część rozmiaru
	and	cx,	0xF000

	; sprawdź czy rozmiar uległ zmianie
	cmp	rcx,	qword [rsp]
	je	.ok	; jeśli nie, ok

	; jeśli tak, zwiększ rozmiar pliku o jedną stronę
	add	rcx,	0x1000

.ok:
	; usuń zmienną lokalną
	add	rsp,	0x08

	; zamień rozmiar pliku na strony
	shr	rcx,	12

	; przygotuj przestrzeń pod proces
	mov	rax,	VIRTUAL_HIGH_MEMORY_ADDRESS
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3	; tablica PML4 jądra systemu
	call	cyjon_page_map_logical_area	; wykonaj

	; załaduj plik do pamięci
	mov	rsi,	qword [rdi]	; numer pierwszego bloku danych pliku
	mov	rdi,	REAL_HIGH_MEMORY_ADDRESS
	call	cyjon_virtual_file_system_read_file

	; przygotuj miejsce pod stos procesu
	mov	rax,	VIRTUAL_HIGH_MEMORY_ADDRESS + VIRTUAL_HIGH_MEMORY_ADDRESS - 0x1000	; ostatnie 4 KiB pamięci logicznej
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; rozmiar stosu, jedna strona (4096 Bajtów)
	mov	r11,	cr3	; tablica PML4 jądra systemu
	call	cyjon_page_map_logical_area	; wykonaj

	; przygotuj miejsce dla tablicy PML4 procesu
	call	cyjon_page_allocate

	; zapamiętaj
	push	rdi

	; mapuj tablicę PML4 jądra do procesu
	mov	rsi,	cr3	; tablica PML4 jądra systemu
	mov	rcx,	512	; 512 rekordów
	rep	movsq	; kopiuj

	; załaduj tablicę PML4 procesu
	mov	r11,	qword [rsp]

	; usuń stos kontekstu jądra, zostanie utworzony nowy dla procesu
	mov	qword [r11 + 0x07F8],	0x0000000000000000

	; utwórz stos kontekstu procesu
	mov	rax,	VIRTUAL_HIGH_MEMORY_ADDRESS - 0x1000	; ostatnie 4 KiB Low Memory
	mov	rcx,	1	; jedna strona o rozmiarze 4 KiB
	mov	rbx,	0x03	; ustaw flagi 4 KiB, Administrator, 4 KiB, Odczyt/Zapis, Dostępna
	call	cyjon_page_map_logical_area	; wykonaj

	; odłóż na stos kontekstu procesu spreparowane dane powrotu z planisty
	mov	rdi,	qword [r8]
	and	di,	0xFFF0	; usuń właściwości strony z adresu

	; wyczyść stos kontekstu procesu
	call	cyjon_page_clear

	; przesuń wskaźnik na spreparowany wskaźnik szczytu stosu kontekstu procesu
	add	rdi,	0x1000 - ( 5 * 0x08 )

	; odstaw na stos kontekstu procesu spreparowane dane powrotu z przerwania IRQ0

	; RIP
	mov	rax,	REAL_HIGH_MEMORY_ADDRESS
	stosq	; zapisz

	; CS
	mov	rax,	0x18 | 3	; +3 typ: proces
	stosq	; zapisz

	; EFLAGS
	mov	rax,	0x246
	stosq	; zapisz

	; RSP
	mov	rax,	0x0000000000000000
	stosq	; zapisz

	; DS
	mov	rax,	0x20 | 3	; +3 typ: proces
	stosq	; zapisz

	; załaduj adres tablicy PML4 procesu
	mov	rax,	qword [rsp]

.free:
	; oczekuj na wolne miejsce w tablicy procesów
	cmp	qword [variable_process_table_count],	PROCESS_LIMIT
	je	.free

.wait:
	; sprawdź czy tablica procesów jest dostępna
	cmp	byte [variable_multitasking_semaphore_process_table],	0x01
	je	.wait	; jeśli nie, czekaj

	; zablokuj tablice procesów
	mov	byte [variable_multitasking_semaphore_process_table],	0x01

	; znajdź wolny rekord w tablicy procesów
	mov	rdi,	qword [variable_process_table_address]

.loop:
	; szukaj wolnego rekordu w tablicy
	cmp	qword [rdi],	0x0000000000000000
	je	.found

	; przesuń wskaźnik na następny rekord
	add	rdi,	0x10

	; szukaj dalej
	jmp	.loop

.found:
	; oblicz identyfikator procesu
	mov	rax,	rdi

	; wyczyść starszą część
	and	rax,	0x0000000000000fff
	shr	rax,	4	; / 0x10

	; zapamiętaj identyfikator procesu
	xchg	rax,	qword [rsp]

	; zapisz adres tablicy PML4 procesu do rekordu
	stosq
	
	; zapisz adres szczytu stosu kontekstu procesu do rekordu
	mov	rax,	VIRTUAL_HIGH_MEMORY_ADDRESS - (21 * 0x08)
	stosq

	; zwiększ ilość rekordów/procesów przechowywanych w tablicy
	inc	qword [variable_process_table_count]

	; odblokuj tablice procesów dla planisty
	mov	byte [variable_multitasking_semaphore_process_table],	0x00

	; wysprzątaj tablice PML4 jądra z zainicjalizowanego procesu
	xor	rax,	rax	; wyczyść rekordy
	mov	rcx,	0x100	; 256 rekordów (256:511)
	mov	rdi,	cr3	; adres tablicy PML4 jądra systemu
	add	rdi,	256 * 0x08	; przesuń wskaźnik na 256 rekord tablicy PML4 jądra systemu
	rep	stosq	; wyczyść

	; zwróć informacje o numerze identyfikatora uruchomionego procesu
	pop	qword [variable_process_pid]

	; zwolnij możliwość uruchomienia nowego procesu
	mov	qword [variable_process_new],	0x0000000000000000

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

cyjon_process_close:
	; załaduj adres rekordu z tablicy procesów
	mov	rdi,	qword [variable_process_close]

	; pobierz adres tablicy PML4 procesu do zamknięcia
	mov	rbx,	qword [rdi]

	; zapamiętaj adres tablicy PML4 procesu
	push	rbx

	; wyczyść rekord w tablicy
	mov	qword [rdi],	0x0000000000000000

	; zmniejsz ilość procesów przechowywanych w tablicy
	dec	qword [variable_process_table_count]

	; zwolnij pamięć zajętą przez proces
	mov	rdi,	rbx	; załaduj adres tablicy PML4 procesu
	add	rdi,	255 * 0x08	; rozpocznij zwalnianie przestrzeni od rekordu stosu kontekstu procesu
	mov	rbx,	4	; ustaw poziom tablicy przetwarzanej
	mov	rcx,	257	; ile pozostało rekordów w tablicy PML4 do zwolnienia
	call	cyjon_page_release_area.loop

	; przywróć adres tablicy PML4 procesu
	pop	rdi

	; zwolnij przestrzeń spod tablicy PML4 procesu
	call	cyjon_page_release

	; zwolnij procedure zamykania procesów
	mov	qword [variable_process_close],	0x0000000000000000

	; kontynuuj
	jmp	alive
