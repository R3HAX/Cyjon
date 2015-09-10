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

	; zachowaj licznik elementów
	push	rcx

	; wyświetl nagłówek
	mov	rax,	0x0101
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_header
	int	0x40

	; przywróć licznik
	pop	rcx

	; pobierz rozmiar rekordu
	mov	r9,	qword [rdi]
	; przejdź do piwerszego rekordu
	add	rdi,	0x08

.loop:
	push	rdi

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
	mov	rcx,	-1
	mov	rsi,	rdi
	add	rsi,	0x08
	int	0x40

	mov	rsi,	text_paragraph
	int	0x40

	pop	rdi

	add	rdi,	r9

	cmp	qword [rdi],	VARIABLE_EMPTY
	jne	.loop

	xor	ax,	ax
	int	0x40

%include	"library/align_address_up_to_page.asm"

text_header	db	"PID     PROCESS", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_paragraph	db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

end:
