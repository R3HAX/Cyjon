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

variable_process_semaphore_init	db	VARIABLE_EMPTY

variable_process_new		dq	VARIABLE_EMPTY
variable_process_close		dq	VARIABLE_EMPTY
variable_process_pid		dq	VARIABLE_EMPTY

;===============================================================================
; procedura uruchamia nowy proces, przydzielając pamięć i numer identyfikacyjny
; IN:
;	rcx - ilość znaków w nazwie pliku
;	rdx - rozmiar danych do przetransferowania
;	rsi - wskaźnik do nazwy pliku i danych
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
	push	r8
	push	r11

	; szukaj pliku na partycji systemowej
	call	cyjon_virtual_file_system_find_file
	jc	.found	; znaleziono plik

	; pliku nie znaleziono
	xor	rcx,	rcx

	; koniec obsługi procedury
	jmp	.end

.found:
.ready:
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
	add	rcx,	VARIABLE_MEMORY_PAGE_SIZE

.ok:
	; usuń zmienną lokalną
	add	rsp,	0x08

	; zamień rozmiar pliku na strony
	shr	rcx,	12

	; przygotuj przestrzeń pod proces w 254 rekordzie tablicy PML4 (limit rozmiaru programu 512 GiB)
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - ( VARIABLE_MEMORY_PML4_RECORD_SIZE * 2 )
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3	; tablica PML4 aktualnego procesu
	call	cyjon_page_map_logical_area	; wykonaj

	; załaduj plik do pamięci
	mov	rsi,	qword [rdi]	; numer pierwszego bloku danych pliku
	mov	rdi,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - ( VARIABLE_MEMORY_PML4_RECORD_SIZE * 2 )
	call	cyjon_virtual_file_system_read_file

	; przygotuj miejsce dla tablicy PML4 procesu
	call	cyjon_page_allocate

	; zapamiętaj
	push	rdi

	; mapuj tablicę PML4 aktualnego procesu do nowego
	mov	rsi,	cr3
	mov	rcx,	255
	rep	movsq	; kopiuj

	; załaduj tablicę PML4 procesu
	mov	r11,	qword [rsp]

	; przesuń załadowany program w odpowiednie miejsce pamięci logicznej nowej tablicy PML4 procesu
	mov	rax,	qword [r11 + 0x07F0]
	mov	qword [r11 + 0x0800],	rax
	mov	rax,	cr3
	mov	qword [rax + 0x07F0],	VARIABLE_EMPTY
	mov	qword [r11 + 0x07F0],	VARIABLE_EMPTY

	; usuń stos aktualnego procesu
	mov	qword [r11 + 0x0FF8],	VARIABLE_EMPTY
	; usuń stos kontekstu aktualnego procesu
	mov	qword [r11 + 0x07F8],	VARIABLE_EMPTY

	; przygotuj miejsce pod stos procesu
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS + VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - 0x1000	; ostatnie 4 KiB pamięci logicznej
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; rozmiar stosu, jedna strona (4096 Bajtów)
	call	cyjon_page_map_logical_area	; wykonaj

	; utwórz stos kontekstu procesu
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - 0x1000	; ostatnie 4 KiB Low Memory
	mov	rbx,	0x03	; ustaw flagi 4 KiB, Administrator, 4 KiB, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; jedna strona o rozmiarze 4 KiB
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
	mov	rax,	VARIABLE_MEMORY_HIGH_REAL_ADDRESS
	stosq	; zapisz

	; CS
	mov	rax,	0x18 | 3	; +3 typ: proces
	stosq	; zapisz

	; EFLAGS
	mov	rax,	0x246
	stosq	; zapisz

	; RSP
	mov	rax,	VARIABLE_EMPTY
	stosq	; zapisz

	; DS
	mov	rax,	0x20 | 3	; +3 typ: proces
	stosq	; zapisz

	mov	rdi,	qword [variable_multitasking_serpentine_start_address]
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	jmp	.do_not_leave_me

.next_record:
	dec	rcx

	; przesuń na następny rekord
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.do_not_leave_me:
	cmp	rcx,	VARIABLE_EMPTY
	ja	.in_page

	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	and	di,	0xF000
	add	rdi,	0x0FF8

	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.serpentine_full

	mov	rdi,	qword [rdi]

	jmp	.in_page

.serpentine_full:
	push	rdi

	call	cyjon_page_allocate
	call	cyjon_page_clear

	pop	rax

	mov	qword [rax],	rdi

.in_page:
	cmp	word [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY
	jne	.next_record

	; pobierz dostępny identyfikator procesu
	mov	rax,	qword [variable_multitasking_pid_value_next]

	; zachowaj
	push	rax

	; szukaj nastepnego wolnego
	inc	rax

	push	rax

	; sprawdź czy numer procesu jest dozwolony (modulo ROZMIAR_STRONY != 0)
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE
	xor	rdx,	rdx
	div	rcx

	cmp	rdx,	VARIABLE_EMPTY
	jne	.pid

	; następny
	inc	qword [rsp]

.pid:
	; zapisz
	pop	qword [variable_multitasking_pid_value_next]

	; przywróć
	pop	rax

	; zapisz PID procesu do rekordu
	stosq

	; zapisz CR3 procesu
	xchg	rax,	qword [rsp]
	stosq

	; zapisz adres szczytu stosu kontekstu procesu do rekordu
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - (21 * 0x08)
	stosq

	; ustaw flagę rekordu na aktywny
	mov	rax,	STATIC_SERPENTINE_RECORD_FLAG_USED | STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	stosq

	; ustaw wskaźnik do nazwy pliku
	mov	rsi,	qword [rsp + 0x20]

	; rozmiar nazwy pliku
	mov	rcx,	qword [rsp + 0x30]

	; załaduj nazwe procesu do rekordu
	rep	movsb

	; zwiększ ilość rekordów/procesów przechowywanych w tablicy
	inc	qword [variable_multitasking_serpentine_record_counter]

	; zwróć informacje o numerze identyfikatora uruchomionego procesu
	pop	rcx

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	add	rsp,	0x08
	pop	rbx

	; powrót z procedury
	ret
