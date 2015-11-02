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

[BITS 64]

key_ctrl_push:
	mov	byte [variable_semaphore_key_ctrl],	VARIABLE_TRUE

	jmp	start.noKey

key_ctrl_pull:
	mov	byte [variable_semaphore_key_ctrl],	VARIABLE_FALSE

	jmp	start.noKey
