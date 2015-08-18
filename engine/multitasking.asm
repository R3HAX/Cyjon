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

; semafor blokujący dostęp do tablicy procesów
variable_multitasking_semaphore_process_table	db	0x00

; adres logiczny tablicy z uruchomionymi procesami
variable_process_table_address			dq	0x0000000000000000
; aktualnie obsługiwany proces ( uruchomiony)
variable_process_table_record_active		dq	0x0000000000000000
; ilość rekordów przechowywanych w tablicy
variable_process_table_count			dq	0x0000000000000000
; ilość rekordów, które zostały przetworzone
variable_process_table_handled			dq	0x0000000000000000

;===============================================================================
; procedura tworzy i dodaje jądro systemu do tablicy procesów uruchomionych
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
multitasking:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; limit procesów możliwych do uruchomienia dostanie ograniczony do 256
	; 4096 / ( 1 [adres tablicy PML4 procesu] + 1 [wskaźnik szczytu stosu kontekstu procesu] ) = 256 rekordów
	call	cyjon_page_allocate	; plik: engine/paging.asm
	; wyczyść tablice procesów
	call	cyjon_page_clear	; plik: engine/paging.asm

	; zapisz adres tablicy procesów
	mov	qword [variable_process_table_address],	rdi

	; utwórz pierwszy rekord w tablicy procesów, czyli jądro systemu
	; jeden rekord składa się z 16 Bajtów

	; zapisz adres bezwzględny rekordu aktualnie uruchomionego procesu
	mov	qword [variable_process_table_record_active],	rdi

	; załaduj do rekordu adres tablicy PML4 jądra systemu
	mov	rax,	cr3
	stosq	; zapisz zawartość rejestru RAX pod adres w wskaźniku RDI, zwiększ wskaźnik o 8 Bajtów

	; przy pierwszym przełączeniu procesów, adres stosu kontekstu w rekordzie - zostanie uzupełniony poprawną wartością

	; aktualizuj ilość przechowywanych rekordów w tablicy
	inc	qword [variable_process_table_count]

	; aktualizuj ilość procesów obsłużonych (czyli jądro systemu w tym momencie)
	inc	qword [variable_process_table_handled]

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura przełącza procesor na następny proces, poprzedni stan procesora zostanie zachowany na stosie kontekstu poprzedniego procesu
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_irq32:
	; wyłącz przerwania, nic nie może przeszkadzać
	cli

	; zachowaj oryginalne rejestry na stos kontekstu procesu
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp

	; rejestr RSP został już zachowany poprzez wywołanie przerwania sprzętowego IRQ0
	; push	rsp

	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; odłóż na stos kontekstu flagi procesora
	pushfq

	; zwiększ znacznik mikroczasu do obliczenia "uptime"
	inc	qword [variable_microtime]

	; sprawdź czy tablica procesów jest zablokowana
	cmp	byte [variable_multitasking_semaphore_process_table],	0x01
	je	.end	; jeśli tak, nie przełączaj zadań
	; jądro systemu w tym momencie zamyka, uruchamia lub modyfikuje proces

	; zablokuj tablice procesów
	mov	byte [variable_multitasking_semaphore_process_table],	0x01

	; załaduj adres wskaźnika aktualnie przetwarzanego rekordu
	mov	rdi,	qword [variable_process_table_record_active]

	; zapisz aktualny wskaźnik stosu kontekstu wstrzymanego procesu
	mov	qword [rdi + 0x08],	rsp

	; załaduj ilość procesów przetworzonych
	mov	rcx,	qword [variable_process_table_handled]

	; sprawdź czy jest to ostatni dostępny rekord w tablicy procesów
	cmp	rcx,	qword [variable_process_table_count]
	jne	.next	; jeśli nie, szukaj następnego dostępnego procesu w tablicy

	; jeśli tak, ustaw wskaźnik na pierwszy rekord tablicy procesów (jądro systemu)
	mov	rdi,	qword [variable_process_table_address]

	; zresetuj licznik procesów obsłużonych
	mov	qword [variable_process_table_handled],	0x0000000000000000

	; załaduj proces
	jmp	.found

.next:
	; przesuń wskaźnik na następny rekord
	add	rdi,	0x10	; pml4 + rsp = jeden rekord

	; sprawdź czy rekord zawiera informacje o procesie
	cmp	qword [rdi],	0x0000000000000000	; czy brak wpisanej tablicy PML4 procesu
	je	.next	; jeśli tak, pobierz zawartość następnego rekordu

.found:
	; zwiększ licznik procesów przetworzonych
	inc	qword [variable_process_table_handled]

	; zapamiętaj adres aktualnie przetwarzanego rekordu
	mov	qword [variable_process_table_record_active],	rdi

	; ustaw wskaźnik stosu kontektu w ostatnie znane miejsce dla procesu
	mov	rsp,	qword [rdi + 0x08]

	; przełącz stronicowanie na nowy proces
	mov	rax,	qword [rdi]	; pobierz adres PML4 następnego procesu
	mov	cr3,	rax	; wykonaj

	; udostępnij tablice procesów
	mov	byte [variable_multitasking_semaphore_process_table],	0x00

.end:
	; wyślij informacje o zakończeniu obsługi przerwania sprzętowego
	mov	al,	0x20
	out	0x20,	al

	; pobierz z stosu kontekstu flagi procesora
	popfq

	; przywróć oryginalne rejestry z stosu kontekstu procesu
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8

	; rejestr RSP zostanie przywrócony po zakończeniu przerwania sprzętowego IRQ0
	; pop	rsp

	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; włącz przerwania
	sti

	; powrót z przerwania
	iretq
