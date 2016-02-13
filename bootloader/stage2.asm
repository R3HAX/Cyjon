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

%include	"config.asm"

; 16 Bitowy kod programu
[BITS 16]

; położenie kodu programu w pamięci fizycznej 0x0000:0x1000
[ORG 0x1000]

start:
	jmp	$
