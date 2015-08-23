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

key_home:
	; pobierz pozycje kursora - kolumna
	mov	ecx,	dword [cursor_yx]

	; przesuń wskaźnik kursora wewnątrz przestrzeni dokumentu na pocżatek aktualnej linii
	sub	qword [cursor_position],	rcx

	; ustaw pozycje kursora na poczatek linii (kolumna 0)
	mov	dword [cursor_yx],	0

	; przestaw fizyczny kursor w odpowiednie miejsce
	call	set_cursor

	; koniec funkcji
	jmp	start.loop
