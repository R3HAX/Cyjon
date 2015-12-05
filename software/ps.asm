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

struc VARIABLE_TABLE_SERPENTINE_RECORD
	.PID		resq	1
	.CR3		resq	1
	.RSP		resq	1
	.FLAGS		resq	1
	.NAME		resb	32
	.ARGS		resq	1
	.SIZE		resb	1
endstruc

STATIC_SERPENTINE_RECORD_FLAG_USED	equ	0	; rekord w serpentynie jest zajęty przez uruchomiony proces
STATIC_SERPENTINE_RECORD_FLAG_ACTIVE	equ	1	; proces bierze czynny udział w pracy systemu
STATIC_SERPENTINE_RECORD_FLAG_CLOSED	equ	2
STATIC_SERPENTINE_RECORD_FLAG_DAEMON	equ	3

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; oblicz adres za programem do pełnej strony
	mov	rdi,	end
	call	library_align_address_up_to_page

	; pobierz listę aktywnych procesów (prócz jądra systemu)
	mov	ax,	0x0004
	int	0x40

	; wyświetl nagłówek
	mov	rax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_header
	int	0x40

	; pobierz rozmiar rekordu
	mov	r9,	qword [rdi]

	; przejdź do pierwszego rekordu
	add	rdi,	0x08

.loop:
	push	rdi

	mov	bx,	STATIC_SERPENTINE_RECORD_FLAG_DAEMON
	bt	[rdi + 	VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	bx
	jnc	.color_default

	mov	ebx,	VARIABLE_COLOR_GRAY

	jmp	.color_ok

.color_default:
	mov	ebx,	VARIABLE_COLOR_DEFAULT

.color_ok:
	; wyświetl numer PID
	mov	ax,	0x0103
	mov	ecx,	10
	mov	r8,	qword [rdi]
	int	0x40

	push	rbx

	mov	ax,	0x0104
	int	0x40

	push	rbx
	mov	dword [rsp],	0x08
	pop	rbx

	mov	ax,	0x0105
	int	0x40

	pop	rbx
	mov	ax,	0x0101
	mov	rcx,	32	; maksymalna ilość znaków na nazwę procesu
	mov	rsi,	rdi
	add	rsi,	VARIABLE_TABLE_SERPENTINE_RECORD.NAME
	int	0x40

	mov	rsi,	text_paragraph
	int	0x40

	pop	rdi

	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY
	jne	.loop

	xor	ax,	ax
	int	0x40

%include	"library/align_address_up_to_page.asm"

text_header	db	"PID     PROCESS", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_paragraph	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

end:
