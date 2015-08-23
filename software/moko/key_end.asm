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

key_end:
	; pobierz rozmiar edytowanej linii
	mov	rcx,	qword [line_chars_count]

	; oblicz ilość znaków pozostałych do końca linii
	sub	ecx,	dword [cursor_yx]

	; przesuń wskaźnik kursora wewnątrz przestrzeni dokumentu na koniec aktualnej linii
	add	qword [cursor_position],	rcx

	; ustaw pozycje kursora na koniec linii
	add	dword [cursor_yx],	ecx

	; przestaw fizyczny kursor w odpowiednie miejsce
	call	set_cursor

	; koniec funkji
	jmp	start.loop
