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

save_into_document:
	; sprawdź czy zmieścimy w linii kojelny znak
	movzx	rcx,	byte [screen_xy]
	dec	rcx
	cmp	byte [line_chars_count],	cl
	je	start.loop	; brak miejsca, limit znaków na linie

	; sprawdź czy znak zapisać na końcu dokumentu
	mov	rdi,	qword [cursor_position]
	cmp	rdi,	qword [document_chars_count]
	je	.document_end

	; utwórz miejsce na znak w dokumencie --------------------------
	; czyli, przesuń zawartość dokumentu od pozycji kursora w dokumencie o jedną pozycję do przodu

	; ustaw wskaźnik docelowy
	mov	rdi,	qword [document_address_start]
	add	rdi,	qword [document_chars_count]
	; ustaw wskaźnik źródłowy
	mov	rsi,	rdi
	dec	rsi	; znak z poprzedniej pozycji skopiuj do aktualnej

	; ustaw rozmiar dokumentu w znakach za pozycją kursora w dokumencie
	mov	rcx,	qword [document_chars_count]
	sub	rcx,	qword [cursor_position]

	; przesuń zawartość dokumenu o ustanowioną ilość znaków
	call	move_memory_up

	; miejsce dla znaku zostało utworzone, zachowaj w dokumencie
	jmp	.space

.document_end:
	; przesuń wskaźnik na pozycje do zapisania znaku
	add	rdi,	qword [document_address_start]

	; sprawdź czy jest miejsce
	cmp	rdi,	qword [document_address_end]
	jb	.space

	; rozszerz przestrzeń dokumentu o kolejne 4096 Bajtów/stronę
	call	allocate_new_memory

.space:
	; zapisz znak do przestrzeni dokumentu w ustalone miejsce
	stosb

	; zachowaj informacje o zmodyfikowanym dokumencie
	mov	byte [semaphore_modified],	0x01

.end:
	; zwiększ ilość znaków przechowywanych w dokumencie
	inc	qword [document_chars_count]

	; przesuń aktualną pozycję w dokumencie na następną wolną pozycję
	inc	qword [cursor_position]

	; zwiększ ilość znaków przechowywanych w aktualnej linii
	inc	qword [line_chars_count]

	; wyświetl zaaktualizowaną zawartość dokumentu
	call	print

	; przesuń kursor w prawo
	inc	byte [cursor_yx]

	; wyświetl nową pozycję kursora
	call	set_cursor

	; powrót z procedury
	jmp	start.loop

modified:
	; zachowaj znak ASCII
	push	rax
	push	rbx
	push	rcx
	push	rsi

	; ustaw kursora w polu informacyjnym nagłówka
	mov	ax,	0x0105
	xor	bx,	bx
	mov	ebx,	dword [screen_xy]
	sub	ebx,	10 + 1	; ilość znaków w ciągu + odstęp
	int	0x40	; wykonaj

	; wyświetl informację
	mov	ax,	0x0101
	mov	rbx,	VARIABLE_COLOR_BACKGROUND_DEFAULT	; czcionka
	mov	rcx,	-1	; wyświetl całą zawartość ciągu
	mov	rdx,	VARIABLE_COLOR_DEFAULT	; tło
	mov	rsi,	text_file_modified
	int	0x40	; wykonaj

	; ustaw kursor na swoją pozycję
	call	set_cursor

	; przywróć znak ASCII
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

semaphore_modified		db	VARIABLE_EMPTY
text_file_modified	db	'[modified]', VARIABLE_ASCII_CODE_TERMINATOR
