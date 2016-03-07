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

struc	HEADER
	.cpu	resb	1
	.video	resb	1
endstruc

; zestaw imiennych wartości stałych
%include	"config.asm"

;-------------------------------------------------------------------------------
; 32 bitowy kod jądra systemu
;-------------------------------------------------------------------------------
[BITS 32]

; położenie kodu jądra systemu w pamięci fizycznej/logicznej
[ORG VARIABLE_KERNEL_PHYSICAL_ADDRESS]

; NAGŁÓWEK =====================================================================
header:
	db	0x20	; 32 bitowy kod jądra systemu
	db	VARIABLE_FALSE	; tryb - tryb graficzny
	; todo: dodać obsługę wykrywania trybu graficznego włączonego
	; przez oprogramowanie GRUB, bo on ma prawo zignorować nasz nagłówek
; NAGŁÓWEK KONIEC ==============================================================

_start:
	; poinformuj jądro systemu o wykorzystaniu własnego programu rozruchowego
	mov	byte [variable_bootloader_own],	VARIABLE_TRUE

	; skocz do procedury przełączania procesora w tryb 64 bitowy
	jmp	entry

variable_bootloader_own	db	VARIABLE_EMPTY

%include	"engine/multiboot.asm"
%include	"engine/init.asm"

; rozpocznij 64 bitowy kod jądra systemu od pełnego adresu
align	0x08

;-------------------------------------------------------------------------------
; 64 bitowy kod jądra systemu
;-------------------------------------------------------------------------------
[BITS 64]

kernel:
	; ustaw deskryptory danych, ekstra i stosu
	mov	ax,	0x0010

	; podstawowe segmenty
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

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
	;call	mouse
	; przygotuj obsługę wyjątków i przerwań procesora, przerwań użyktownika
	call	interrupt_descriptor_table

	xchg	bx,	bx

	; włączamy przerwania i wyjątki procesora
	sti	; tchnij życie

	; włącz przerwania sprzętowe IRQ0 (planista), IRQ1 (klawiatura)
	mov	al,	11111111b	; irq15, irq14, irq13, mouse, irq11, irq10, irq9, irq8
	out	0xA1,	al
	mov	al,	11111100b	; irq7, irq6, sound, irq4, irq3, irq2, keyboard, sheduler/clock
	out	0x21,	al

	; resetuj karte dźwiękową SB16
	call	sound

	; szukaj karty sieciowej
	call	cyjon_network_i8254x_find_card

	; szukaj dysków sata
	call	cyjon_ahci_initialize

	; Qemu wykrzacza się na sterowniku IDE/ATA PIO, nie mam debugera - nie sprawdzę dlaczego
	; zatem wirtualny dysk będę podłączał pod AHCI/SATA, Bochs będzie obsługiwał IDE/ATA PIO
	; sprawdź czy znaleziono dysk pod kontrolerem AHCI/SATA
	cmp	byte [variable_ahci_semaphore],	VARIABLE_EMPTY
	ja	.ahci_found

	; zainicjalizuj dostęp do nośnika IDE0 Master
	call	ide_initialize

.ahci_found:
	; przygotuj wirtualne systemy plików (płaski system plików)
	; wirtualny system plików zostanie przygotowany na nowo (wzorem z ext2), aby mieć obsługe katalogów
	call	virtual_file_systems

	; załaduj do wirtualnego systemu plików, dołączone oprogramowanie
	call	move_included_files_to_virtual_filesystem

	; uruchom niezbędne demony
	call	daemon_init_disk_io	; dostęp do dysku twardego
	call	daemon_init_garbage_collector	; czyszczenie pamieci z zakończonych procesow
	call	daemon_init_dma	; obsługa trybu DMA

	; przeszukaj partycje na dysku za obsługiwanymi systemami plików
	call	check_partitions

	; oblicz rozmiar przestrzeni do zwolnienia w Bajtach
	mov	rdi,	kernel_end
	call	library_align_address_up_to_page

	mov	rcx,	rdi
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

	mov	rax,	2
	call	cyjon_page_allocate
	call	qword [variable_partition_interface_file_read]

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
%include	"engine/partitions.asm"

%include	"engine/daemon/garbage_collector.asm"
%include	"engine/daemon/disk_io.asm"
%include	"engine/daemon/dma.asm"

%include	"engine/drivers/pci.asm"
%include	"engine/drivers/ide.asm"
%include	"engine/drivers/ahci.asm"

%include	"engine/drivers/network/i8254x.asm"

%include	"engine/drivers/filesystem/kfs.asm"
%include	"engine/drivers/filesystem/ntfs.asm"
%include	"engine/drivers/filesystem/ext.asm"

%include	"library/align_address_up_to_page.asm"
%include	"library/find_free_bit.asm"
%include	"library/compare_string.asm"
%include	"library/find_first_word.asm"

%include	VARIABLE_FONT_MATRIX_DEFAULT

file_load_init		dq	4
file_load_init_pointer	db	"init"

; dołączone oprogramowanie wyrównaj do pełnego adresu strony, będzie można zwolnić na końcu inicjalizacji dodatkową przestrzeń dla 
align	0x1000

; poniższe strony pamięci zostaną zwolnione po przetworzeniu
release_memory:

%include	"software/internal.asm"

; wskaźnik końca kodu jądra wyrównaj do pełnego adresu strony
align	0x1000

; koniec kodu jądra systemu
kernel_end:
