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

%define	KERNEL_VERSION			"0.442"

PHYSICAL_KERNEL_ADDRESS		equ	0x0000000000100000

HIGH_MEMORY_ADDRESS		equ	0xFFFF000000000000
REAL_HIGH_MEMORY_ADDRESS	equ	0xFFFF800000000000
VIRTUAL_HIGH_MEMORY_ADDRESS	equ	REAL_HIGH_MEMORY_ADDRESS - HIGH_MEMORY_ADDRESS
FREE_LOGICAL_MEMORY_ADDRESS	equ	0x0000400000000000	; adres umowny, jest to przestrzeń gdzie jądro systemu może operować na różnej wielkości fragmentach pamięci logicznej, gdzie pamięć fizyczna nie sięga

KERNEL_STACK_ADDRESS		equ	VIRTUAL_HIGH_MEMORY_ADDRESS - 0x1000

ASCII_CODE_TERMINATOR		equ	0x00
ASCII_CODE_ENTER		equ	0x0D
ASCII_CODE_NEWLINE		equ	0x0A
ASCII_CODE_BACKSPACE		equ	0x08

COLOR_DEFAULT			equ	0x00AAAAAA
BACKGROUND_COLOR_DEFAULT	equ	0x00202020
COLOR_WHITE			equ	0x00FFFFFF
COLOR_GREEN			equ	0x001CC76A
COLOR_BLUE			equ	0x00267BE6
COLOR_RED			equ	0x00E62626

%define	FONT_MATRIX_DEFAULT	"font/sinclair.asm"

PCI_CONFIG_ADDRESS		equ	0x0CF8
PCI_CONFIG_DATA			equ	0x0CFC

PIT_CLOCK			equ	1000	; Hz

KEYBOARD_CACHE_SIZE		equ	16
