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

[BITS 64]
[DEFAULT REL]
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; wyczyść ekran
	mov	ax,	0x0100
	int	0x40	; wykonaj

	mov	ax,	0x0103
	xor	rbx,	rbx
	mov	rcx,	0x10
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

.loop:
	int	0x40

	inc	rbx
	inc	r8
	cmp	r8,	0xff
	jna	.loop

	xor	ax,	ax
	int	0x40
