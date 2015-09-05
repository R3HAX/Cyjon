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

key_enter:
	; załaduj do akumulatora znak nowej linii
	mov	al,	VARIABLE_ASCII_CODE_NEWLINE

	; sprawdź czy jest miejsce na nowy znak w dokumencie
	mov	rdi,	qword [document_address_start]
	add	rdi,	qword [document_chars_count]
	cmp	rdi,	qword [document_address_end]
	jb	.ok

	; rozszerz przestrzeń dokumentu o kolejną ramkę
	call	allocate_new_memory

.ok:
	; sprawdź czy jesteśmy na końcu dokumentu
	mov	rcx,	qword [cursor_position]
	cmp	rcx,	qword [document_chars_count]
	je	.at_end

	; przesuń całą zawartość dokumentu od miejsca wskaźnika o jeden znak do przodu

	; ustaw wskaźnik źródłowy
	mov	rsi,	rdi
	dec	rsi	; poprzedni znak

	; ustal ilość znaków do przesunięcia
	mov	rcx,	qword [document_chars_count]
	sub	rcx,	qword [cursor_position]

	; przesuń zawartość dokumenu o ustanowioną ilość znaków
	call	move_memory_up

.new_line:
	; zapisz znak nowej linii do dokumentu
	stosb

	; ustaw kursor na początku nowej linii
	mov	dword [cursor_yx],	0x00000000

	; czy kursor znajdował się w ostatniej linii na ekranie?
	mov	eax,	dword [screen_xy + 0x04]
	sub	rax,	qword [interface_height]
	cmp	dword [cursor_yx + 0x04],	eax
	jb	.move

	; zmień numer linii, od której wyświetlać dokument
	inc	qword [show_line]

	; wyczyść ostatnią linię
	mov	rax,	0x0101
	mov	rbx,	0xaaaaaa
	xor	rcx,	rcx	; wyświetl całą zawartość ciągu
	mov	rdx,	0
	mov	rsi,	text_clear_line
	int	0x40	; wykonaj

	; kontynuuj
	jmp	.update

.move:
	; przesuń kursora o jeden wiersz w dół
	inc	dword [cursor_yx + 0x04]

.update:
	; wyświetl nową zawartość dokumentu
	call	print

	; aktualizuj ozycje kursora na ekranie
	call	set_cursor

.end:
	; każdy klawisz entera to nowy znak w dokumencie
	inc	qword [document_chars_count]
	; koryguj wskaźnik kursora wewnątrz dokumentu
	inc	qword [cursor_position]
	; każdy klawisz entera to nowa linia
	inc	qword [document_lines_count]

	; oblicz ilość znaków w nowej linii
	mov	rsi,	rdi
	call	count_chars_in_line

	; zapisz
	mov	qword [line_chars_count],	rcx

	; koniec obsługi klawisza enter
	jmp	start.loop

.at_end:
	; zapisz znak na koniec dokumentu
	mov	rdi,	qword [document_address_start]
	add	rdi,	qword [cursor_position]

	; kontynuuj
	jmp	.new_line
