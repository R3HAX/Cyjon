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

; 64 bitowy kod programu
[BITS 64]

variable_keyboard_semaphore				db	0x00

variable_keyboard_key_special				db	0x00
variable_keyboard_matrix_active				dq	0x0000000000000000

variable_keyboard_matrix_low				db	0x00, 0x1B, "1234567890-=", 0x08, 0x09, "qwertyuiop[]", 0x0D, 0x1D, "asdfghjkl;", "'", "`", 0x00, "\", "zxcvbnm,./", 0x00, 0x00, 0x00, " ", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, "789-456+1230", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
							db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
variable_keyboard_matrix_high				db	0x00, 0x1B, "!@#$%^&*()_+", 0x08, 0x09, "QWERTYUIOP{}", 0x0D, 0x1D, "ASDFGHJKL:", '"', "~", 0x00, "|", "ZXCVBNM<>?", 0x00, 0x00, 0x00, " ", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, "789-456+1230", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
							db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

variable_keyboard_cache	times	KEYBOARD_CACHE_SIZE	dw	0x0000	; bufor
variable_keyboard_cache_keys				db	0x00

;===============================================================================
; procedura ustawia domyślną macierz klawiszy (małe znaki)
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
keyboard:
	; zachowaj oryginalne rejestry
	push	rax

	; ustaw standardową macierz klawiatury
	mov	rax,	variable_keyboard_matrix_low
	mov	qword [variable_keyboard_matrix_active],	rax

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura zapisuje pobrany/zmodyfikowany kod klawisza ASCII z klawiatury do bufora programowego klawiatury
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
keyboard_key_save:
	; sprawdź dostępność miejsca w programowalnym buforze klawiatury
	cmp	byte [variable_keyboard_cache_keys],	KEYBOARD_CACHE_SIZE - 1
	je	.end	; brak miejsca, zignoruj klawisz

	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; załaduj adres bufora programowego klawiatury
	mov	rsi,	variable_keyboard_cache

	; załaduj wskaźnik pozycji następnego wolnego miejsca w buforze programowym klawiatury
	movzx	rcx,	byte [variable_keyboard_cache_keys]
	shl	rcx,	1	; każdy rekord/klawisz zajmuje 2 Bajty

	; zapisz znak do bufora programowego klawiatury
	mov	word [rsi + rcx],	ax

	; zwięsz ilość znaków ASCII przechowywanych w buforze programowym klawiatury
	inc	byte [variable_keyboard_cache]

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

.end:
	; powrót z procedury
	ret

;===============================================================================
; procedura przełącza macierz klawiatury przy naciśnięciu/puszczeniu klawisza SHIFT
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
keyboard_key_shift:
	; lewy naciśnięty
	cmp	al,	0x2A
	je	.press

	; prawy naciśnięty
	cmp	al,	0x36
	je	.press

	; lewy puszczony
	cmp	al,	0x2A + 0x80
	je	.release

	; prawy puszczony
	cmp	al,	0x36 + 0x80
	je	.release

	; powrót z procedury
	ret

.press:
	; ustaw macierz drugą jako domyślną
	mov	rax,	variable_keyboard_matrix_high
	mov	qword [variable_keyboard_matrix_active],	rax

	; zapisz do bufora informacje o naciśnięciu klawisza SHIFT
	mov	ax,	0x8000	; lewy lub prawy (0x8001 prawy)
	call	keyboard_key_save

	; zakończ obsługę przerwania sprzetowego klawiatury
	add	rsp,	0x08	; usuń adres powrotu z procedury

	; kontynuuj
	jmp	irq33.end

.release:
	; ustaw macież pierwszą jako domyślną
	mov	rax,	variable_keyboard_matrix_low
	mov	qword [variable_keyboard_matrix_active],	rax

	; zapisz do bufora informacje o naciśniętym klawiszu SHIFT
	mov	ax,	0xB000	; lewy lub prawy (0xB001 prawy)
	call	keyboard_key_save

	; zakończ obsługę przerwania sprzetowego klawiatury
	add	rsp,	0x08	; usuń adres powrotu z procedury

	; kontynuuj
	jmp	irq33.end

;===============================================================================
; procedura pobiera z bufora programowego klawiatury zachowany pierwszy klawisz
; IN:
;	brak
; OUT:
;	ax - kod ASCII klawisza, lub ZERO jeśli bufor pusty
;
; pozostałe rejestry zachowane
cyjon_keyboard_key_read:
	; wyczyść wynik operacji
	xor	rax,	rax

	; sprawdź czy bufor programowy klawiatury zawiera klawisze
	cmp	byte [variable_keyboard_cache_keys],	0x00
	je	.end

	; zachowaj oryginalne rejestry
	push	rdx
	push	rsi

	; pobierz kod ASCII z bufora programowego klawiatury
	mov	ax,	word [variable_keyboard_cache]

	; usuń znak z bufora programowego klawiatury
	mov	rdx,	qword [variable_keyboard_cache + 0x02]
	mov	qword [variable_keyboard_cache],	rdx
	mov	rdx,	qword [variable_keyboard_cache + 0x0A]
	mov	qword [variable_keyboard_cache + 0x08],	rdx

	; zmniejsz ilość znaków przechowywanych w buforze programowym klawiatury
	dec	byte [variable_keyboard_cache_keys]

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx

.end:
	; powrót z procedury
	ret

;===============================================================================
; procedura obsługuje przerwanie sprzętowe klawiatury, zachowując informacje o naciśniętych klawiszach
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
irq33:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; pobierz kod klawisza z bufora sprzętowego klawiatury
	xor	rax,	rax	; wyczyść cały akumulator
	in	al,	0x60

	; sprawdź czy zmienić typ macierzy
	call	keyboard_key_shift

	; sprawdź czy naciśnięto klawisz specjalny
	cmp	al,	0xE0
	jne	.no_special	; nie

	; ustaw flagę
	mov	byte [variable_keyboard_key_special],	0x01

	; koniec
	jmp	.end

.no_special:
	; sprawdź czy specjalny kod klawisza
	cmp	byte [variable_keyboard_key_special],	0x00
	je	.no

	; wyłącz flagę
	mov	byte [variable_keyboard_key_special],	0x00

	; naciśnięcie klawisza strzałki w lewo?
	cmp	al,	0x4B
	je	.strzalka_w_lewo_nacisniecie

	; puszczenie klawisza strzałki w lewo?
	cmp	al,	0x4B + 0x80
	je	.strzalka_w_lewo_puszczenie

	; naciśnięcie klawisza strzałki w prawo?
	cmp	al,	0x4D
	je	.strzalka_w_prawo_nacisniecie

	; puszczenie klawisza strzałki w prawo?
	cmp	al,	0x4D + 0x80
	je	.strzalka_w_prawo_puszczenie

	; naciśnięcie klawisza strzałki w górę?
	cmp	al,	0x48
	je	.strzalka_w_gore_nacisniecie

	; puszczenie klawisza strzałki w górę?
	cmp	al,	0x48 + 0x80
	je	.strzalka_w_gore_puszczenie

	; naciśnięcie klawisza strzałki w dół?
	cmp	al,	0x50
	je	.strzalka_w_dol_nacisniecie

	; puszczenie klawisza strzałki w dół?
	cmp	al,	0x50 + 0x80
	je	.strzalka_w_dol_puszczenie

	; naciśnięcie prawego klawisza CTRL
	cmp	al,	0x1D
	je	.prawy_klawisz_ctrl_nacisniecie

	; puszczenie prawego klawisza CTRL
	cmp	al,	0x1D + 0x80
	je	.prawy_klawisz_ctrl_puszczenie

	; naciśnięcie klawisza End
	cmp	al,	0x4F
	je	.klawisz_end_nacisniecie

	; puszczenie klawisza End
	cmp	al,	0x4F + 0x80
	je	.klawisz_end_puszczenie

	; naciśnięcie klawisza Home
	cmp	al,	0x47
	je	.klawisz_home_nacisniecie

	; puszczenie klawisza Home
	cmp	al,	0x47 + 0x80
	je	.klawisz_home_puszczenie

	; naciśnięcie klawisza Delete
	cmp	al,	0x53
	je	.klawisz_delete_nacisniecie

	; puszczenie klawisza Delete
	cmp	al,	0x53 + 0x80
	je	.klawisz_delete_puszczenie

	; naciśnięcie klawisza PageUp
	cmp	al,	0x49
	je	.klawisz_pageup_nacisniecie

	; puszczenie klawisza PageUp
	cmp	al,	0x49 + 0x80
	je	.klawisz_pageup_puszczenie

	; naciśnięcie klawisza PageDown
	cmp	al,	0x51
	je	.klawisz_pagedown_nacisniecie

	; puszczenie klawisza PageDown
	cmp	al,	0x51 + 0x80
	je	.klawisz_pagedown_puszczenie

	; naciśnięcie klawisza Insert
	cmp	al,	0x52
	je	.klawisz_insert_nacisniecie

	; puszczenie klawisza Insert
	cmp	al,	0x52 + 0x80
	je	.klawisz_insert_puszczenie

	; nie rozpoznano znaku złożonego
	jmp	.end

.strzalka_w_lewo_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8002

	; koniec
	jmp	.save

.strzalka_w_lewo_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB002

	; koniec
	jmp	.save

.strzalka_w_prawo_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8003

	; koniec
	jmp	.save

.strzalka_w_prawo_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB003

	; koniec
	jmp	.save

.strzalka_w_gore_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8004

	; koniec
	jmp	.save

.strzalka_w_gore_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB004

	; koniec
	jmp	.save

.strzalka_w_dol_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8005

	; koniec
	jmp	.save

.strzalka_w_dol_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB005

	; koniec
	jmp	.save

.prawy_klawisz_ctrl_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8006

	; koniec
	jmp	.save

.prawy_klawisz_ctrl_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB006

	; koniec
	jmp	.save

.klawisz_end_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8008

	; koniec
	jmp	.save

.klawisz_end_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB008

	; koniec
	jmp	.save

.klawisz_home_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8007

	; koniec
	jmp	.save

.klawisz_home_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB007

	; koniec
	jmp	.save

.klawisz_delete_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x8009

	; koniec
	jmp	.save

.klawisz_delete_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB009

	; koniec
	jmp	.save

.klawisz_pageup_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x800A

	; koniec
	jmp	.save

.klawisz_pageup_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB00A

	; koniec
	jmp	.save

.klawisz_pagedown_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x800B

	; koniec
	jmp	.save

.klawisz_pagedown_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB00B

	; koniec
	jmp	.save

.klawisz_insert_nacisniecie:
	; ustaw systemowy kod klawisza
	mov	ax,	0x800C

	; koniec
	jmp	.save

.klawisz_insert_puszczenie:
	; ustaw systemowy kod klawisza
	mov	ax,	0xB00C

	; koniec
	jmp	.save

.no:
	; pobierz kod ASCII klawisza z macierzy
	mov	rsi,	qword [variable_keyboard_matrix_active]
	mov	al,	byte [rsi + rax]

	; sprawdź czy naciśnięto klawisz ENTER
	cmp	al,	0x0D
	jne	.nie_enter

	; zapisz kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.nie_enter:
	; sprawdź czy naciśnięto klawisz BACKSPACE
	cmp	al,	0x08
	jne	.nie_backspace

	; zapisz kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.nie_backspace:
	; sprawdź czy naciśnięto klawisz ESC
	cmp	al,	0x1B
	jne	.nie_esc

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.nie_esc:
	; sprawdź czy naciśnięto klawisz TAB
	cmp	al,	0x09
	jne	.nie_tab

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.nie_tab:
	; sprawdź czy naciśnięto klawisz CTRL
	cmp	al,	0x1D
	jne	.nie_nacisnieto_ctrl

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.nie_nacisnieto_ctrl:
	; sprawdź czy puszczono klawisz CTRL
	cmp	al,	0x1D + 0x80
	jne	.nie_puszczono_ctrl

	; kod ASCII klawisza
	call	keyboard_key_save

	; koniec
	jmp	.end

.nie_puszczono_ctrl:
	; sprawdź czy kod ASCII klawisza jest możliwy do wyświetlenia

	; test pierwszy
	cmp	al,	0x20
	jb	.end

	; test drugi
	cmp	al,	0x7E
	ja	.end

.save:
	; kod ASCII klawisza jest możliwy do wyświetlenia
	call	keyboard_key_save

.end:
	; wyślij informacje o zakończeniu przerwania sprzętowego
	mov	al,	0x20
	out	0x20,	al

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z przerwania
	iretq
