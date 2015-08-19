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

variable_idt_structure:
variable_interrupt_descriptor_table_limit	dw	0x1000	; rozmiar tablicy / do 512 rekordów
variable_interrupt_descriptor_table_address	dq	0x0000000000000000

;===============================================================================
; procedura tworzy tablicę IDT do obsługi przerwań i wyjątków
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
interrupt_descriptor_table:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; przygotuj miejsce na Tablicę Deskryptorów Przerwań
	call	cyjon_page_allocate	; plik: engine/paging.asm
	; wyczyść wszystkie rekordy
	call	cyjon_page_clear	; plik: engine/paging.asm

	; zapisz adres Tablicy Deskryptorów Przerwań
	mov	qword [variable_interrupt_descriptor_table_address],	rdi

	; utworzymy obsługę 32 wyjątków (zombi, w przyszłości utworzy się odpowiednie procedury obsługi) procesora
	mov	rax,	itd_cpu_exception
	mov	bx,	0x8E00	; typ - wyjątek procesora
	mov	rcx,	32	; wszystkie wyjątki procesora
	call	recreate_record	; utwórz

	; utworzymy obsługę 16 przerwań (zombi) sprzętowych
	; gdyby jakimś cudem wystąpiły
	; co niektóre dostaną prawidłową procedurę obsługi
	mov	rax,	itd_hardware_interrupt
	mov	bx,	0x8F00	; typ - przerwanie sprzętowe
	mov	rcx,	16	; wszystkie przerwania sprzętowe
	call	recreate_record	; utwórz

	; utworzymy obsługę pozostałych 208 przerwań (zombi) programowych
	; tylko jedno z nich (przerwanie 64, 0x40) dostanie prawidłową procedurę obsługi
	mov	rax,	itd_software_interrupt
	mov	bx,	0xEF00	; typ - przerwanie programowe
	mov	rcx,	208	; pozostałe rekordy w tablicy
	call	recreate_record	; utwórz

	; podłączamy poszczególne procedury obsługi przerwań/wyjątków

	;---------------------------------------------------------------

	; procedura obsługi przerwania sprzętowego zegara
	mov	rax,	irq32	; plik: engine/multitasking.asm
	mov	bx,	0x8F00	; typ - przerwanie sprzętowe
	mov	rcx,	1	; modyfikuj jeden rekord
	; ustaw adres rekordu
	mov	rdi,	qword [variable_interrupt_descriptor_table_address]
	add	rdi,	0x10 * 32	; podrekord 0x00
	call	recreate_record	; wykonaj

	; procedura obsługi przerwania sprzętowego klawiatury
	mov	rax,	irq33	; plik: engine/keyboard.asm
	call	recreate_record	; wykonaj

	;---------------------------------------------------------------

	; procedura obsługi przerwania programowego użytkownika
	mov	rax,	irq64	; plik: engine/multitasking.asm
	mov	bx,	0xEF00	; typ - przerwanie sprzętowe
	mov	rcx,	1	; modyfikuj jeden rekord
	; ustaw adres rekordu
	mov	rdi,	qword [variable_interrupt_descriptor_table_address]
	add	rdi,	0x10 * 64	; 40-ty wpis
	call	recreate_record	; wykonaj

	;---------------------------------------------------------------

	; załaduj Tablicę Deskryptorów Przerwań
	lidt	[variable_idt_structure]

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z przerwania
	ret

;===============================================================================
; procedura podstawowej obsługi wyjątku/przerwania procesora
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
itd_cpu_exception:
	; wyświetl informację
	mov	rbx,	COLOR_RED
	mov	rcx,	-1	; wyświetl całą informację
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	mov	rsi,	text_cpu_exception
	call	cyjon_screen_print_string	; plik: engine/screen.asm

	; wyświetl rozamiar pozostałej pamięcie w ilości stron
	mov	rax,	qword [variable_binary_memory_map_free_pages]
	mov	rcx,	10	; system dziesiętny
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	call	cyjon_screen_print_number

	; przejdź do następnej linii
	mov	rsi,	text_paragraph
	call	cyjon_screen_print_string

	; pobierz z stosu 6 wartości
	mov	rcx,	5
.loop:
	; pobierz z stosu informacje
	pop	rax

	; zachowaj licznik
	push	rcx

	; system liczbowy
	mov	rcx,	16

	; wyświetl wartość
	call	cyjon_screen_print_number
	; przejdź do nastepnej linii
	mov	rsi,	text_paragraph
	call	cyjon_screen_print_string

	; przywróć licznik
	pop	rcx
	; kontynuuj z kolejnymi wartościami
	loop	.loop

	; wstrzymaj przełączanie procesów
	inc	qword [variable_multitasking_semaphore_process_table]

	; zatrzymaj dalsze wykonywanie kodu jądra
	jmp	$

text_cpu_exception	db	"Unhandled CPU exception! pages:", ASCII_CODE_TERMINATOR

;===============================================================================
; procedura podstawowej obsługi przerwania sprzętowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
itd_hardware_interrupt:
	; wyświetl informację
	mov	rbx,	COLOR_RED
	mov	rcx,	-1	; wyświetl całą informację
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	mov	rsi,	text_hardware_interrupt
	call	cyjon_screen_print_string	; plik: engine/screen.asm

	; wstrzymaj przełączanie procesów
	inc	qword [variable_multitasking_semaphore_process_table]

	; zatrzymaj dalsze wykonywanie kodu jądra
	jmp	$

text_hardware_interrupt	db	"Unhandled hardware interrupt!", ASCII_CODE_TERMINATOR

;===============================================================================
; procedura podstawowej obsługi przerwania programowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
itd_software_interrupt:
	; standardowo zastosuję zabicie procesu, który zrobił coś czego być był nie powinien

	; wyświetl informację
	mov	rbx,	COLOR_RED
	mov	rcx,	-1	; wyświetl całą informację
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	mov	rsi,	text_software_interrupt
	call	cyjon_screen_print_string	; plik: engine/screen.asm

	; wstrzymaj przełączanie procesów
	inc	qword [variable_multitasking_semaphore_process_table]

	; zatrzymaj dalsze wykonywanie kodu jądra
	jmp	$

text_software_interrupt	db	"Unhandled software interrupt!", ASCII_CODE_TERMINATOR

;===============================================================================
; procedura tworzy/modyfikuje rekord w Tablicy Deskryptorów Przerwań
; IN:
;	rax	- adres logiczny procesury obsługi wyjątku/przerwania
;	bx	- typ: wyjątek/przerwanie(sprzętowe/programowe)
;	rcx	- ilość kolejnych rekordów o tej samej procedurze obsługi
;	rdi	- adres logiczny rekordu w Tablicy Deskryptorów Przerawń do modyfikacji
; OUT:
;	rdi	- adres kolejnego rekordu w Tablicy Deskryptorów Przerwań
;
; pozostałe rejestry zachowane
recreate_record:
	; zachowaj oryginalny rejestr
	push	rcx

.next:
	; zachowaj adres procedury obsługi
	push	rax

	; załaduj do tablicy adres obsługi wyjątku (bity 15...0)
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; selektor deskryptora kodu (GDT)
	mov	ax,	0x0008
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; typ: wyjątek/przerwanie(sprzętowe/programowe)
	mov	ax,	bx
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; przywróć wartość zmiennej
	mov	rax,	qword [rsp]

	; przemieszczamy do ax bity 31...16 z rax
	shr	rax,	16
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; przemieszczamy do eax bity 63...32 z rax
	shr	rax,	16
	stosd	; zapisz zawartość rejestru EAX pod adres w rejestrze RDI, zwiększ rejestr RDI o 4 Bajty

	; pola zastrzeżone
	xor	eax,	eax
	stosd	; zapisz zawartość rejestru EAX pod adres w rejestrze RDI, zwiększ rejestr RDI o 4 Bajty

	; przywróć adres procedury obsługi
	pop	rax

	; utwórz pozostałe rekordy
	loop	.next

	; przywróć oryginalny rejestr
	pop	rcx

	; powrót z procedury
	ret
