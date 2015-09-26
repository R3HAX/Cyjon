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
[ORG VARIABLE_KERNEL_PHYSICAL_ADDRESS]

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
	out	0xA1,	al
	mov	al,	11111100b	; irq0, irq1
	out	0x21,	al

	; przygotuj wirtualne systemy plików (płaski system plików)
	; wirtualny system plików zostanie przygotowany na nowo (wzorem z ext2), aby mieć obsługe katalogów
	call	virtual_file_systems

	; uruchom niezbędne demony
	call	daemon_init_garbage_collector

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
%include	"engine/interrupt_descriptor_table.asm"
%include	"engine/virtual_file_system.asm"
%include	"engine/process.asm"
%include	"engine/services.asm"

%include	"engine/daemon/garbage_collector.asm"

%include	"engine/drivers/pci.asm"

%include	"library/align_address_up_to_page.asm"
%include	"library/find_free_bit.asm"
%include	"library/compare_string.asm"

%include	VARIABLE_FONT_MATRIX_DEFAULT

file_load_init		dq	4
file_load_init_pointer	dq	"init"

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

	; wskaźnik do tablicy plików
	mov	rsi,	files_table

.loop:
	; koniec tablicy?
	cmp	qword [rsi],	VARIABLE_EMPTY
	je	.end	; tak

	; zachowaj wskaźnik
	push	rsi

	; pobierz ilość znaków w nazwie pliku
	mov	rcx,	qword [rsi]

	; pobierz rozmiar pliku
	mov	rdx,	qword [rsi + 0x08]

	; ustaw wskaźnik na początek danych pliku
	mov	rdi,	qword [rsi + 0x10]

	; ustaw wskaźnik na nazwę pliku
	add	rsi,	0x20

	; zapisz do wirtualnego systemu plików
	call	cyjon_virtual_file_system_save_file

	; przywróć wskaźnik
	pop	rsi

	; przesuń na następny rekord
	add	rsi,	0x20
	add	rsi,	rcx

	; kontynuuj z pozostałymi plikami
	loop	.loop

.end:
	; wyświetl informacje o inicjalizacji wirtulnego systemu plików
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_virtial_file_system
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

files_table:
	; plik
	dq	4				; ilość znaków w nazwie pliku
	dq	file_init_end - file_init	; rozmiar pliku w Bajtach
	dq	file_init			; wskaźnik początku pliku
	dq	file_init_end			; wskaźnik końca pliku
	db	'init'				; nazwa pliku

	dq	5
	dq	file_shell_end - file_shell
	dq	file_shell
	dq	file_shell_end
	db	'shell'

	dq	5
	dq	file_login_end - file_login
	dq	file_login
	dq	file_login_end
	db	'login'

	dq	4
	dq	file_help_end - file_help
	dq	file_help
	dq	file_help_end
	db	'help'

	dq	6
	dq	file_uptime_end - file_uptime
	dq	file_uptime
	dq	file_uptime_end
	db	'uptime'

	dq	4
	dq	file_moko_end - file_moko
	dq	file_moko
	dq	file_moko_end
	db	'moko'

	dq	2
	dq	file_ps_end - file_ps
	dq	file_ps
	dq	file_ps_end
	db	'ps'

	dq	4
	dq	file_date_end - file_date
	dq	file_date
	dq	file_date_end
	db	'date'

	; koniec tablicy plików
	dq	VARIABLE_EMPTY

file_init:		incbin	'init.bin'
file_init_end:

file_shell:		incbin	'shell.bin'
file_shell_end:

file_login:		incbin	'login.bin'
file_login_end:

file_help:		incbin	'help.bin'
file_help_end: 

file_uptime:		incbin	'uptime.bin'
file_uptime_end:

file_moko:		incbin	'moko.bin'
file_moko_end:

file_ps:		incbin	'ps.bin'
file_ps_end:

file_date:		incbin	'date.bin'
file_date_end:

text_virtial_file_system	db	" Virtual file system initialized.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

;===============================================================================
;===============================================================================

; etykiete końca kodu jądra wyrównaj do pełnego adresu strony
align	0x1000

; koniec kodu jądra systemu + oprogramowania
end:
