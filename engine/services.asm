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
	cmp	ah,	0x00
	je	irq64_process

	; czy zarządzać ekranem?
	cmp	ah,	0x01
	je	irq64_screen

	; czy zarządzać klawiaturą?
	cmp	ah,	0x02
	je	irq64_keyboard

.end:
	; powrót z przerwania programowanego
	iretq

;===============================================================================
irq64_process:
	; sprawdź czy zamknąć proces
	cmp	al,	0x00
	je	.process_kill

	; uruchomić nowy proces?
	cmp	al,	0x01
	je	.process_new

	; sprawdzić czy proces istnieje?
	cmp	al,	0x02
	je	.process_check

	; brak obsługi
	jmp	irq64.end

.process_kill:
	; sprawdź czy jądro jest gotowe przyjąć polecenie zamknięcia procesu
	cmp	qword [variable_process_close],	0x0000000000000000
	ja	.process_kill	; czekaj

	; zatrzymaj aktualnie uruchomiony proces
	mov	rax,	qword [variable_process_table_record_active]
	mov	qword [variable_process_close],	rax

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
	cmp	byte [variable_process_semaphore_init],	0x00
	jne	.process_new_found	; czekaj

	; zarezerwuj procedure
	mov	byte [variable_process_semaphore_init],	0x01

	; poinformuj jądro systemu o potrzebie uruchomienia nowego procesu
	mov	qword [variable_process_new],	rdi

.process_new_check:
	; sprawdź czy proces został uruchomiony
	cmp	qword [variable_process_pid],	0x0000000000000000
	je	.process_new_check	; jeśli nie, czekaj dalej

	; pobierz numer PID uruchomionego procesu
	xor	rcx,	rcx
	xchg	rcx,	qword [variable_process_pid]

	; zwolnij procedure uruchamiania nowego procesu
	mov	byte [variable_process_semaphore_init],	0x00

.process_new_end:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi

	; koniec obsługi procedury
	jmp	irq64.end

.process_check:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; pobierz adres tablicy procesów
	mov	rdi,	qword [variable_process_table_address]

	; zamień numer PID na przesunięcie
	shl	rcx,	4

	; sprawdź czy proces jest uruchomiony
	cmp	qword [rdi + rcx],	0x0000000000000000
	jne	.process_check_exists

	; brak procesu
	mov	qword [rsp + 0x08],	0x0000000000000000

.process_check_exists:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; koniec obsługi procedury
	jmp	irq64.end

;===============================================================================
irq64_screen:
	; sprawdź czy wyczyścić ekran
	cmp	al,	0x00
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
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdi

	; wyłącz kursor
	call	cyjon_screen_cursor_lock

	; sprawdź czy kursor będzie znajdował się poza ekranem
	cmp	dword [variable_video_mode_chars_x],	ebx
	jb	.ok

	; koryguj
	mov	ebx,	dword [variable_video_mode_chars_x]

.ok:
	; aktualizuj pozycje kursora X
	mov	dword [variable_screen_cursor_xy],	ebx

	; zamień wartości miejscami
	ror	rbx,	32

	; sprawdź czy kursor będzie znajdował się poza ekranem
	cmp	dword [variable_video_mode_chars_y],	ebx
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

	; włącz kursor
	call	cyjon_screen_cursor_unlock

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rbx

	; koniec obsługi procedury
	jmp	irq64.end

.screen_information:
	; zwróć informacje o rozmiarze ekranu w znakach
	mov	eax,	dword [variable_video_mode_chars_y]
	shl	rax,	32
	or	rax,	qword [variable_video_mode_chars_x]

	; koniec obsługi procedury
	jmp	irq64.end

;===============================================================================
irq64_keyboard:
	; sprawdź czy pobrać znak z bufora klawiatury
	cmp	al,	0x00
	je	.keyboard_get_key

	; brak obsługi
	jmp	irq64.end

.keyboard_get_key:
	; pobierz kod ASCII klawisza z bufora klawiatury
	call	cyjon_keyboard_key_read

	; koniec obsługi procedury
	jmp	irq64.end

; pozostała część w trakcie przepisywania
