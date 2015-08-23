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

allocate_new_memory:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; załaduj do wskaźnika aktualny koniec dokumentu
	mov	rdi,	qword [document_address_end]

	; dodaj do przestrzeni dokumentu jedną ramkę (4096 Bajtów == 1 ramka)
	mov	rcx,	1	; 1x4096

	; zarezerwuj miejsce (rejestracja w tablicy stronicowania programu)
	mov	ax,	0x0003
	int	0x40	; wykonaj

	; przesuń adres wskaźnika końca przestrzeni dokumentu o jedną ramkę do przodu
	add	qword [document_address_end],	0x1000

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
