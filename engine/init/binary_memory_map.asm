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

; 64 bitowy kod
[BITS 64]

variable_binary_memory_map_address_start	dq	VARIABLE_EMPTY
variable_binary_memory_map_address_end		dq	VARIABLE_EMPTY
variable_binary_memory_map_total_pages		dq	VARIABLE_EMPTY
variable_binary_memory_map_free_pages		dq	VARIABLE_EMPTY

text_binary_memory_map_fail			db	"Create binary memory map, fail.", VARIABLE_ASCII_CODE_TERMINATOR
text_available_memory				db	" Available memory: ", VARIABLE_ASCII_CODE_TERMINATOR

; Multiboot Information Structure
struc	MIS
	.flags		resd	1
	.ignore		resb	40
	.mmap_length	resd	1
	.mmap_addr	resd	1
endstruc

; struktura tablicy mapy pamięci oprogramowania GRUB
struc	MMAP_STRUCTURE
	.record_size	resd	1
	.base_address	resq	1
	.memory_amount	resq	1
	.flags		resd	1
endstruc

;===============================================================================
; tworzy binarną mapę pamięci za kodem jądra systemu operacyjnego
; IN:
;	rbx - 
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

	; sprawdź jakie oprogramowanie załadowało jądro systemu do pamięci
	cmp	byte [variable_bootloader_own],	VARIABLE_TRUE
	je	.next

	; GRUB Bootloader
	bt	word [rbx + MIS.flags],	6
	jnc	.fail

	; pobierz rozmiar mapy pamięci
	mov	ecx,	dword [rbx + MIS.mmap_length]

	; ustaw wskaźnik na początek mapy pamięci
	mov	ebx,	dword [ebx + MIS.mmap_addr]

.next_record:
	; sprawdź czy opisany jest adres VARIABLE_KERNEL_PHYSICAL_ADDRESS
	mov	rax,	qword [rbx + MMAP_STRUCTURE.base_address]
	cmp	rax,	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	je	.found_grub

	; zmiejsz ilość przeszukiwanych danych
	sub	ecx,	dword [rbx + MMAP_STRUCTURE.record_size]
	jz	.fail

	; przesuń wskaźnik na następny rekord
	add	ebx,	dword [rbx + MMAP_STRUCTURE.record_size]
	add	ebx,	0x04	; korekcja

	; następny rekord
	jmp	.next_record

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

.fail:
	; ustaw ciag zawierający opis błędu
	mov	rsi,	text_binary_memory_map_fail
	jmp	cyjon_screen_kernel_panic	; wyświetl

.found_grub:
	; ustaw wskaźnik na rozmiar przestrzeni
	mov	esi,	ebx
	add	esi,	MMAP_STRUCTURE.memory_amount

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
	mov	rdi,	kernel_end

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

	; wyświetl informacje o zasobach pamięci RAM
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
	mov	rcx,	10	; dziesiętny system liczbowy
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
