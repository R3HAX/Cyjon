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

;===============================================================================
; procedura/podprocedury obsługujące przerwanie programowe procesów
; IN:
;	różne
; OUT:
;	różne
;
; różne rejestry zachowane
irq64:
	; czy zarządzać procesami?
	cmp	ah,	VARIABLE_EMPTY
	je	irq64_process

	; czy zarządzać ekranem?
	cmp	ah,	0x01
	je	irq64_screen

	; czy zarządzać klawiaturą?
	cmp	ah,	0x02
	je	irq64_keyboard

	; czy zarządzać systemem?
	cmp	ah,	0x03
	je	irq64_system

.end:
	; powrót z przerwania programowanego
	iretq

;===============================================================================
irq64_process:
	; sprawdź czy zamknąć proces
	cmp	al,	VARIABLE_EMPTY
	je	.process_kill

	; uruchomić nowy proces?
	cmp	al,	0x01
	je	.process_new

	; sprawdzić czy proces istnieje?
	cmp	al,	0x02
	je	.process_check

	; proces poprosił o dodatkową przestrzeń pamięci?
	cmp	al,	0x03
	je	.process_more_memory

	; lista procesów aktywnych
	cmp	al,	0x04
	je	.process_active_list

	; brak obsługi
	jmp	irq64.end

.process_kill:
	; zatrzymaj aktualnie uruchomiony proces
	mov	rdi,	qword [variable_process_serpentine_record_active]

	; ustaw flagę "gotowy do zamknięcia" i "proces nieaktywny"
	and	byte [rdi + STATIC_PROCESS_RECORD.FLAGS],	11111110b
	or	byte [rdi + STATIC_PROCESS_RECORD.FLAGS],	00000100b

	; zatrzymaj dalsze wykonywanie kodu procesu
	jmp	$

.process_new:
	; zachowaj oryginalne rejestry
	push	rdi
	push	r8

	; szukaj programu na partycji systemowej
	mov	r8,	variable_partition_specification_system
	call	cyjon_virtual_file_system_find_file

	; czy znaleziono?
	jc	.process_new_found

	; nie znaleziono pliku o podanej nazwie na partycji systemowej
	xor	rcx,	rcx

	; koniec obsługi przerwania
	jmp	.process_new_end

.process_new_found:
	; sprawdź czy jądro jest gotowe na uruchomienie kolejnego procesu
	cmp	byte [variable_process_semaphore_init],	VARIABLE_EMPTY
	jne	.process_new_found	; czekaj

	; zarezerwuj procedure
	mov	byte [variable_process_semaphore_init],	0x01

	; poinformuj jądro systemu o potrzebie uruchomienia nowego procesu
	mov	qword [variable_process_new],	rdi

.process_new_check:
	; sprawdź czy proces został uruchomiony
	cmp	qword [variable_process_pid],	VARIABLE_EMPTY
	je	.process_new_check	; jeśli nie, czekaj dalej

	; pobierz numer PID uruchomionego procesu
	xor	rcx,	rcx
	xchg	rcx,	qword [variable_process_pid]

	; zwolnij procedure uruchamiania nowego procesu
	mov	byte [variable_process_semaphore_init],	VARIABLE_EMPTY

.process_new_end:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi

	; koniec obsługi procedury
	jmp	irq64.end

.process_check:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; pobierz adres tablicy procesów
	mov	rdi,	qword [variable_process_serpentine_start_address]

	; zapamiętaj
	push	rdi

	; przeszukane rekordy
	xor	rbx,	rbx

	; pomiń nagłówek
	add	rdi,	0x08

.process_check_loop:
	; sprawdź numer PID procesu w rekordzie
	cmp	qword [rdi + STATIC_PROCESS_RECORD.PID],	rcx
	jne	.process_check_continue

	; sprawdź czy proces jest aktywny
	mov	al,	byte [rdi + STATIC_PROCESS_RECORD.FLAGS]
	bt	ax,	0
	jnc	.process_check_not_found

	; proces istnieje i jest aktywny
	jmp	.process_check_exists

.process_check_continue:
	; następny rekord
	add	rdi,	STATIC_PROCESS_RECORD.SIZE

	; przeszukano rekord
	inc	rbx

	; koniec części serpentyny?
	cmp	rbx,	STATIC_PROCESS_RECORDS_PER_PAGE
	jb	.process_check_loop

	; przejdź do następnej części
	mov	rdi,	qword [rdi]

	; wykonaliśmy pętlę?
	cmp	rdi,	qword [rsp]
	je	.process_check_not_found

	; pomiń nagłówek
	add	rdi,	0x08

	; kontynuuj z nastepnymi rekordami
	jmp	.process_check_loop

.process_check_not_found:
	; zwróć brak uruchomionego procesu
	mov	qword [rsp + 0x10],	VARIABLE_EMPTY

.process_check_exists:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi procedury
	jmp	irq64.end

.process_more_memory:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rbx
	push	rdi
	push	r11

	; wyrównaj adres do pełnej strony
	call	library_align_address_up_to_page

	; przygotuj przestrzeń pod dane
	mov	rax,	rdi
	mov	rdi,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rdi
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	; przywróć oryginalne rejestry
	pop	r11
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi procedury
	jmp	irq64.end

.process_active_list:
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	r11
	push	r8

	mov	rax,	STATIC_PROCESS_RECORD.SIZE
	mov	rcx,	qword [variable_process_serpentine_record_count]
	mul	rcx

	xchg	rax,	rdi
	call	library_align_address_up_to_page
	xchg	rax,	rdi
	xchg	rax,	rcx
	shr	rcx,	12

	; wyrównaj adres do pełnej strony
	call	library_align_address_up_to_page

	; przygotuj przestrzeń pod dane
	mov	rax,	rdi
	mov	rdi,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rdi
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	; znajdź wolny rekord w tablicy procesów
	mov	rsi,	qword [variable_process_serpentine_start_address]

	; pomiń nagłówek
	add	rsi,	0x08

	add	rdi,	rax

	; licznik elemtów w utworzonej tablicy
	xor	r8,	r8

	; nagłówek tworzonej tablicy (rozmiar jednego rekordu w Bajtach)
	mov	rax,	41
	stosq

.process_active_list_loop:
	; flaga
	xor	bx,	bx

	; licznik rekordów
	xor	rcx,	rcx

.process_active_list_next:
	; przesuń na następny rekord
	add	rsi,	STATIC_PROCESS_RECORD.SIZE

	; rekord zajęty
	inc	rcx

	; koniec rekordów w części serpentyny?
	cmp	rcx,	STATIC_PROCESS_RECORDS_PER_PAGE
	jb	.process_active_list_in_page

	; zładuj adres kolejnej części serpentyny
	mov	rsi,	qword [rsi]

	; koniec serpentyny
	cmp	rsi,	qword [variable_process_serpentine_start_address]
	je	.process_active_list_end

	; pomiń nagłówek
	add	rsi,	0x08

	; zresetuj licznik rekordów na część serpentyny
	xor	rcx,	rcx

.process_active_list_in_page:
	; sprawdź czy rekord jest aktywny
	bt	word [rsi + STATIC_PROCESS_RECORD.FLAGS],	bx
	jnc	.process_active_list_next	; jeśli tak

	push	rcx
	push	rsi
	mov	rcx,	8
	rep	movsb
	add	rsi,	0x18
	mov	rcx,	32
	rep	movsb
	; dodaj terminator na koniec rekordu
	xor	al,	al
	stosb
	pop	rsi
	pop	rcx

	; dodano element to tablicy
	inc	r8

	jmp	.process_active_list_next

.process_active_list_end:
	mov	rcx,	r8

	pop	r11
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; koniec obsługi procedury
	jmp	irq64.end

;===============================================================================
irq64_screen:
	; sprawdź czy wyczyścić ekran
	cmp	al,	VARIABLE_EMPTY
	je	.screen_clear

	; sprawdź czy wyświetlić ciąg znaków
	cmp	al,	0x01
	je	.screen_string

	; sprawdź czy wyświetlić znak
	cmp	al,	0x02
	je	.screen_char

	; sprawdź czy wyświetlić liczbę
	cmp	al,	0x03
	je	.screen_number

	; sprawdź czy pobrać współrzędne kursora
	cmp	al,	0x04
	je	.screen_cursor_get_xy

	; sprawdź czy przestawić kursor
	cmp	al,	0x05
	je	.screen_cursor_set_xy

	; pobierz informacje o ekranie
	cmp	al,	0x06
	je	.screen_information

	; ukryj kursor
	cmp	al,	0x07
	je	.screen_cursor_hide

	; pokaź kursor
	cmp	al,	0x08
	je	.screen_cursor_show

	; brak obsługi
	jmp	irq64.end

.screen_clear:
	call	cyjon_screen_clear

	; koniec obsługi procedury
	jmp	irq64.end

.screen_string:
	; wyświetl ciąg znaków na ekranie
	call	cyjon_screen_print_string

	; koniec obsługi procedury
	jmp	irq64.end

.screen_char:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyłącz kursor programowy lub zwiększ poziom blokady
	call	cyjon_screen_cursor_lock

	; załaduj znak do wyświetlenia
	mov	rax,	r8
	
	; pobierz pozycje kursora w przestrzeni pamięci ekranu
	mov	rdi,	qword [variable_video_mode_cursor_indicator]

.loop:
	; wyświetl znak
	call	cyjon_screen_print_char

	; sprawdź pozycje kursora
	call	cyjon_screen_cursor_check_position

	; zapisz aktualną pozycję kursora w przestrzeni pamięci ekranu
	mov	qword [variable_video_mode_cursor_indicator],	rdi

	; kontynuuj z pozostałą ilością powtórzeń
	loop	.loop

	; włącz kursor programowy lub zmniejsz poziom blokady
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; koniec obsługi procedury
	jmp	irq64.end

.screen_number:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; załaduj liczbe do wyświetlenia
	mov	rax,	r8
	; załaduj wskaźnik kursora w przestrzeni pamięci ekranu
	mov	rdi,	qword [variable_video_mode_cursor_indicator]
	; wykonaj
	call	cyjon_screen_print_number

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; koniec obsługi procedury
	jmp	irq64.end

.screen_cursor_get_xy:
	mov	rbx,	qword [variable_screen_cursor_xy]

	; koniec obsługi procedury
	jmp	irq64.end

.screen_cursor_set_xy:
	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	call	screen_cursor_set_xy

	; włącz kursor
	call	cyjon_screen_cursor_unlock

	; koniec obsługi procedury
	jmp	irq64.end

.screen_information:
	; zwróć informacje o rozmiarze ekranu w znakach
	mov	ebx,	dword [variable_video_mode_chars_y]
	shl	rbx,	32
	or	rbx,	qword [variable_video_mode_chars_x]

	; koniec obsługi procedury
	jmp	irq64.end

.screen_cursor_hide:
	call	cyjon_screen_cursor_lock

	; koniec obsługi procedury
	jmp	irq64.end

.screen_cursor_show:
	cmp	qword [variable_screen_cursor_semaphore], VARIABLE_EMPTY
	je	irq64.end

	call	cyjon_screen_cursor_unlock

	; koniec obsługi procedury
	jmp	irq64.end

screen_cursor_set_xy:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdi

	; sprawdź czy kursor będzie znajdował się poza ekranem
	cmp	ebx,	dword [variable_video_mode_chars_x]
	jb	.ok

	; koryguj
	mov	ebx,	dword [variable_video_mode_chars_x]

.ok:
	; aktualizuj pozycje kursora X
	mov	dword [variable_screen_cursor_xy],	ebx

	; zamień wartości miejscami
	ror	rbx,	32

	; sprawdź czy kursor będzie znajdował się poza ekranem
	cmp	ebx,	dword [variable_video_mode_chars_y]
	jb	.ready

	; koryguj
	mov	ebx,	dword [variable_video_mode_chars_y]

.ready:
	; aktualizuj pozycje Y
	mov	dword [variable_screen_cursor_xy + 0x04],	ebx

	; oblicz nową pozycję wskaźnika kursora w przestrzeni pamięci ekranu
	call	cyjon_screen_cursor_calculate_indicator

	; zapisz
	mov	qword [variable_video_mode_cursor_indicator],	rdi

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rbx

	; powrót z procedury
	ret

;===============================================================================
irq64_keyboard:
	; sprawdź czy pobrać znak z bufora klawiatury
	cmp	al,	VARIABLE_EMPTY
	je	.keyboard_get_key

	; brak obsługi
	jmp	irq64.end

.keyboard_get_key:
	; pobierz kod ASCII klawisza z bufora klawiatury
	call	cyjon_keyboard_key_read

	; koniec obsługi procedury
	jmp	irq64.end

;===============================================================================
irq64_system:
	; pobrać czas 'uptime'?
	cmp	al,	VARIABLE_EMPTY
	je	.system_uptime

	; pobrać date?
	cmp	al,	0x01
	je	.system_date

	; brak obsługi
	jmp	irq64.end

.system_uptime:
	; pobierz czas 'uptime'
	mov	rcx,	qword [variable_system_uptime]

	; koniec obsługi procedury
	jmp	irq64.end

.system_date:
	xor	rbx,	rbx
	; załaduj dzień tygodnia
	mov	bl,	byte [variable_cmos_day_of_week]
	; przeładuj
	shl	rbx,	8
	; załaduj dzień miesiąca
	mov	bl,	byte [variable_cmos_day_of_month]
	; przełąduj
	shl	rbx,	8
	; załaduj miesiąc
	mov	bl,	byte [variable_cmos_month]
	; przeładuj
	shl	rbx,	8
	; załaduj rok
	mov	bl,	byte [variable_cmos_year]
	; przeładuj
	shl	rbx,	8
	; załaduj godzine
	mov	bl,	byte [variable_cmos_hour]
	; przeładuj
	shl	rbx,	8
	; załaduj minute
	mov	bl,	byte [variable_cmos_minute]
	; przeładuj
	shl	rbx,	8
	; załaduj sekunde
	mov	bl,	byte [variable_cmos_second]
	; przeładuj
	shl	rbx,	8
	mov	bl,	00000001b	; tryb 24 godzinny

	; koniec obsługi procedury
	jmp	irq64.end

; pozostała część w trakcie przepisywania
