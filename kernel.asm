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

; zestaw imiennych wartości stałych
%include	"config.asm"

; 64 bitowy kod
[BITS 64]

; położenie kodu jądra systemu w pamięci logicznej/fizycznej
[ORG PHYSICAL_KERNEL_ADDRESS]

	; NAGŁÓWEK =============================================================
	db	0x40	; 64 bitowy kod jądra systemu
	; NAGŁÓWEK KONIEC ======================================================

start:
	; przygotuj podstawowe dane, niezbędne do wyświetlania informacji
	call	screen_initialization
	; przygotuj binarną mapę pamięci dla jądra systemu
	call	binary_memory_map
	; utwórz własną tablicę GDT
	call	global_descriptor_table
	; przygotuj nowe stronicowanie dla przestrzeni jądra systemu
	call	recreate_paging
	; mapuj przestrzeń pamięci ekranu pod nowe stronicowanie
	call	screen_initialization_reload

	; inicjalizacja pełnego środowiska jądra systemu gotowa

	; przemapuj numery przerwań sprzętowych pod 0x20..0x2F
	call	programmable_interrupt_controller
	; ustaw częstotliwość wywołań przerwania sprzętowego IRQ0
	call	programmable_interval_timer
	; dodaj jądro systemu do kolejki procesów
	call	multitasking
	; konfiguruj klawiature
	call	keyboard
	; przygotuj obsługę wyjątków i przerwań procesora, przerwań użyktownika
	call	interrupt_descriptor_table

	; włączamy przerwania i wyjątki procesora
	sti	; tchnij życie

	; włącz przerwania sprzętowe IRQ0 (planista), IRQ1 (klawiatura)
	mov	al,	11111111b
	out	0xa1,	al
	mov	al,	11111100b	; irq0, irq1
	out	0x21,	al

	; przygotuj wirtualne systemy plików (płaski system plików)
	; wirtualny system plików zostanie przygotowany na nowo (wzorem z ext2), aby mieć obsługe katalogów
	call	virtual_file_systems

	; załaduj do wirtualnego systemu plików, dołączone oprogramowanie
	call	save_included_files
	; oblicz rozmiar przestrzeni do zwolnienia w Bajtach
	mov	rcx,	end
	sub	rcx,	save_included_files
	; zamień na ilość stron zajętych
	shr	rcx,	12	; /4096

	; rozpocznij zwalnianie przestrzeni od adresu
	mov	rdi,	save_included_files

.loop:
	; call zwolnij stronę
	call	cyjon_page_release

	; zwolnij następną
	add	rdi,	0x1000

	; kontynuuj z pozostałymi
	loop	.loop

	; uruchom proces główny INIT
	mov	rcx,	qword [file_init_name_chars]	; ilość znaków nazwie pliku
	mov	rsi,	file_init_name	; wskaźnik do ciągu znaków reprezentujący nazwe pliku
	mov	r8,	variable_partition_specification_system	; z partycji systemowej
	call	cyjon_process_init	; wykonaj

	; pozostała część w trakcie przepisywania

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

%include	"engine/init/binary_memory_map.asm"
%include	"engine/init/global_descriptor_table.asm"
%include	"engine/init/paging.asm"

%include	"engine/database.asm"
%include	"engine/screen.asm"
%include	"engine/paging.asm"
%include	"engine/programmable_interrupt_controller.asm"
%include	"engine/programmable_interval_timer.asm"
%include	"engine/multitasking.asm"
%include	"engine/keyboard.asm"
%include	"engine/interrupt_descriptor_table.asm"
%include	"engine/virtual_file_system.asm"
%include	"engine/process.asm"
%include	"engine/services.asm"

%include	"engine/drivers/pci.asm"

%include	"library/align_address_up_to_page.asm"
%include	"library/find_free_bit.asm"
%include	"library/compare_string.asm"

%include	FONT_MATRIX_DEFAULT

; dołączone oprogramowanie wyrównaj do pełnego adresu strony, będzie można zwolnić przestrzeń dla innych
align	0x1000

;===============================================================================
;===============================================================================

; procedura zostanie usunięta z pamięci po wykonaniu
save_included_files:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; pliki załaduj do wirtualnego systemu plików
	mov	r8,	variable_partition_specification_system

	; plik shell
	mov	rcx,	qword [file_init_name_chars]	; ilość znaków w nazwie pliku
	; oblicz rozmiar pliku
	mov	rdx,	file_init_end
	sub	rdx,	file_init
	; poczatek kodu pliku
	mov	rdi,	file_init
	; ciąg znaków reprezentujący nazwe pliku
	mov	rsi,	file_init_name
	; zapisz
	call	cyjon_virtual_file_system_save_file

	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

file_init_name		db	'init'
file_init_name_chars	dq	5
file_init:		incbin	'init.bin'
file_init_end:

;===============================================================================
;===============================================================================

; etykiete końca kodu jądra wyrównaj do pełnego adresu strony
align	0x1000

; koniec kodu jądra systemu + oprogramowania
end:
