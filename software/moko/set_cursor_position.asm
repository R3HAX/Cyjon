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

set_cursor:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx

	; ustaw kursor
	mov	ax,	0x0105
	mov	rbx,	qword [cursor_yx]
	int	0x40	; wykonaj

	; przywróć oryginalne rejestry
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
