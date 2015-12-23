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

; 64 bitowy kod programu
[BITS 64]

VARIABLE_MOUSE_PS2_PORT_DATA		equ	0x60
VARIABLE_MOUSE_PS2_PORT_COMMAND		equ	0x64

VARIABLE_MOUSE_PS2_COMMAND_RESET	equ	0xFF
VARIABLE_MOUSE_PS2_RESPOND_ACK		equ	0xFA

variable_semaphore_mouse		db	0x00

mouse:
	mov	al,	VARIABLE_MOUSE_PS2_COMMAND_RESET
	mov	dx,	VARIABLE_MOUSE_PS2_PORT_COMMAND
	out	dx,	al

	mov	dx,	VARIABLE_MOUSE_PS2_PORT_DATA
	in	al,	dx

	cmp	al,	VARIABLE_MOUSE_PS2_RESPOND_ACK
	jne	.no_mouse

	mov	ecx,	4

.drop_status:
	in	al,	dx

	sub	ecx,	VARIABLE_DECREMENT
	jnz	.drop_status

	; myszka zainicjalizowana
	mov	byte [variable_semaphore_mouse],	VARIABLE_TRUE

.no_mouse:
	ret

; mouse IRQ12
irq43:
	xchg	bx,	bx

	iretq
