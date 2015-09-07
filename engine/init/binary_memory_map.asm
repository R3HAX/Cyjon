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

; 64 bitowy kod
[BITS 64]

variable_binary_memory_map_address_start	dq	VARIABLE_EMPTY
variable_binary_memory_map_address_end		dq	VARIABLE_EMPTY
variable_binary_memory_map_total_pages		dq	VARIABLE_EMPTY
variable_binary_memory_map_free_pages		dq	VARIABLE_EMPTY

text_binary_memory_map_fail			db	"Binary Memory Map fail, I cannot find the size of memory available at 0x00100000.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, "System halted.", VARIABLE_ASCII_CODE_TERMINATOR
text_available_memory				db	" Available memory: ", VARIABLE_ASCII_CODE_TERMINATOR

;===============================================================================
; tworzy binarną mapę pamięci za kodem jądra systemu operacyjnego
; IN:
;	rsi - adres tablicy mapy pamięci utworzonej przez program rozruchowy
; OUT:
;	brak
;
; wszystkie rejestry zachowane
binary_memory_map:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

.next:
	; pobierz z tablicy mapy pamięci adres opisanej przestrzeni pamięci fizycznej
	lodsq	; rax

	; sprawdź czy jest to interesujący nas fragment przestrzeni pamięci fizycznej
	cmp	rax,	0x0000000000100000
	je	.found

	; przesuń wskaźnik na następny rekord tablicy mapy pamięci
	add	rsi,	16

	; sprawdź czy koniec tablicy mapy pamięci
	cmp	qword [rsi],	VARIABLE_EMPTY
	jne	.next

	; nie można odnaleźć wymaganego rekordu, dalsza inicjalizacja jądra systemu jest niemożliwa

	; ustaw ciag zawierający opis błędu
	mov	rsi,	text_binary_memory_map_fail
	jmp	cyjon_screen_kernel_panic	; wyświetl

.found:
	; znaleziono rekord opisujący poszukiwany fragment przestrzeni pamięci fizycznej
	; pobierz rozmiar opisanego fragmentu przestrzeni pamięci fizycznej
	lodsq

	; przy poniższych przeliczeniach, możemy stracić dostęp do paru ramek pamięci fizycznej
	; max. 64 * 4 KiB, zastosowałem ten sposób dla czytelniejszego kodu

	; przelicz rozmiar przestrzeni na liczbe stron po 4 KiB, każda
	shr	rax,	12	; / 4096

	; zapamiętaj
	mov	qword [variable_binary_memory_map_total_pages],	rax
	mov	qword [variable_binary_memory_map_free_pages],	rax

	; przelicz liczbę stron na ilość "pakietów" po 64 bity, każdy
	shr	rax,	6	; / 64

	; wyliczamy pozycję naszej nowej binarnej mapy pamięci
	; ustawimy ją za kodem jądra systemu
	; adres wyrównamy do pełnej strony (w górę)
	mov	rdi,	end

	; wyrównaj adres do pełnej strony
	call	library_align_address_up_to_page

	; zapisz adres początku binarnej mapy pamięci
	mov	qword [variable_binary_memory_map_address_start],	rdi

	; jeden "pakiet" składa się z 64 bitów/stron
	mov	rcx,	-1	; 0xffffffffffffffff == 11111111[..48..]11111111b
	; ustaw wartości na swoje miejsca
	xchg	rax,	rcx
	; uzupełnij binarną mapę pamięci
	rep	stosq

	; zapisz adres końca binarnej mapy pamięci
	mov	qword [variable_binary_memory_map_address_end],	rdi

	; binarna mapa pamięci utworzona, należy teraz wyłączyć w binarnej mapie pamięci
	; bity opisujące przestrzeń zajętą przez jądro i binarną mapę pamięci zarazem

	; wyrównaj adres końca binarnej mapy pamięci do pełnej strony
	call	library_align_address_up_to_page

	; oblicz rozmiar zajętej pamięci przez jądro i binarną mapę pamięci łącznie
	sub	rdi,	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	; zamień na ilość stron po 4 KiB
	shr	rdi,	12	; / 4096

	; bity wyłączymy w najprostrzy sposób, poprosimy o adresy N pierwszych ramek (no nie da się prościej)
	; odpowiedzi zignorujemy

	; ustaw licznik stron do pobrania/zablokowania/wyłączenia
	mov	rcx,	rdi

.disable:
	; pobierz pierwszą dostępną stronę
	call	cyjon_page_allocate

	; wykonaj raz jeszcze
	loop	.disable

	; wyświetl informacje o inicjalizacji wirtulnego systemu plików
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_available_memory
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	rax,	qword [variable_binary_memory_map_total_pages]
	shl	rax,	2	; zamień strony na KiB
	mov	rcx,	10	; system liczbowy
	call	cyjon_screen_print_number

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_kib
	call	cyjon_screen_print_string

	mov	rsi,	text_paragraph
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
