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

key_function_exit:
	; sprawdź czy plik był modyfikowany
	cmp	byte [semaphore_modified],	0x00
	je	.now

;	; poinformuj procedure zapisu, o zakończeniu działania programu
;	mov	byte [semaphore_exit],	0x01
;
;	; ustaw kursor w wierszu informacyjnym
;	mov	ax,	0x0105
;	mov	ebx,	dword [screen_xy + 0x04]
;	dec	ebx
;	sub	ebx,	dword [interface_menu_height]
;	shl	rbx,	32
;	push	rbx	; zapamiętaj
;	int	0x40	; wykonaj
;
;	; zmień kolor linii zapytań
;	mov	ax,	0x0102
;	mov	rbx,	BACKGROUND_COLOR_DEFAULT
;	mov	ecx,	dword [screen_xy]	; szerokość ekranu w znakach
;	mov	r8,	' '	; spacja
;	mov	rdx,	COLOR_DEFAULT
;	int	0x40	; wykonaj
;
;	; ustaw kursor w wierszu informacyjnym
;	mov	ax,	0x0105
;	mov	rbx,	qword [rsp]
;	int	0x40	; wykonaj
;
;	; wyświetl zapytanie
;	mov	ax,	0x0101
;	mov	rbx,	BACKGROUND_COLOR_DEFAULT
;	mov	rcx,	-1	; wyświetl pełny ciąg znaków, zakończony terminatorem
;	mov	rdx,	COLOR_DEFAULT
;	mov	rsi,	text_save_changes
;	int	0x40	; wykonaj
;
;.loop:
;	; pobierz znak z bufora klawiatury
;	mov	ax,	0x0200
;	int	0x40	; wykonaj
;
;	; czekaj na odpowiedź
;	cmp	ax,	0x0000
;	je	.loop
;
;	; sprawdź nie zapisywać
;	cmp	ax,	"n"
;	je	.now
;
;	; sprawdź czy zapisać
;	cmp	ax,	"y"
;	je	key_function_save
;
;	; sprawdź czy zapisać
;	cmp	ax,	0x000D	; enter
;	je	key_function_save
;
;	; czekaj na odpowiedź
;	jmp	.loop

.now:
	; przesuń kursor na koniec ekranu
	mov	ax,	0x0105
	mov	ebx,	dword [screen_xy + 0x04]
	dec	ebx
	shl	rbx,	32
	int	0x40	; wykonaj

	mov	ax,	0x0101
	mov	rbx,	COLOR_DEFAULT
	mov	rcx,	-1	; wyświetl pełny ciąg znaków, zakończony terminatorem
	mov	rdx,	BACKGROUND_COLOR_DEFAULT
	mov	rsi,	text_new_line
	int	0x40	; wykonaj

	; seppuku
	xor	rax,	rax
	int	0x40	; wykonaj

semaphore_exit	db	0x00

text_save_changes	db	'Save the changes? (Y/n)', ASCII_CODE_TERMINATOR
