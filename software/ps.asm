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
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_LIST
	int	STATIC_KERNEL_SERVICE

	; wyświetl nagłówek
	mov	rax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_header
	int	STATIC_KERNEL_SERVICE

	; pobierz rozmiar rekordu
	mov	r9,	qword [rdi]

	; przejdź do pierwszego rekordu
	add	rdi,	VARIABLE_QWORD_SIZE

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
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	ecx,	10	; system dziesiętny
	mov	r8,	qword [rdi]
	int	STATIC_KERNEL_SERVICE

	push	rbx

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_GET
	int	STATIC_KERNEL_SERVICE

	push	rbx
	mov	dword [rsp],	0x08
	pop	rbx

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	int	STATIC_KERNEL_SERVICE

	pop	rbx
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rcx,	32	; maksymalna ilość znaków na nazwę procesu
	mov	rsi,	rdi
	add	rsi,	VARIABLE_TABLE_SERPENTINE_RECORD.NAME
	int	STATIC_KERNEL_SERVICE

	mov	rsi,	text_paragraph
	int	STATIC_KERNEL_SERVICE

	pop	rdi

	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	cmp	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY
	jne	.loop

	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

%include	"library/align_address_up_to_page.asm"

text_header	db	"PID     PROCESS", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_paragraph	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

end:
