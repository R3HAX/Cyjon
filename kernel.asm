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


%include	"library/align_address_up_to_page.asm"
%include	"library/find_free_bit.asm"

%include	FONT_MATRIX_DEFAULT

; koniec kodu jądra systemu
end:
