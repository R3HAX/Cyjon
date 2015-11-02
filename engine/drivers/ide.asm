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

STATIC_IDE_PRIMARY	equ	0x01F0
STATIC_IDE_SECONDARY	equ	0x03F0

STATIC_IDE_MASTER	equ	0x40
STATIC_IDE_SLAVE	equ	0x50

STATIC_IDE_READ		equ	0x24
STATIC_IDE_WRITE	equ	0x34

struc	IDE_PORT
	.DATA		resb	1
	.FEATURES	resb	1
	.COUNTER	resb	1
	.LBA_LOW	resb	1
	.LBA_MIDDLE	resb	1
	.LBA_HIGH	resb	1
	.DRIVE		resb	1
	.COMMAND	resb	1
endstruc

; 64 Bitowy kod programu
[BITS 64]

cyjon_ide_sector_read:
	; zachowaj modyfikowane rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi

	call	cyjon_ide_lba

	; dysk pierwszy czy drugi?
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.DRIVE
	mov	al,	STATIC_IDE_MASTER
	out	dx,	al

	; wyślij polecenie odczytu sektora
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.COMMAND
	mov	al,	STATIC_IDE_READ
	out	dx,	al

	; dx = 0x1F7
	call	cyjon_ide_check_ready	; sprawdź gotowość nośnika

	; odczytaj dane z portu bufora dysku
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.DATA	; port wejścia/wyjścia kontrolera IDE0
	mov	rcx,	256	; 256 słów, 1 sektor, 512 Bajtów
	rep	insw	; zapisz ax w word [es:rdi], zwiększ rdi o 2, jeśli rcx > 0 powtórz raz jeszcze

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

cyjon_ide_sector_write:
	; zachowaj modyfikowane rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi

	call	cyjon_ide_lba

	; dysk pierwszy czy drugi?
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.DRIVE
	mov	al,	STATIC_IDE_MASTER
	out	dx,	al

	; wyślij polecenie odczytu sektora
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.COMMAND
	mov	al,	STATIC_IDE_WRITE
	out	dx,	al

	; dx = 0x1F7
	call	cyjon_ide_check_ready	; sprawdź gotowość nośnika

	; odczytaj dane z portu bufora dysku
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.DATA	; port wejścia/wyjścia kontrolera IDE0
	mov	rcx,	256	; 256 słów, 1 sektor, 512 Bajtów
	rep	outsw

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

cyjon_ide_lba:
	; zachowaj
	mov	rbx,	rax

	; pierwszy pusty Bajt
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.FEATURES
	mov	al,	0x00
	out	dx,	al

	; starsza część ilości odczytywanych sektorów
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.COUNTER
	mov	al,	0x00
	out	dx,	al

	; drugi pusty Bajt
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.FEATURES
	mov	al,	0x00
	out	dx,	al

	; młodsza część ilości odczytywanych sektorów
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.COUNTER
	mov	al,	0x01
	out	dx,	al

	; wyślij 48 bitowy numer sektora

	; al = 31..24
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.LBA_LOW
	mov	rax,	rbx
	shr	rax,	24
	out	dx,	al

	; al = 39..32
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.LBA_MIDDLE
	mov	rax,	rbx
	shr	rax,	32
	out	dx,	al

	; al = 47..40
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.LBA_HIGH
	mov	rax,	rbx
	shr	rax,	40
	out	dx,	al

	; al = 7..0
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.LBA_LOW
	mov	rax,	rbx
	out	dx,	al

	; al = 15..8
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.LBA_MIDDLE
	mov	al,	bh
	out	dx,	al

	; al = 23..16
	mov	dx,	STATIC_IDE_PRIMARY + IDE_PORT.LBA_HIGH
	mov	rax,	rbx
	shr	rax,	16
	out	dx,	al

	ret

cyjon_ide_check_ready:
	in	al,	dx	; pobierz stan dysku
	test	al,	8	; czy 8 bit włączony?
	jz	cyjon_ide_check_ready	; jeśli nie, czekaj

	; powrót z procedury
	ret
