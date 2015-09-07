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

[DEFAULT REL]
[BITS 64]
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	mov	rax,	1
	mov	rbx,	2
	mov	rcx,	3
	mov	rdx,	4
	mov	rcx,	0
	mov	rbp,	5
	mov	rsi,	6
	mov	rdi,	7
	mov	r8,	9
	mov	r9,	10
	mov	r10,	11
	mov	r11,	12
	mov	r12,	13
	mov	r13,	14
	mov	r14,	15
	mov	r15,	16

	; ups!
	div	rcx
