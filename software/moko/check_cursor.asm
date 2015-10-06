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

check_cursor:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx

	mov	ebx,	dword [variable_screen_size + 0x04]
	sub	rbx,	VARIABLE_INTERFACE_MENU_HEIGHT
	cmp	dword [variable_cursor_position + 0x04],	ebx
	jb	.check_column

	; kursor poza dozwolonym wierszem, korekta
	dec	dword [variable_cursor_position + 0x04]

.check_column:
	mov	rbx,	qword [variable_cursor_position]
	cmp	ebx,	dword [variable_screen_size]
	jb	.ok

	; kursor poza dozwoloną kolumną, korekta
	dec	dword [variable_cursor_position]
	dec	ebx
	inc	qword [variable_line_show_from_char]

.ok:
	; ustaw kursor
	mov	ax,	0x0105
	int	0x40	; wykonaj

	; przywróć oryginalne rejestry
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
