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

; zestaw imiennych wartości stałych
%include	"config.asm"

; 64 bitowy kod
[BITS 64]

; położenie kodu jądra systemu w pamięci logicznej/fizycznej
[ORG VARIABLE_KERNEL_PHYSICAL_ADDRESS]

struc	HEADER
	.cpu	resb	1
	.video	resb	1
endstruc

header:
	; NAGŁÓWEK =============================================================
	db	0x40	; 64 bitowy kod jądra systemu
	db	VARIABLE_FALSE	; true - tryb graficzny
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
	; skonfiguruj myszke PS2
	call	mouse
	; przygotuj obsługę wyjątków i przerwań procesora, przerwań użyktownika
	call	interrupt_descriptor_table

	; włączamy przerwania i wyjątki procesora
	sti	; tchnij życie

	; włącz przerwania sprzętowe IRQ0 (planista), IRQ1 (klawiatura)
	mov	al,	11101111b	; irq15, irq14, irq13, mouse, irq11, irq10, irq9, irq8
	out	0xA1,	al
	mov	al,	11011100b	; irq7, irq6, sound, irq4, irq3, irq2, keyboard, sheduler/clock
	out	0x21,	al

	; resetuj karte dźwiękową SB16
	call	sound

	; zainicjalizuj dostęp do nośnika IDE0 Master
	call	ide_initialize

	; przygotuj wirtualne systemy plików (płaski system plików)
	; wirtualny system plików zostanie przygotowany na nowo (wzorem z ext2), aby mieć obsługe katalogów
	call	virtual_file_systems

	; uruchom niezbędne demony
	call	daemon_init_disk_io
	call	daemon_init_garbage_collector

	; inizjalizuj system plików
	mov	rax,	2048
	mov	rcx,	1	; rozmiar superbloku, 1 blok
	mov	r8,	variable_partition_specification_home
	call	cyjon_filesystem_kfs_initialization

	; utwórz plik readme.txt w głównym systemie plików /
	call	create_readme

	; załaduj do wirtualnego systemu plików, dołączone oprogramowanie
	call	move_included_files_to_virtual_filesystem

	; oblicz rozmiar przestrzeni do zwolnienia w Bajtach
	mov	rcx,	end
	sub	rcx,	release_memory
	; zamień na ilość stron zajętych
	shr	rcx,	12	; /4096

	; rozpocznij zwalnianie przestrzeni od adresu
	mov	rdi,	release_memory

.loop:
	; zwolnij zajętą przestrzeń
	call	cyjon_page_release
	add	rdi,	VARIABLE_MEMORY_PAGE_SIZE
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop

	; uruchom proces główny INIT
	mov	rcx,	qword [file_load_init]	; ilość znaków nazwie pliku
	mov	rsi,	file_load_init_pointer	; wskaźnik do ciągu znaków reprezentujący nazwe pliku
	mov	r8,	variable_partition_specification_system	; z partycji systemowej
	call	cyjon_process_init	; wykonaj

	; nie potrzebujemy pamiętać numeru PID procesu init
	mov	qword [variable_process_pid],	VARIABLE_EMPTY

%include	"engine/alive.asm"

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
%include	"engine/mouse.asm"
%include	"engine/sound.asm"
%include	"engine/interrupt_descriptor_table.asm"
%include	"engine/virtual_file_system.asm"
%include	"engine/process.asm"
%include	"engine/services.asm"

%include	"engine/daemon/garbage_collector.asm"
%include	"engine/daemon/disk_io.asm"

%include	"engine/drivers/pci.asm"
%include	"engine/drivers/ide.asm"

%include	"engine/drivers/filesystem/kfs.asm"

%include	"library/align_address_up_to_page.asm"
%include	"library/find_free_bit.asm"
%include	"library/compare_string.asm"

%include	VARIABLE_FONT_MATRIX_DEFAULT

file_load_init		dq	4
file_load_init_pointer	db	"init"

; dołączone oprogramowanie wyrównaj do pełnego adresu strony, będzie można zwolnić na końcu inicjalizacji dodatkową przestrzeń dla 
align	0x1000

release_memory:

%include	"software/internal.asm"

; koniec kodu jądra systemu + oprogramowania
end:
