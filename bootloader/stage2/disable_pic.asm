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

; 16 Bitowy kod programu
[BITS 16]

stage2_disable_pic:
	; wyłączamy wszystkie przerwania sprzętowe (PIC)
	mov	al,	11111111b
	out	0xA1,	al
	out	0x21,	al

	; powrót z procedury
	ret
