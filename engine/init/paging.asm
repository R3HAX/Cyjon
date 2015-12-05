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

variable_page_pml4_address	dq	VARIABLE_EMPTY

;===============================================================================
; tworzy nowe tablice stronicowania opisując przestrzeń pamięci fizycznej względem utworzonej binarnej mapy pamięci
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
recreate_paging:
	; utworzenie nowego stronicowania specjalnie dla jądra
	; będzie skutkowało utworzeniem nowego stosu/stosu kontekstu jądra
	; zapamiętajmy adres powrotu z procedury
	mov	rax,	qword [rsp]
	; aby nie marnować niepotrzebnie miejsca, wykorzystamy przestrzeń już niepotrzebną
	mov	qword [recreate_paging],	rax

	; przygotuj miejsce dla tablicy PML4 jądra
	; tak dla własnego dobra, stosuję numeracje dla tablic
	; PML4, PML3(PDP), PML2(PD), PML1(PT) - prostrze i wygodniejsze
	call	cyjon_page_allocate
	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres fizyczny/logiczny tablicy PML4 jądra
	mov	qword [variable_page_pml4_address],	rdi

	; opisz w tablicach stronicowania jądra przestrzeń zarejestrowaną w binarnej mapie pamięci
	mov	rax,	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	; ustaw właściwości rekordów/stron w tablicach stronicowania
	mov	rbx,	3	; flagi: 4 KiB, Administrator, Odczyt/Zapis, Dostępna
	; opisz w tablicach stronicowania jądra przestrzeń o rozmiarze N stron
	mov	rcx,	qword [variable_binary_memory_map_total_pages]
	; załaduj adres fizyczny/logiczny tablicy PML4 jądra
	mov	r11,	rdi

	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_physical_area

	; utwórz stos/stos kontekstu dla jądra na końcu pierwszej połowy przestrzeni logicznej
	; przyjąłem, że jądro systemu otrzyma pierwszą połowę całej dostępnej przestrzeni pamięci logicznej
	; znaczne ułatwienie przy debugowaniu (bochs potrafi się sypać namiętnie)
	; tj. 0x0000000000000000 - 0x00007FFFFFFFFFFF
	; a pozostałe procesy/programy, drugą połowę
	; tj. 0xFFFF8000000000000000 - 0xFFFFFFFFFFFFFFFF
	mov	rax,	VARIABLE_KERNEL_STACK_ADDRESS	; ostatnia strona o rozmiarze 4 KiB
	mov	rcx,	1	; przeznacz jedną stronę na stos/stos kontekstu jądra systemu
	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_logical_area

	; przeładuj stronicowanie
	mov	rax,	qword [variable_page_pml4_address]
	mov	cr3,	rax

	; stronicowanie utworzone, pora wrócić z procedury
	; ustawiamy wskaźnik szczytu stosu na koniec przestrzeni stosu
	mov	rsp,	VARIABLE_KERNEL_STACK_ADDRESS + 0x1000

	; i wychodzimy z procedury, imitacją RET
	jmp	qword [recreate_paging]
