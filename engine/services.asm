; Copyright (C) 2013-2016 Wataha.net
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

	; czy zarządzać systemem plików
	cmp	ah,	0x04
	je	irq64_filesystem

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

	; pobierz argumenty przekazane do procesu
	cmp	al,	0x05
	je	.process_args

	; brak obsługi
	jmp	irq64.end

.process_kill:
	; zatrzymaj aktualnie uruchomiony proces
	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]

	; ustaw flagę STATIC_SERPENTINE_RECORD_FLAG_CLOSED, NOT STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	and	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	~STATIC_SERPENTINE_RECORD_FLAG_ACTIVE
	or	byte [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	STATIC_SERPENTINE_RECORD_FLAG_CLOSED

	hlt

	; zatrzymaj dalsze wykonywanie kodu procesu
	jmp	$

.process_new:
	; zachowaj oryginalne rejestry
	push	r8

	mov	r8,	variable_partition_specification_system

	call	cyjon_process_init

	; przywróć oryginalne rejestry
	pop	r8

	; koniec obsługi procedury
	jmp	irq64.end

.process_check:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rdi

	mov	rax,	rcx

	mov	rdi,	qword [variable_multitasking_serpentine_start_address]

	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	mov	rdx,	qword [variable_multitasking_serpentine_record_counter]

	jmp	.do_not_leave_me

.next_record:
	dec	rcx
	dec	rdx

	; przesuń na następny rekord
	add	rdi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.do_not_leave_me:
	cmp	rdx,	VARIABLE_EMPTY
	ja	.left_something

	; brak uruchomionego procesu o danym PID
	xor	rcx,	rcx

	jmp	.end

.left_something:
	cmp	rcx,	VARIABLE_EMPTY
	ja	.in_page

	and	di,	0xF000
	mov	rdi,	qword [rdi + 0x0FF8]

	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.in_page:
	cmp	rax,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.PID]
	jne	.next_record

	mov	rcx,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.PID]

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
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

	mov	rax,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	mov	rcx,	qword [variable_multitasking_serpentine_record_counter]
	mul	rcx

	xchg	rax,	rdi
	call	library_align_address_up_to_page
	xchg	rax,	rdi
	xchg	rax,	rcx
	shr	rcx,	12

	; wyrównaj adres do pełnej strony
	call	library_align_address_up_to_page

	push	rdi

	; przygotuj przestrzeń pod dane
	mov	rax,	rdi
	mov	rdi,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rdi
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	pop	rdi

	mov	rsi,	qword [variable_multitasking_serpentine_start_address]

	; ilość rekordów na stronę
	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

	; zapisz informacje o rozmiarze pojedyńczego rekordu
	mov	rax,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	stosq

	jmp	.process_active_list_left_something

.process_active_list_empty_record:
	add	rsi,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.process_active_list_next_record:
	dec	rcx

.process_active_list_left_something:
	cmp	rcx,	VARIABLE_EMPTY
	ja	.process_active_list_in_page

	and	si,	0xF000
	mov	rsi,	qword [rsi + 0x0FF8]

	cmp	rsi,	VARIABLE_EMPTY
	je	.process_active_list_end

	mov	rcx,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / VARIABLE_TABLE_SERPENTINE_RECORD.SIZE

.process_active_list_in_page:
	cmp	qword [rsi + VARIABLE_TABLE_SERPENTINE_RECORD.FLAGS],	VARIABLE_EMPTY
	je	.process_active_list_empty_record

	push	rcx

	mov	rcx,	VARIABLE_TABLE_SERPENTINE_RECORD.SIZE
	rep	movsb

	pop	rcx

	jmp	.process_active_list_next_record

.process_active_list_end:
	; pusty rekord na koniec tablicy
	stosq
	stosq

	pop	r11
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; koniec obsługi procedury
	jmp	irq64.end

.process_args:
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	mov	rdi,	qword [variable_multitasking_serpentine_record_active_address]
	mov	rcx,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS]
	cmp	rcx,	VARIABLE_EMPTY
	je	.process_args_end

	; przygotuj miejsce pod argumenty
	mov	rax,	qword [rsp + 0x08]
	mov	rbx,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rbx
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; rozmiar 1 strona
	push	r11
	mov	r11,	cr3
	call	cyjon_page_map_logical_area
	pop	r11

	mov	rsi,	qword [rdi + VARIABLE_TABLE_SERPENTINE_RECORD.ARGS]
	mov	rdi,	qword [rsp + 0x08]	

	push	qword [rsi]
	add	rsi,	0x08	; pomiń rozmiar

	mov	r8,	( VARIABLE_MEMORY_PAGE_SIZE - 0x08 ) / 8

.process_args_loop:
	mov	rax,	qword [rsi]
	mov	qword [rdi],	rax
	add	rsi,	0x08
	add	rdi,	0x08
	sub	r8,	VARIABLE_DECREMENT
	jnz	.process_args_loop

	pop	rcx

.process_args_end:
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

	; przewiń zawartość ekranu
	cmp	al,	0x09
	je	.screen_scroll

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

.screen_scroll:
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	call	cyjon_screen_cursor_lock

	; oblicz adres lini źródłowej
	mov	rax,	qword [variable_video_mode_char_line_in_bytes]
	mul	rdx
	mov	rsi,	rax
	add	rsi,	qword [variable_video_mode_memory_address]
	; oblicz adres linii docelowej
	mov	rdi,	rsi
	sub	rdi,	qword [variable_video_mode_char_line_in_bytes]

	; oblicz rozmiar przestrzemi pamięci do przesunięcia
	mov	rax,	qword [variable_video_mode_char_line_in_bytes]
	mul	rcx
	mov	rcx,	rax

	cmp	bl,	VARIABLE_EMPTY
	je	.screen_scroll_down

	; przewiń w górę
.screen_scroll_loop_1:
	movsq
	sub	rcx,	8
	jnz	.screen_scroll_loop_1
	jmp	.screen_scroll_end

.screen_scroll_down:
	; przesuń wskaźniki na koniec
	xchg	rdi,	rsi
	add	rdi,	rcx
	add	rsi,	rcx

.screen_scroll_loop_2:
	movsq
	sub	rsi,	16
	sub	rdi,	16
	sub	rcx,	8
	jnz	.screen_scroll_loop_2

.screen_scroll_end:
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

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

irq64_filesystem:
	; odczytać plik?
	cmp	al,	VARIABLE_EMPTY
	je	.filesystem_file_read

	cmp	al,	0x01
	je	.filesystem_file_size

	cmp	al,	0x02
	je	.filesystem_file_touch

	cmp	al,	0x03
	je	.filesystem_root_directory

	; brak obsługi
	jmp	irq64.end

.filesystem_file_read:
	push	r8

	mov	r8,	variable_partition_specification_home

	mov	rax,	rbx

	call	cyjon_filesystem_kfs_find_file
	jnc	.filesystem_file_read_end

	; przygotuj miejsce w przestrzeni pamięci procesu na plik

	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r11

	push	rax

	mul	qword [r8 + KFS.knot_size]
	mov	rsi,	qword [r8 + KFS.knots_table_address]
	add	rsi,	rax

	cmp	qword [rsi + KNOT.size_in_bytes],	VARIABLE_EMPTY
	je	.filesystem_file_read_empty
	
	mov	rax,	qword [rsi + KNOT.size_in_bytes]

	add	rsp,	0x08

	xor	rdx,	rdx
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE
	div	rcx

	cmp	rdx,	VARIABLE_EMPTY
	je	.filesystem_file_read_ok

	add	rax,	VARIABLE_INCREMENT

.filesystem_file_read_ok:
	mov	rcx,	rax
	mov	rax,	rdi
	mov	rbx,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rbx
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	pop	r11
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	call	cyjon_filesystem_kfs_file_read

.filesystem_file_read_end:
	pop	r8

	; koniec obsługi procedury
	jmp	irq64.end

.filesystem_file_read_empty:
	pop	rax
	xor	rdx,	rdx

	pop	r11
	pop	r8
	pop	rsi
	add	rsp,	0x08
	pop	rcx
	pop	rbx
	pop	rax

	jmp	.filesystem_file_read_end

.filesystem_file_size:
	push	rax
	push	rdx
	push	rsi
	push	r8

	mov	rax,	rbx
	mov	r8,	variable_partition_specification_home
	mul	qword [r8 + KFS.knot_size]
	mov	rsi,	qword [r8 + KFS.knots_table_address]
	add	rsi,	rax

	mov	rcx,	qword [rsi + KNOT.size_in_bytes]

	pop	r8
	pop	rsi
	pop	rdx
	pop	rax

	; koniec obsługi procedury
	jmp	irq64.end

.filesystem_file_touch:
	push	r8

	mov	rax,	rdx
	mov	r8,	variable_partition_specification_home
	call	cyjon_filesystem_kfs_find_file
	jc	.filesystem_file_touch_exists

	call	cyjon_filesystem_kfs_file_create
	xor	rax,	rax	; tworzenie pliku przebiegło pomyślnie

	jmp	.filesystem_file_touch_end

.filesystem_file_touch_exists:
	mov	rax,	~VARIABLE_FALSE

.filesystem_file_touch_end:
	pop	r8

	; koniec obsługi procedury
	jmp	irq64.end

.filesystem_root_directory:
	push	r8

	mov	r8,	variable_partition_specification_home

	mov	rax,	rbx

	; przygotuj miejsce w przestrzeni pamięci procesu na plik

	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r11

	mul	qword [r8 + KFS.knot_size]
	mov	rsi,	qword [r8 + KFS.knots_table_address]
	add	rsi,	rax

	mov	rax,	qword [rsi + KNOT.size_in_bytes]
	xor	rdx,	rdx
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE
	div	rcx

	cmp	rdx,	VARIABLE_EMPTY
	je	.filesystem_root_directory_ok

	add	rax,	VARIABLE_INCREMENT

.filesystem_root_directory_ok:
	mov	rcx,	rax
	mov	rax,	rdi
	mov	rbx,	VARIABLE_MEMORY_HIGH_ADDRESS
	sub	rax,	rbx
	mov	rbx,	0x07	; flagi: Użytkownik, 4 KiB, Odczyt/Zapis, Dostępna
	mov	r11,	cr3
	call	cyjon_page_map_logical_area

	pop	r11
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	call	cyjon_filesystem_kfs_file_read

.filesystem_root_directory_end:
	pop	r8

	; koniec obsługi procedury
	jmp	irq64.end

; pozostała część w trakcie przepisywania
