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

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]	

start:
	; program kończy działanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

%include	"library/window_message_info.asm"

variable_message_info_specification	times	WINDOW_MESSAGE_INFO.structure_size	db	VARIABLE_EMPTY
