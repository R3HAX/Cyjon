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

text_daemon_garbage_collector_name	db	"garbage_collector"
text_daemon_garbage_collector_name_end:

; 64 Bitowy kod programu
[BITS 64]

daemon_garbage_collector:
	; szukaj procesu gotowego do zamknięcia
	mov	bx,	STATIC_SERPENTINE_RECORD_FLAG_USED + STATIC_SERPENTINE_RECORD_FLAG_CLOSED

	call	cyjon_multitasking_serpentine_find_record

	; pobierz adres tablicy PML4 procesu do zamknięcia
	mov	rbx,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.CR3]

	; zapamiętaj adres tablicy PML4 procesu
	push	rbx

	; zmniejsz ilość procesów przechowywanych w tablicy
	dec	qword [variable_multitasking_serpentine_record_counter]

	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS],	VARIABLE_EMPTY
	je	.no_args

	; zwolnij przestrzeń pod argumenty
	push	rdi

	mov	rdi,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS]
	call	cyjon_page_release

	pop	rdi

.no_args:
	; wyczyść rekord w tablicy
	mov	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY

	; wyczyść nazwę pliku z rekordu
	xor	al,	al
	mov	rcx,	VARIABLE_TABLE_SERPENTINE_RECORD.ARGS - VARIABLE_TABLE_SERPENTINE_RECORD.NAME
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.NAME

.loop:
	mov	byte [rdi],	al
	add	rdi,	VARIABLE_INCREMENT
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop

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

	hlt

	jmp	daemon_garbage_collector

daemon_init_garbage_collector:
	; przygotuj miejsce dla tablicy PML4 demona
	call	cyjon_page_allocate

	; zapamiętaj
	push	rdi

	; mapuj tablicę PML4 jądra do demona
	mov	rsi,	cr3	; tablica PML4 jądra systemu
	mov	rcx,	512	; 512 rekordów
	rep	movsq	; kopiuj

	; załaduj tablicę PML4 demona
	mov	r11,	qword [rsp]

	; usuń stos kontekstu jądra, zostanie utworzony nowy dla demona
	mov	qword [r11 + 0x07F8],	VARIABLE_EMPTY

	; utwórz stos kontekstu demona
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - 0x1000	; ostatnie 4 KiB Low Memory
	mov	rcx,	1	; jedna strona o rozmiarze 4 KiB
	mov	rbx,	0x03	; ustaw flagi 4 KiB, Administrator, 4 KiB, Odczyt/Zapis, Dostępna
	call	cyjon_page_map_logical_area	; wykonaj

	; odłóż na stos kontekstu demona spreparowane dane powrotu z planisty
	mov	rdi,	qword [r8]
	and	di,	0xFFF0	; usuń właściwości strony z adresu

	; wyczyść stos kontekstu demona
	call	cyjon_page_clear

	; przesuń wskaźnik na spreparowany wskaźnik szczytu stosu kontekstu demona
	add	rdi,	0x1000 - ( 5 * 0x08 )

	; odstaw na stos kontekstu demona spreparowane dane powrotu z przerwania IRQ0

	; RIP
	mov	rax,	daemon_garbage_collector
	stosq	; zapisz

	; CS
	mov	rax,	0x08
	stosq	; zapisz

	; EFLAGS
	mov	rax,	0x246
	stosq	; zapisz

	; RSP
	mov	rax,	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS
	stosq	; zapisz

	; DS
	mov	rax,	0x10
	stosq	; zapisz

	; załaduj adres tablicy PML4 procesu
	mov	rax,	qword [rsp]

	; znajdź wolny rekord w tablicy procesów
	mov	rdi,	qword [variable_multitasking_serpentine_start_address]

	; flaga
	xor	bx,	bx

.next:
	; przesuń na następny rekord
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	; koniec rekordów w części serpentyny?
	mov	cx,	di
	and	cx,	0x0FFF
	cmp	cx,	0x0FF8
	jne	.in_page

	; zładuj adres kolejnej części serpentyny
	mov	rcx,	qword [rdi]

	; koniec serpentyny?
	cmp	rcx,	qword [variable_multitasking_serpentine_start_address]
	jne	.not_at_end

	; rozszerz serpentynę
	mov	rcx,	rdi
	call	cyjon_page_allocate
	call	cyjon_page_clear
	push	rcx
	mov	rcx,	qword [variable_multitasking_serpentine_start_address]
	mov	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - 0x08],	rcx
	pop	rcx
	mov	qword [rcx],	rdi
	mov	rdi,	rcx

.not_at_end:
	mov	rdi,	qword [rdi]

.in_page:
	; sprawdź czy rekord jest niedostepny
	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY
	ja	.next	; jeśli tak

.found:
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
	mov	rax,	STATIC_SERPENTINE_RECORD_FLAG_USED | STATIC_SERPENTINE_RECORD_FLAG_ACTIVE | STATIC_SERPENTINE_RECORD_FLAG_DAEMON
	stosq

	; ustaw wskaźnik do nazwy pliku
	mov	rsi,	text_daemon_garbage_collector_name

	; rozmiar nazwy pliku
	mov	rcx,	text_daemon_garbage_collector_name_end - text_daemon_garbage_collector_name

	; załaduj nazwe procesu do rekordu
	rep	movsb

	; zwiększ ilość rekordów/procesów przechowywanych w tablicy
	inc	qword [variable_multitasking_serpentine_record_counter]

	; usuń adres tablicy PML4 demona
	add	rsp,	0x08

	; powrót z procedury
	ret
