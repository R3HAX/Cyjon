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

variable_video_mode_memory_address		dq	VARIABLE_EMPTY
variable_video_mode_memory_size			dq	VARIABLE_EMPTY
variable_video_mode_x_resolution		dq	VARIABLE_EMPTY
variable_video_mode_x_resolution_in_bytes	dq	VARIABLE_EMPTY
variable_video_mode_y_resolution		dq	VARIABLE_EMPTY
variable_video_mode_bpp				dq	VARIABLE_EMPTY
variable_video_mode_pixels_count		dq	VARIABLE_EMPTY
variable_video_mode_pixels_per_line		dq	VARIABLE_EMPTY
variable_video_mode_chars_x			dq	VARIABLE_EMPTY
variable_video_mode_chars_y			dq	VARIABLE_EMPTY
variable_video_mode_cursor_indicator		dq	VARIABLE_EMPTY	; określa wyliczoną pozycję wirtualnego kursora w przestrzeni pamięci ekranu na podstawie X,Y
variable_video_mode_char_line_in_bytes		dq	VARIABLE_EMPTY

variable_screen_cursor_xy			dq	VARIABLE_EMPTY
variable_screen_cursor_semaphore		dq	VARIABLE_EMPTY	; flaga, 0 == kursor włączony
										; jeśli inaczej oznacza poziom blokady kursora programowego

;=======================================================================
; inicjalizuje podstawowe zmienne dotyczące właściwości trybu graficznego
; IN:
;	rbx - wskaźnik do tablicy SuperVGA Mode
; OUT:
;	brak
;
; wszystkie rejestry zachowane
screen_initialization:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rax

	; ustaw adres tablicy SuperVGA Mode
	mov	rsi,	rbx

	; pobierz adres fizyczny/logiczny przestrzeni pamięci liniowej karty graficznej
	mov	eax,	dword [rsi + 0x28]
	mov	qword [variable_video_mode_memory_address],	rax	; zapisz
	; początkowa pozycja wskaźnika kursora w przestrzeni pamięci karty graficznej: X=0, Y=0
	mov	qword [variable_video_mode_cursor_indicator],	rax	; zapisz
	; pobierz szerokość ekranu w pikselach
	movzx	eax,	word [rsi + 0x12]
	mov	qword [variable_video_mode_x_resolution],	rax	; zapisz

	; pobierz wysokość ekranu w pikselach
	movzx	eax,	word [rsi + 0x14]
	mov	qword [variable_video_mode_y_resolution],	rax	; zapisz

	; pobierz głębię kolorów
	movzx	eax,	byte [rsi + 0x19]
	; zamień na Bajty
	shr	rax,	3	; /8
	mov	qword [variable_video_mode_bpp],	rax	; zapisz

	; pobierz rozmiar linii (rozdzielczość X + uzupełnienie) o wysokości jednego piksela w Bajtach
	movzx	eax,	word [rsi + 0x10]

	; wyczyść resztę z dzielenia
	xor	rdx,	rdx
	; zamień na piksele
	div	qword [variable_video_mode_bpp]

	; sprawdź czy wartość różna od zera
	cmp	rax,	VARIABLE_EMPTY
	ja	.ok

	; ustaw wartość standardową
	mov	rax,	qword [variable_video_mode_x_resolution]

.ok:
	; zapisz wartość
	mov	qword [variable_video_mode_pixels_per_line],	rax	; zapisz

	; oblicz rozmiar przestrzeni pamięci liniowej karty graficznej w Bajtach

	; pobierz szerokość ekranu w pikselach (wraz z uzupełnieniem)
	mov	rax,	qword [variable_video_mode_pixels_per_line]
	; pomnóż przez wysokość ekranu
	mul	qword [variable_video_mode_y_resolution]
	; zapisz ilość pikseli
	mov	qword [variable_video_mode_pixels_count],	rax	; zapisz

	; zamień ilość pikseli na Bajty
	mul	qword [variable_video_mode_bpp]
	; otrzymaliśmy rozmiar przestrzeni pamięci ekranu w Bajtach
	mov	qword [variable_video_mode_memory_size],	rax	; zapisz

	; przelicz szerokość i wysokość ekranu na ilość znaków względem rozmiaru zastosowanej czcionki

	; ilość znaków na szerokość
	mov	rax,	qword [variable_video_mode_x_resolution]
	xor	rdx,	rdx	; wyczyść starszą część / resztę
	div	qword [variable_font_x_in_pixels]

	; reszta z dzielenia jest pomijana, nie da się tam wstawić pełnego znaku
	mov	qword [variable_video_mode_chars_x],	rax	; zapisz

	; ilość znaków na wysokość
	mov	rax,	qword [variable_video_mode_y_resolution]
	xor	rdx,	rdx	; wyczyść starszą część / resztę
	div	qword [variable_font_y_in_pixels]

	; reszta z dzielenia jest pomijana, nie da się tam wstawić pełnego znaku
	mov	qword [variable_video_mode_chars_y],	rax	; zapisz

	; oblicz rozmiar linii w Bajtach wypełnionej znakami
	mov	rax,	qword [variable_video_mode_pixels_per_line]
	; zamień linie na Bajty
	mul	qword [variable_video_mode_bpp]
	; powiększ o ilość linii w matrycy znaku
	mul	qword [variable_font_y_in_pixels]
	mov	qword [variable_video_mode_char_line_in_bytes],	rax	; zapisz

	; włącz kursor programowy
	call	cyjon_screen_cursor_enable_disable

	; wyczyść ekran
	call	cyjon_screen_clear

	; przywróć oryginalne rejestry
	pop	rax
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;=======================================================================
; mapuj przestrzeń pamięci ekranu do tablic stronicowania jądra systemu
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
screen_initialization_reload:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	r11

	; opisz w tablicach stronicowania jądra przestrzeń zarejestrowaną w binarnej mapie pamięci
	mov	rax,	qword [variable_video_mode_memory_address]
	; ustaw właściwości rekordów/stron w tablicach stronicowania
	mov	rbx,	3	; flagi: 4 KiB, Administrator, Odczyt/Zapis, Dostępna
	; opisz w tablicach stronicowania jądra przestrzeń o rozmiarze N stron
	mov	rdi,	qword [variable_video_mode_memory_size]
	; wyrównaj do pełnej strony
	call	library_align_address_up_to_page
	; ustaw licznik
	mov	rcx,	rdi
	; zamień na ilość stron
	shr	rcx,	12	; /4096
	; załaduj adres fizyczny/logiczny tablicy PML4 jądra
	mov	r11,	cr3

	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_physical_area

	; przywróc oryginalne rejestry
	pop	r11
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; czyści ekran na domyślny kolor tła
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyłącz kursor programowy lub zwiększ poziom blokady
	call	cyjon_screen_cursor_lock

	; wyczyść przestrzeń pamięci ekranu karty graficznej
	mov	eax,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	; rozmiar przestrzeni pamięci w pikselach
	mov	rcx,	qword [variable_video_mode_pixels_count]
	; adres początku przestrzeni pamięci ekranu
	mov	rdi,	qword [variable_video_mode_memory_address]

	; sprawdź palete barw
	cmp	byte [variable_video_mode_bpp],	0x03
	je	.bpp24	; 24 bitowa

.bpp32:
	; zapisz piksel o danym kolorze
	stosd
	sub	rcx,	1
	; kontynuuj
	jnz	.bpp32

	; zakończ
	jmp	.ready

.bpp24:
	; zapisz piksel o danym kolorze
	stosw
	ror	eax,	16
	stosb
	rol	eax,	16

	; kontynuuj
	sub	rcx,	1
	jnz	.bpp24

.ready:

	; ustaw adres wskaźnika kursora na początek przestrzeni ekranu
	mov	rax,	qword [variable_video_mode_memory_address]
	mov	qword [variable_video_mode_cursor_indicator],	rax

	; zapisz nową pozycję kursora programowego na ekranie
	xor	rax,	rax
	mov	qword [variable_screen_cursor_xy],	rax

	; włącz kursor programowy lub zmiejsz poziom blokady
	call	cyjon_screen_cursor_unlock

	; przywróc oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wyłącza i blokuje dostęp do kursora programowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_lock:
	; sprawdź czy kursor programowy jest wyłączony
	cmp	qword [variable_screen_cursor_semaphore],	VARIABLE_EMPTY
	ja	.blocked	; tak wyłączony

	; zablokuj kursor programowy
	inc	qword [variable_screen_cursor_semaphore]

	; wyłącz kursor programowy
	call	cyjon_screen_cursor_enable_disable

	; powrót z procedury
	ret

.blocked:
	; zwiększ poziom blokady kursora programowego
	inc	qword [variable_screen_cursor_semaphore]

	; powrót z procedury
	ret

;===============================================================================
; włącza i odblokowuje dostęp do kursora programowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_unlock:
	; zmniejsz poziom blokady kursora programowego
	dec	qword [variable_screen_cursor_semaphore]

	; sprawdź czy kursor został odblokowany
	cmp	qword [variable_screen_cursor_semaphore],	VARIABLE_EMPTY
	ja	.no

	; włącz kursor programowy
	call	cyjon_screen_cursor_enable_disable

.no:
	; powrót z procedury
	ret

;===============================================================================
; włącz lub wyłącza (wykonuje inwersje kolorów) programowy kursor na podstawie współrzędnych wirtualnego kursora
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_enable_disable:
	; zachowaj oryginalne rejestry
	push	rdi

	; pobierz aktualną pozycję kursora w przestrzeni pamięci ekranu
	call	cyjon_screen_cursor_calculate_indicator

	; zmień typ kursora na widoczny/niewidoczny
	call	cyjon_screen_cursor_invert_color

	; przywróć oryginalne rejestry
	pop	rdi

	; powrót z procedury
	ret

;===============================================================================
; na podstawie współrzędnych wirtualnego kursora oblicza odpowiadający adres (wskaźnik RDI) w przestrzeni pamięci ekranu
; IN:
;	brak
; OUT:
;	rdi - wskaźnik w przestrzeni pamięci ekranu
;
; pozostałe rejestry zachowane
cyjon_screen_cursor_calculate_indicator:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	; oblicz przesunięcie do określonej linii Y
	mov	rax,	qword [variable_video_mode_char_line_in_bytes]
	mul	dword [variable_screen_cursor_xy + 0x04]

	; ustaw wskaźnik kursora na poczatek ekranu
	mov	rdi,	qword [variable_video_mode_memory_address]
	add	rdi,	rax	; przesuń wskaźnik na obliczoną linię

	; oblicz przesunięcie do określonej kolumny X
	mov	eax,	dword [variable_screen_cursor_xy]
	; przelicz rozmiar na szerokość w matrycy znaku
	mul	qword [variable_font_x_in_pixels]
	; zamień na Bajty
	mul	qword [variable_video_mode_bpp]

	; zwróć sumę przesunięć jak i wskaźnik adresu w przestrzeni pamięci ekranu odpowiadający położeniu kursora
	add	rdi,	rax

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; wykonuje inwersje wartości w fragmencie pamięci ekranu o rozmiarze i umiejscowieniu wirtualnego kursora
; IN:
;	rdi - wskaźnik kursora w przestrzeni pamięci ekranu
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_cursor_invert_color:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; pobierz wysokość kursora w pikselach
	mov	rcx,	qword [variable_font_y_in_pixels]

.loopY:
	; zachowaj oryginalne rejestry
	push	rcx

	; pobierz szerokość kursora w pikselach
	mov	rcx,	qword [variable_font_x_in_pixels]

.loopX:
	; pobierz wartość z fragmentu adresu przestrzeni pamięci przedstawiającej kursor programowy
	mov	eax,	dword [edi]
	; odwóć wartości (inwersja kolorów)
	not	eax

	; sprawdź palete barw
	cmp	byte [variable_video_mode_bpp],	0x03
	je	.bpp24	; 24 bitowa

.bpp32:
	; zapisz nowy kolor piksela
	stosd

	; koniec
	jmp	.ready

.bpp24:
	; zapisz nowy kolor piksela
	stosw
	; przesuń bity 23..16 do 7..0
	ror	eax,	16
	; zapisz nowy kolor piksela
	stosb

.ready:
	; kontynuuj z pozostałymi pikselami w szerokości kursora
	sub	rcx,	1
	jnz	.loopX

	; przesuń wskaźnik w przestrzeni pamięci ekranu na następną linię kursora
	mov	rax,	qword [variable_video_mode_pixels_per_line]
	; koryguj o szerokość kursora
	sub	rax,	qword [variable_font_x_in_pixels]
	; przelicz na ilość Bajtów
	mul	qword [variable_video_mode_bpp]
	; dodaj przesunięcie do wskaźnika
	add	rdi,	rax

	; przywróć oryginalne rejestry
	pop	rcx

	; kontynuuj z pozostałymi liniami kursora
	sub	rcx,	1
	jnz	.loopY

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; wyświetla znak z macierzy czcionki pod adresem wskaźnika w przestrzeni pamięci ekranu
; IN:
;	al - kod ASCII znaku do wyświetlenia
;	ebx - kolor znaku
;	edx - kolor tła znaku
;	rdi - wskaźnik przestrzeni pamięci ekranu dla pozycji wyświetlanego znaku
; OUT:
;	rdi - wskaźnik do następnego znaku w przestrzeni pamięci ekranu
;
; pozostałe rejestry zachowane
cyjon_screen_print_char:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; wyłącz kursor programowy lub zwiększ poziom blokady
	call	cyjon_screen_cursor_lock

	; sprawdź czy klawisz BACKSPACE
	cmp	al,	VARIABLE_ASCII_CODE_BACKSPACE
	je	.backspace

	; sprawdź czy klawisz ENTER
	cmp	al,	VARIABLE_ASCII_CODE_ENTER
	je	.enter

	; sprawdź czy klawisz NOWA_LINIA
	cmp	al,	VARIABLE_ASCII_CODE_NEWLINE
	je	.new_line

	; ustaw wskaźnik na matryce znaku do wyświetlenia

	; ustaw wskaźnik macierzy czcionki
	mov	rsi,	font

	; zachowaj oryginalne rejestry
	push	rdx

	; przelicz przesunięcie znaku w macierzy czcionki na matryce znaku
	mov	rcx,	qword [variable_font_y_in_pixels]
	mul	rcx	; rax * rcx

	; przywróć oryginalne rejestry
	pop	rdx

	; przesuń wskaźnik na matryce znaku
	add	rsi,	rax

	; pobierz wysokość matrycy znaku
	mov	rcx,	qword [variable_font_y_in_pixels]

.matrix_line:
	; zachowaj licznik
	push	rcx

	; szerokość matrycy w pikselach
	mov	rcx,	qword [variable_font_x_in_pixels]
	; koryguj licznik
	dec	rcx

.pixel:
	; sprawdź czy bit ustawiony
	bt	qword [rsi],	rcx
	jnc	.background	; nie, tło

	; ustaw kolor sprecyzowany
	mov	rax,	rbx

	; wyświetl piksel na ekranie
	call	cyjon_screen_pixel_set

	; kontynuuj
	jmp	.continue

.background:
	; ustaw kolor sprecyzowany
	mov	rax,	rdx

	; wyświetl piksel na ekranie
	call	cyjon_screen_pixel_set

.continue:
	; następny piksel
	dec	rcx

	; sprawdź czy koniec bitów dla znaku
	cmp	rcx,	-1
	jne	.pixel

	; zachowaj oryginalne rejestry
	push	rdx

	; przesuń wskaźnik adresu w przestrzeni pamięci na następną linię z matrycy znaku
	mov	rax,	qword [variable_video_mode_pixels_per_line]
	; koryguj o szerokość matrycy znaku
	sub	rax,	qword [variable_font_x_in_pixels]
	; zamień na Bajty
	mul	qword [variable_video_mode_bpp]

	; przywróć oryginalne rejestry
	pop	rdx

	; przesuń wskaźnik na następną linię matrycy znaku w przestrzeni pamięci ekranu
	add	rdi,	rax

	; przywróć licznik linii
	pop	rcx

	; przesuń wskaźnik na następną linię matrycy znaku
	add	rsi,	qword [variable_font_x_in_bytes]

	; następna linia
	sub	rcx,	1
	jnz	.matrix_line

	; przesuń wskaźnik kursora w przestrzeni pamięci ekranu na następną pozycję
	mov	rax,	qword [variable_video_mode_bpp]
	mul	qword [variable_font_x_in_pixels]
	; koryguj wskaźnik na stosie
	add	qword [rsp],	rax

	; przesuń wskaźnik kursora o jedną pozycję w prawo
	inc	qword [variable_screen_cursor_xy]

	; koniec
	jmp	.end

.backspace:
	; sprawdź czy kursor znajduje się na początku linii
	cmp	dword [variable_screen_cursor_xy],	VARIABLE_EMPTY
	ja	.no

	; sprawdź czy można się cofnąć o jedną linię wcześniej
	cmp	dword [variable_screen_cursor_xy + 0x04],	VARIABLE_EMPTY
	je	.end	; kursora nie można ustawić poza ekranem

	; przesuń kursor o jedną linię wyżej
	dec	dword [variable_screen_cursor_xy + 0x04]

	; przesuń kursor na koniec linii
	mov	rax,	qword [variable_video_mode_chars_x]
	mov	dword [variable_screen_cursor_xy],	eax
	; koryguj
	dec	qword [variable_screen_cursor_xy]

	; oblicz wskaźnik
	jmp	.calculate

.no:
	; przesuń kursor o jedną pozycję w lewo
	dec	dword [variable_screen_cursor_xy]

.calculate:
	; oblicz położenie wskaźnika w przestrzeni pamięci ekranu
	call	cyjon_screen_cursor_calculate_indicator

	; wyczyść miejsce dla przyszłego znaku
	call	cyjon_screen_char_background_clear

	; ustaw wskaźnik na stosie
	mov	qword [rsp],	rdi

	; koniec
	jmp	.end

.enter:
	; cofnij kursor w przestrzeni pamięci ekranu na początek
	mov	rdi,	qword [variable_video_mode_memory_address]
	; pobierz rozmiar linii wypełnionej znakami w Bajtach
	mov	rax,	qword [variable_video_mode_char_line_in_bytes]
	; oblicz przesunięcie względem pozycji kursora Y
	mul	dword [variable_screen_cursor_xy + 0x04]
	; aktualizuj adres wskaźnika
	add	rdi,	rax
	; załaduj do wskaźnika na stosie
	mov	qword [rsp],	rdi

	; przesuń kursor programowy na początek linii
	mov	dword [variable_screen_cursor_xy],	VARIABLE_EMPTY

	; koniec
	jmp	.end

.new_line:
	; przesuń wskaźnik kursora w przestrzeni pamięci ekranu do nowej linii
	mov	rax,	qword [variable_video_mode_char_line_in_bytes]
	add	qword [rsp],	rax

	; przesuń kursor do nowej linii
	inc	dword [variable_screen_cursor_xy + 0x04]

.end:
	; włącz kursor programowy lub zmniejsz poziom blokady
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; wyświetla znak z macierzy czcionki pod adresem wskaźnika w przestrzeni pamięci ekranu
; IN:
;	eax - kolor piksela
;	rdi - wskaźnik w przestrzeni pamięci ekranu
; OUT:
;	rdi - pozycja następnego piksela
;
; pozostałe rejestry zachowane
cyjon_screen_pixel_set:
	; sprawdź palete barw
	cmp	byte [variable_video_mode_bpp],	0x03
	je	.bpp24	; 24 bitowa

.bpp32:
	; zapisz piksel o danym kolorze
	stosd

	; powrót z procedury
	ret

.bpp24:
	; zapisz piksel o danym kolorze
	stosw
	ror	eax,	16
	stosb
	rol	eax,	16

.ready:
	; powrót z procedury
	ret

;=======================================================================
; czyści pozycje w przestrzeni pamięci ekranu o rozmiarach czcionki
; IN:
;	edx - tło znaku
;	rdi - wskaźnik w przestrzeni pamięci ekranu
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_char_background_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; ustaw tło
	mov	rax,	rdx

	; pobierz wysokość matrycy znaku
	mov	rcx,	qword [variable_font_y_in_pixels]

.matrix_line:
	; zachowaj licznik
	push	rcx

	; szerokość matrycy w pikselach
	mov	rcx,	qword [variable_font_x_in_pixels]
	; koryguj licznik
	dec	rcx

.pixel:
	; ustaw kolor tła
	mov	rax,	rdx

	; wyświetl piksel na ekranie
	call	cyjon_screen_pixel_set

.continue:
	; następny piksel
	dec	rcx

	; sprawdź czy koniec bitów dla znaku
	cmp	rcx,	-1
	jne	.pixel

	; zachowaj oryginalne rejestry
	push	rdx

	; przesuń wskaźnik adresu w przestrzeni pamięci na następną linię z matrycy znaku
	mov	rax,	qword [variable_video_mode_pixels_per_line]
	; koryguj o szerokość matrycy znaku
	sub	rax,	qword [variable_font_x_in_pixels]
	; zamień na Bajty
	mul	qword [variable_video_mode_bpp]

	; przywróć oryginalne rejestry
	pop	rdx

	; przesuń wskaźnik na następną linię matrycy znaku w przestrzeni pamięci ekranu
	add	rdi,	rax

	; przywróć licznik linii
	pop	rcx

	; następna linia
	sub	rcx,	1
	jnz	.matrix_line

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; wyświetla ciąg znaków spod wskaźnika RSI, zakończony terminatorem lub ilością na podstawie rejestru RCX
; IN:
;	ebx - kolor znaku
;	rcx - ilość znaków do wyświetlenia z ciągu
;	edx - kolor tła znaku
;	rsi - wskaźnik przestrzeni pamięci ekranu dla pozycji wyświetlanego znaku
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_print_string:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; wyłącz kursor programowy lub zwiększ poziom blokady
	call	cyjon_screen_cursor_lock

	; pobierz wskaźnik aktualnego miejsca położenia matrycy znaku do wypisania na ekranie
	mov	rdi,	qword [variable_video_mode_cursor_indicator]

	; sprawdź czy wskazano ilość znaków do wyświetlenia
	cmp	rcx,	VARIABLE_EMPTY
	je	.end	; jeśli nie, zakończ działanie

	; wyczyść akumulator
	xor	rax,	rax

.string:
	; pobierz znak z ciągu tekstu
	lodsb	; załaduj do rejestru AL Bajt pod adresem w wskaźniku RSI, zwiększ wskaźnik RSI o jeden

	; sprawdź czy koniec ciągu
	cmp	al,	VARIABLE_ASCII_CODE_TERMINATOR
	je	.end	; jeśli tak, koniec

	; wyświetl znak na ekranie
	call	cyjon_screen_print_char

	; sprawdź pozycje kursora
	call	cyjon_screen_cursor_check_position

	; wyświetl pozostałe znaki z ciągu
	loop	.string

.end:
	; zapisz aktualny wskaźnik kursora
	mov	qword [variable_video_mode_cursor_indicator],	rdi

	; włącz kursor programowy lub zmniejsz poziom blokady
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; przewija zawartość ekranu o jedną linię (w znakach) do góry jeśli kursor znajduje się w nieodpowiednim miejscu
; IN:
;	brak
; OUT:
;	rdi - wskaźnik do pozycji kursora w przestrzeni pamięci ekranu
;
; pozostałe rejestry zachowane
cyjon_screen_cursor_check_position:
	; zachowaj oryginalne rejestry
	push	rax

	; sprawdź czy kursor znajduje się poza ekranem wszerz
	mov	rax,	qword [variable_video_mode_chars_x]
	cmp	dword [variable_screen_cursor_xy],	eax
	jb	.inX	; nie wyszedł poza ekran

	; przesuń kursor w do nowej linii
	inc	qword [variable_screen_cursor_xy + 0x04]
	; przesuń kursor na początek nowej linii
	mov	dword [variable_screen_cursor_xy],	VARIABLE_EMPTY

	; oblicz nową pozycję kursora w przestrzeni pamięci ekranu
	call	cyjon_screen_cursor_calculate_indicator

.inX:
	; sprawdź czy kursor znajduje się poza ekranem w wzdłóż
	mov	rax,	qword [variable_video_mode_chars_y]
	cmp	dword [variable_screen_cursor_xy + 0x04],	eax
	jb	.inY

	; ustaw kursor spowrotem na ekran (ostatnia linia)
	dec	dword [variable_screen_cursor_xy + 0x04]

	; przewiń zawartość ekranu o jedną linię w górę
	call	cyjon_screen_scroll

	; oblicz nową pozycję kursora w przestrzeni pamięci ekranu
	call	cyjon_screen_cursor_calculate_indicator

.inY:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; przewija zawartość ekranu o jedną linię (w znakach) do góry
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_scroll:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; wyłącz kursor programowy lub zwiększ poziom blokady
	call	cyjon_screen_cursor_lock

	; pobierz rozmiar jednej linii w Bajtach
	mov	rax,	qword [variable_video_mode_char_line_in_bytes]

	; adres docelowy przesunięcia zawartości pamięci ekranu na początek
	mov	rdi,	qword [variable_video_mode_memory_address]

	; oblicz adres źródłowy przsunięcia zawartości ekranu
	mov	rsi,	rdi	; początek ekranu
	add	rsi,	rax	; linia nr 1

	; oblicz rozmiar pamięci do przesunięcia
	mov	rcx,	qword [variable_video_mode_memory_size]
	sub	rcx,	rax	; pomiń rozmiar jednej linii znaków
	shr	rcx,	2	; kopiuj po 4 Bajty na raz

	; skopiuj 4 Bajtową zawartość pamięci pod adresem w rejestrze RSI pod adres w rejestrze RDI, zwiększ obydwa rejestry o 4 Bajty, zmniejsz rejestr RCX o 1, jeśli RCX > 0 wykonaj raz jeszcze
	rep	movsd

	; wyczyść ostatnią linię
	mov	rax,	rdx	; kolor sprecyzowany

	; rozmiar linii do wyczyszczenia w Bajtach
	mov	rcx,	qword [variable_video_mode_char_line_in_bytes]

	; sprawdź głębie kolorów
	cmp	byte [variable_video_mode_bpp],	3
	je	.bpp24

	; kopiuj po 4 Bajty naraz
	shr	rax,	2

	; wykonaj
	rep	stosd

	; koniec
	jmp	.end

.bpp24:
	; szybkość zabójcza :/

	; wykonaj
	stosw	; młodsza część koloru piksela
	ror	eax,	16
	stosb	; starsza część koloru piksela
	rol	eax,	16

	; kontynuuj z następnym pikselem
	sub	rcx,	2
	loop	.bpp24

.end:
	; włącz kursor programowy lub zmniejsz poziom blokady
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; wyświetla liczbę o podanej podstawie
; IN:
;	rax - liczba/cyfra do wyświetlenia
;	ebx - kolor liczby
;	cl - podstawa liczbowa
;	edx - kolor tła tło
;	rdi - wskaźnik przestrzeni pamięci ekranu dla pozycji wyświetlanej liczby
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_screen_print_number:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10

	; wyłącz kursor programowy lub zwiększ poziom blokady
	call	cyjon_screen_cursor_lock

	; sprawdź czy podstawa liczby dozwolona
	cmp	cl,	2
	jb	.end	; brak obsługi

	; sprawdź czy podstawa liczby dozwolona
	cmp	cl,	36
	ja	.end	; brak obsługi

	; zapamiętaj kolor tła
	mov	r8,	rdx

	; wyczyść starszą część / resztę z dzielenia
	xor	rdx,	rdx

	; zapamiętaj flagi
	mov	r9,	rcx

	; wyczyść flagi
	xor	ch,	ch

	; utwórz stos zmiennych lokalnych
	mov	rbp,	rsp

	; zreseruj licznik cyfr
	xor	r10,	r10

.loop:
	; oblicz resztę z dzielenia
	div	rcx

	; licznik cyfr
	inc	r10

	; zapisz resztę z dzielenia do zmiennych lokalnych
	push	rdx

	; wyczyść resztę z dzielenia
	xor	rdx,	rdx

	; sprawdź czy przeliczać dalej
	cmp	rax,	VARIABLE_EMPTY
	ja	.loop	; jeśli tak, powtórz działanie

	; przywróć kolor tła liczby
	mov	rdx,	r8

	; załaduj wskaźnik pozycji kursora
	mov	rdi,	qword [variable_video_mode_cursor_indicator]

	; przywróć flagi
	mov	rcx,	r9

	; flagi dostępne?
	cmp	ch,	VARIABLE_EMPTY
	je	.print

	; wyświetl uzupełnienie do liczby 64 bitowej
	cmp	ch,	0x01
	jne	.no_64bit

	; przywróć tło
	mov	rdx,	r8

	; cyfra
	mov	rcx,	1
	; zero
	mov	rax,	"0"

.bit64:
	cmp	r10,	16
	jae	.print

	call	cyjon_screen_print_char

	inc	r10

	jmp	.bit64

.no_64bit:

.print:
	; pobierz z zmiennych lokalnych cyfrę
	pop	rax

	; przemianuj cyfrę na kod ASCII
	add	rax,	0x30

	; sprawdź czy system liczbowy powyżej podstawy 10
	cmp	al,	0x3A
	jb	.no	; jeśli nie, kontynuuj

	; koryguj kod ASCII do odpowiedniej podstawy liczbowej
	add	al,	0x07

.no:
	; wyświetl cyfrę
	call	cyjon_screen_print_char

	; sprawdź pozycje kursora
	call	cyjon_screen_cursor_check_position

	; sprawdź czy pozostały cyfry do wyświetlenia z liczby
	cmp	rsp,	rbp
	jne	.print	; jeśli tak, wyświetl pozostałe

	; zapisz nowy wskaźnik kursora
	mov	qword [variable_video_mode_cursor_indicator],	rdi

.end:
	; włącz kursor programowy lub zmniejsz poziom blokady
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	r10
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; wyświetla ostateczną informacje o błędzie podczas działania kodu jądra systemu
; IN:
;	brak
; OUT:
;	brak
;
; zatrzymanie procesora
cyjon_screen_kernel_panic:
	; wyświetl informacje o niepowodzeniu
	mov	ebx,	0x00ff2727	; kolor czerwony
	mov	rcx,	-1	; wyświetl cały ciąg tekstu
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT

	; wyświetl informacje
	call	cyjon_screen_print_string

	; zatrzymaj dalsze wykonywanie kodu jądra systemu
	jmp	$
