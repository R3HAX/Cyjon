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

key_ctrl_push:
	; włącz flagę
	mov	byte [semaphore_ctrl],	0x01

	; koniec funkcji
	jmp	start.loop

key_ctrl_pull:
	; wyłącz flagę
	mov	byte [semaphore_ctrl],	0x00

	; koniec funkcji
	jmp	start.loop

; wskaźnik
semaphore_ctrl	db	0x00
