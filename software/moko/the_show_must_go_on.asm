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

print:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8

	call	initialization.reload

	; ustaw kursor na początek ekranu dokumentu
	mov	rax,	0x0105
	mov	rbx,	0x0000000200000000
	int	0x40	; wykonaj

	; załaduj wskaźnik początku dokumentu
	mov	rsi,	qword [document_address_start]

	; ustaw kolor
	mov	rbx,	COLOR_DEFAULT
	; ustaw tło
	mov	rdx,	BACKGROUND_COLOR_DEFAULT

	; sprawdź czy wyświetlić zawartość pliku od samego początku
	cmp	qword [show_line],	0x0000000000000000
	je	.leave	; tak

	; szukaj linii od której zacząć wyświetlać
	mov	rcx,	qword [show_line]

.loop:
	; pobierz znak do al
	lodsb

	; znak nowej linii?
	cmp	al,	0x0A
	jne	.loop	; nie, szukaj dalej

	; tak, szukaj następnego znaku nowej linii
	loop	.loop

.leave:
	; wyświetl N linii dokumentu zaczynając od ustalownej "pierwszej"
	mov	ecx,	dword [screen_xy + 0x04]
	sub	rcx,	qword [interface_all_height]

	; licznik ilości znaków w linii
	xor	r8,	r8

.put:
	; załaduj znak do al
	lodsb

	and	ax,	0x00FF

	; koniec dokumentu?
	cmp	al,	0x00
	je	.end

	; znak nowej linii?
	cmp	al,	0x0A
	je	.enter

	; zliczaj wyświetlone znaki w linii
	inc	r8

	; wyświetl znak
	push	r8
	push	rcx
	mov	rbx,	COLOR_DEFAULT
	mov	r8,	rax
	mov	rcx,	1
	mov	ax,	0x0102
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	int	0x40	; wykonaj
	pop	rcx
	pop	r8

	; kontynuuj
	jmp	.put

.enter:
	; zachowaj oryginalne rejestry
	push	rcx

	; wyświetl spacje do końca linii
	mov	ecx,	dword [screen_xy]
	sub	rcx,	r8

	push	r8
	mov	rbx,	COLOR_DEFAULT
	mov	r8,	' '
	mov	ax,	0x0102
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	int	0x40	; wykonaj
	pop	r8

	; wyczyść licznik
	xor	r8,	r8

	; przywróć oryginalne rejestry
	pop	rcx

	; kontynuuj
	loop	.put

.end:


.the_end:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
