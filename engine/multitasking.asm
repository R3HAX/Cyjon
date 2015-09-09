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

; ilość rekordów mieszczących się w jednej stronie pamięci
STATIC_PROCESS_RECORDS_PER_PAGE	equ	51

struc STATIC_PROCESS_RECORD
	.PID		resq	1
	.CR3		resq	1
	.RSP		resq	1
	.FLAGS		resq	1
	.NAME		resb	32
	.ARGS		resq	1
	.RESERVED	resq	1	; do wykorzystania w przyszłości
	.SIZE		resb	1	; raz chciałem wykonać "add rdi, STATIC_PROCESS_RECORD", ale nie podziałało, ta wartość ją zastępuje ;)
endstruc

; kolejny numer PID procesu
variable_process_pid_next				dq	VARIABLE_EMPTY

; semafor blokujący dostęp do tablicy procesów
variable_process_serpentine_blocked			db	VARIABLE_EMPTY
; adres logiczny tablicy z uruchomionymi procesami
variable_process_serpentine_start_address		dq	VARIABLE_EMPTY
; aktualnie obsługiwany proces ( uruchomiony)
variable_process_serpentine_record_active		dq	VARIABLE_EMPTY
; ilość rekordów przechowywanych w tablicy
variable_process_serpentine_record_count		dq	VARIABLE_EMPTY
; ilość rekordów obsłużonych w części serpentyny
variable_process_serpentine_record_count_handled	dq	VARIABLE_EMPTY

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

	call	cyjon_page_allocate
	call	cyjon_page_clear

	; zapisz adres tablicy procesów
	mov	qword [variable_process_serpentine_start_address],	rdi

	; zwiąż koniec serpentyny z początkiem
	mov	rax,	rdi
	mov	qword [rdi + VARIABLE_MEMORY_PAGE_SIZE - 0x08],	rax

	; utwórz pierwszy rekord w serpentynie procesów, czyli jądro systemu
	; jeden rekord składa się z 80 Bajtów
	add	rdi,	0x08	; pomiń nagłówek tablicy

	; zapisz adres bezwzględny rekordu aktualnie uruchomionego procesu
	mov	qword [variable_process_serpentine_record_active],	rdi

	; zapisz numer PID procesu
	mov	rax,	qword [variable_process_pid_next]
	stosq

	; załaduj do rekordu adres tablicy PML4 jądra systemu
	mov	rax,	cr3
	stosq	; zapisz zawartość rejestru RAX pod adres w wskaźniku RDI, zwiększ wskaźnik o 8 Bajtów

	; przy pierwszym przełączeniu procesów, adres stosu kontekstu w rekordzie - zostanie uzupełniony poprawną wartością
	add	rdi,	0x08	; pomiń

	; zapisz flagi procesu
	mov	rax,	1b	; rekord aktywny (jeszcze nie ustaliłem specyfkacji)
	stosq

	; zachowaj adres rekordu
	push	rdi

	; ustaw nazwę procesu
	mov	al,	"k"
	stosb
	mov	al,	"e"
	stosb
	mov	al,	"r"
	stosb
	mov	al,	"n"
	stosb
	mov	al,	"e"
	stosb
	mov	al,	"l"
	stosb

	; przywróc adres rekordu
	pop	rdi

	; jądro systemu nie przyjmuje argumentów

	; aktualizuj ilość przechowywanych rekordów w serpentynie
	inc	qword [variable_process_serpentine_record_count]

	; ustal następny dostępny numer procesu
	inc	qword [variable_process_pid_next]

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
irq32:
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
	inc	qword [variable_system_microtime]

	; sprawdź czy tablica procesów jest zablokowana
	cmp	byte [variable_process_serpentine_blocked],	0x01
	je	.end	; jeśli tak, nie przełączaj zadań
	; jądro systemu w tym momencie zamyka, uruchamia lub modyfikuje proces

	; zablokuj tablice procesów
	mov	byte [variable_process_serpentine_blocked],	0x01

	; załaduj adres wskaźnika aktualnie przetwarzanego rekordu
	mov	rdi,	qword [variable_process_serpentine_record_active]

	; zapisz aktualny wskaźnik stosu kontekstu wstrzymanego procesu
	mov	qword [rdi + STATIC_PROCESS_RECORD.RSP],	rsp

	; ilość rekordów przeszukanych
	mov	rcx,	qword [variable_process_serpentine_record_count_handled]

.next:
	; zarejestruj obsłużony rekord w danej części serpentyny
	inc	rcx

	; przesuń na następny rekord
	add	rdi,	STATIC_PROCESS_RECORD.SIZE

	cmp	rcx,	STATIC_PROCESS_RECORDS_PER_PAGE
	jb	.in_page

	; zładuj adres kolejnej części serpentyny
	mov	rdi,	qword [rdi]
	; pomiń nagłówek
	add	rdi,	0x08

	; zresetuj licznik rekordów na część serpentyny
	xor	rcx,	rcx

.in_page:
	; flaga ACTIVE
	xor	bx,	bx
	; sprawdź czy rekord jest aktywny
	bt	word [rdi + STATIC_PROCESS_RECORD.FLAGS],	bx
	jnc	.next	; jeśli nie

.found:
	; zapamięraj ilość obsłużonych rekordów
	mov	qword [variable_process_serpentine_record_count_handled],	rcx

	; zapamiętaj adres aktualnie przetwarzanego rekordu
	mov	qword [variable_process_serpentine_record_active],	rdi

	; ustaw wskaźnik stosu kontektu w ostatnie znane miejsce dla procesu
	mov	rsp,	qword [rdi + STATIC_PROCESS_RECORD.RSP]

	; przełącz stronicowanie na nowy proces
	mov	rax,	qword [rdi + STATIC_PROCESS_RECORD.CR3]	; pobierz adres PML4 następnego procesu
	mov	cr3,	rax	; wykonaj

	; udostępnij tablice procesów
	mov	byte [variable_process_serpentine_blocked],	VARIABLE_EMPTY

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
