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

; rozpocznij tablicę Multiboot od pełnego adresu
align	0x04

multiboot_header:
	dd	VARIABLE_MULTIBOOT_HEADER_MAGIC
	dd	VARIABLE_MULTIBOOT_HEADER_FLAGS
	dd	VARIABLE_MULTIBOOT_HEADER_CHECKSUM

	dd	multiboot_header
	dd	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	dd	VARIABLE_EMPTY
	dd	VARIABLE_EMPTY
	dd	entry
