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

variable_page_semaphore_allocate	db	VARIABLE_EMPTY

cyjon_page_release_specified_area:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	mov	rax,	rdi
	mov	r11,	cr3
	call	cyjon_page_prepare_pml_variables

	xor	rax,	rax

.pml1:
	; przetworzono wszystkie rekordy w tablicy PML1?
	cmp	r12,	VARIABLE_MEMORY_PAGE_RECORD_COUNT
	je	.pml2	; poberz adres następnej talicy PML1 z rekordu w tablicy PML2

.pml1_continue:
	push	rdi
	mov	rdi,	qword [rdi]
	and	di,	0xF000	; usuń właściwości rekordu
	call	cyjon_page_release	; zwolnij stronę wykorzystaną do stronicowania
	pop	rdi

	; usuń rekord w tablicy PML1
	mov	qword [rdi],	rax
	add	rdi,	VARIABLE_QWORD_SIZE

	; zlicz ilość rekordów znajdujących się przed wskaźnikiem rdi
	inc	r12

	; sprawdź czy pozostały następne strony do zwolnienia
	dec	rcx
	jnz	.pml1

	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

.pml2:
	; przetworzono wszystkie rekordy w tablicy PML2?
	cmp	r13,	VARIABLE_MEMORY_PAGE_RECORD_COUNT
	je	.pml3	; poberz adres następnej talicy PML1 z rekordu w tablicy PML3

.pml2_continue:
	; pobierz adres nowej tablicy PML1
	mov	rdi,	qword [r9]
	add	r9,	VARIABLE_QWORD_SIZE
	; zlicz ilość rekordów znajdujących się przed wskaźnikiem r9
	inc	r13

	jmp	.pml1_continue

.pml3:
	; przetworzono wszystkie rekordy w tablicy PML3?
	cmp	r14,	VARIABLE_MEMORY_PAGE_RECORD_COUNT
	je	.pml4	; poberz adres następnej talicy PML1 z rekordu w tablicy PML4

.pml3_continue:
	; pobierz adres nowej tablicy PML2
	mov	r9,	qword [r10]
	add	r10,	VARIABLE_QWORD_SIZE
	; zlicz ilość rekordów znajdujących się przed wskaźnikiem r10
	inc	r14

	jmp	.pml2_continue

.pml4:
	; przetworzono wszystkie rekordy w tablicy PML4? Uh, że co kuźwa!?
	cmp	r15,	VARIABLE_MEMORY_PAGE_RECORD_COUNT
	je	cyjon_panic

	; pobierz adres nowej tablicy PML3
	mov	r10,	qword [r11]
	add	r11,	VARIABLE_QWORD_SIZE
	; zlicz ilość rekordów znajdujących się przed wskaźnikiem r11
	inc	r15

	jmp	.pml3_continue

;=======================================================================
; pobiera adres fizyczny wolnej strony do wykorzystania
; IN:
;	brak
; OUT:
;	rdi - adres wolnej strony, lub ZERO jeśli brak
;
; pozostałe rejestry zachowane
cyjon_page_allocate:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; wyczyść adres strony zwracanej
	xor	rdi,	rdi

	; sprawdź czy istnieją dostępne strony
	cmp	qword [variable_binary_memory_map_free_pages],	VARIABLE_EMPTY
	je	.end	; brak, zakończ procedurę

	; istnieją dostępne strony, zmniejsz ich ilość o jedną
	dec	qword [variable_binary_memory_map_free_pages]

.wait:
	; sprawdź czy binarna mapa pamięci jest dostępna do modyfikacji
	cmp	byte [variable_page_semaphore_allocate],	0x01
	je	.wait	; nie, czekaj na zwolnienie

	; zarezerwuj binarną mapę pamięci dla siebie
	mov	byte [variable_page_semaphore_allocate],	0x01

	; załaduj do wskaźnika źródłowego adres logiczny początku binarnej mapy pamięci
	mov	rsi,	qword [variable_binary_memory_map_address_start]
	; załaduj do wskaźnika docelowego adres logiczny końca binarnej mapy pamięci
	mov	rdi,	qword [variable_binary_memory_map_address_end]

	; przeszukaj binarną tablicę za dostępnym bitem
	call	library_find_free_bit

	; załaduj znaleziony bit
	mov	rdi,	rax

	; zamień całkowity numer bitu na względny adres strony
	shl	rdi,	12	; * 4096

	; w binarnej mapie pamięci opisaliśmy przestrzeń zaczynającą się od adresu fizycznego 0x0000000000100000
	; zamień adres fizyczny względny na bezwzględny
	add	rdi,	0x0000000000100000

.end:
	; zwolnij dostęp do binarnej mapy pamięci
	mov	byte [variable_page_semaphore_allocate],	VARIABLE_EMPTY

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; czyści zaalokowaną stronę wypełniając ją wartościami 0x0000000000000000
; IN:
;	rdi - adres strony do wyczyszczenia
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_page_clear:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; wyczyść stronę wartościami 0x0000000000000000
	xor	rax,	rax

	; ustaw licznik, rozmiar strony 4096 Bajtów / 8 Bajtów na rejestr
	mov	rcx,	VARIABLE_MEMORY_PAGE_SIZE / 8

.loop:
	mov	qword [rdi],	rax
	mov	qword [rdi + 0x08],	rax
	mov	qword [rdi + 0x10],	rax
	mov	qword [rdi + 0x18],	rax
	mov	qword [rdi + 0x20],	rax
	mov	qword [rdi + 0x28],	rax
	mov	qword [rdi + 0x30],	rax
	mov	qword [rdi + 0x38],	rax

	add	rdi,	0x40
	sub	rcx,	8
	jnz	.loop

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; procedura przygotowuje niezbędne informacje o tablicach PML[4,3,2,1]
; IN:
;	rax	- adres przestrzeni fizycznej/logicznej do opisania
;	rbx	- właściwości rekordów/stron
;	r11	- adres fizyczny tablicy PML4 jądra/procesu
; OUT:
;	rdi	- wskaźnik rekordu w tablicy PML1 względem otrzymanego adresu fizycznego/logicznego
;
;	r8	- wskaźnik kolejnego wolnego rekordu w tablicy PML1
;	r9	- wskaźnik kolejnego wolnego rekordu w tablicy PML2
;	r10	- wskaźnik kolejnego wolnego rekordu w tablicy PML3
;	r11	- wskaźnik kolejnego wolnego rekordu w tablicy PML4
;
;	r12	- numer kolejnego wolnego rekordu w tablicy PML1
;	r13	- numer kolejnego wolnego rekordu w tablicy PML2
;	r14	- numer kolejnego wolnego rekordu w tablicy PML3
;	r15	- numer kolejnego wolnego rekordu w tablicy PML4
;
; pozostałe rejestry zachowane
cyjon_page_prepare_pml_variables:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; oblicz numer rekordu w tablicy PML4 na podstawie otrzymanego adresu fizycznego/logicznego
	mov	rcx,	0x0000008000000000	; 512 GiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r15,	rax

	; zamień wynik całkowity na przesunięcie adres rekordu wewnątrz tablicy PML4
	shl	rax,	3	; * 8

	; przesuń adres tablicy PML4 na odpowiedni rekord
	add	r11,	rax

	; sprawdź czy rekord PML4 zawieta adres tablicy PML3
	cmp	qword [r11],	VARIABLE_EMPTY
	je	.no_pml3

	; pobierz adres tablicy PML3 z rekordu tablicy PML4
	mov	rax,	qword [r11]

	; usuń właściwości strony/rekordu z adresu tablicy PML3
	xor	al,	al

	; zapisz adres tablicy PML3
	mov	r10,	rax

	; przejdź do dalszych obliczeń
	jmp	.pml3_table

.no_pml3:
	; przygotuj miejsce na tablicę PML3
	call	cyjon_page_allocate
	; wyczyść stronę
	call	cyjon_page_clear

	; zapisz adres tablicy PML3
	mov	r10,	rdi

	; ustaw właściwości strony w rekordzie tablicy PML3
	or	di,	bx

	; zapisz wartość tablicy PML3 do rekordu tablicy PML4
	mov	qword [r11],	rdi

.pml3_table:
	; ustaw numer kolejnego wolnego rekordu w tablicy PML4
	inc	r15

	; ustaw wskaźnik kolejnego wolnego rekordu w tablicy PML4
	add	r11,	0x08

	; oblicz numer rekordu w PML3
	mov	rax,	rdx	; załaduj resztę z poprzedniego dzielenia
	mov	rcx,	0x0000000040000000	; 1 GiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r14,	rax

	; zamień wynik całkowity na przesunięcie wew. tablicy PML3
	shl	rax,	3	; rax*8

	; ustaw wskaźnik na rekord w tablicy PML3
	add	r10,	rax

	; sprawdź czy istnieje tablica PML2
	cmp	qword [r10],	VARIABLE_EMPTY
	je	.no_pml2

	; pobierz adres tablicy PML2 z rekordu tablicy PML3
	mov	rax,	qword [r10]

	; usuń właściwości strony/rekordu z adresu tablicy PML2
	xor	al,	al

	; zapisz adres tablicy PML2
	mov	r9,	rax

	; przejdź do dalszych obliczeń
	jmp	.pml2_table

.no_pml2:
	; przygotuj miejsce na tablicę PML2
	call	cyjon_page_allocate
	; wyczyść stronę
	call	cyjon_page_clear

	; zapisz adres tablicy PML2
	mov	r9,	rdi

	; ustaw właściwości strony w rekordzie tablicy PML2
	or	di,	bx

	; zapisz wartość tablicy PML2 do rekordu tablicy PML3
	mov	qword [r10],	rdi

.pml2_table:
	; ustaw numer kolejnego wolnego rekordu w tablicy PML3
	inc	r14

	; ustaw wskaźnik kolejnego wolnego rekordu w tablicy PML3
	add	r10,	0x08

	; oblicz numer rekordu w PML2
	mov	rax,	rdx	; załaduj resztę z poprzedniego dzielenia
	mov	rcx,	0x0000000000200000	; 2 MiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r13,	rax

	; zamień wynik całkowity na przesunięcie wew. tablicy PML2
	shl	rax,	3	; rax*8

	; ustaw wskaźnik na rekord w tablicy PML2
	add	r9,	rax

	; sprawdź czy istnieje tablica PML1
	cmp	qword [r9],	VARIABLE_EMPTY
	je	.no_pml1

	; pobierz adres tablicy PML1 z rekordu tablicy PML2
	mov	rax,	qword [r9]

	; usuń właściwości strony/rekordu z adresu tablicy PML1
	xor	al,	al

	; zapisz adres tablicy PML1
	mov	r8,	rax

	; przejdź do dalszych obliczeń
	jmp	.pml1_table

.no_pml1:
	; przygotuj miejsce na tablicę PML1
	call	cyjon_page_allocate
	; wyczyść stronę
	call	cyjon_page_clear

	; zapisz adres tablicy PML1
	mov	r8,	rdi

	; ustaw właściwości strony w rekordzie tablicy PML1
	or	di,	bx

	; zapisz wartość tablicy pml1 do rekordu tablicy PML2
	mov	qword [r9],	rdi

.pml1_table:
	; ustaw numer kolejnego wolnego rekordu w tablicy PML2
	inc	r13

	; ustaw wskaźnik kolejnego wolnego rekordu w tablicy PML2
	add	r9,	0x08

	; oblicz numer rekordu w PML1
	mov	rax,	rdx	; załaduj resztę z poprzedniego dzielenia
	mov	rcx,	0x0000000000001000	; 4 KiB
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx	; RAX / RCX

	; zapamiętaj numer rekordu
	mov	r12,	rax

	; zamień wynik całkowity na przesunięcie wew. tablicy PML1
	shl	rax,	3	; * 8

	; ustaw wskaźnik na rekord w tablicy PML1
	add	r8,	rax

	; załaduj wskaźnik do rekordu tablicy PML1
	mov	rdi,	r8

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret


;=======================================================================
; procedura udostępnia przestrzeń logiczną podpinając wolne strony z pamięci fizycznej
; IN:
;	rax	- adres przestrzeni logicznej do opisania
;	rbx	- właściwości rekordów/stron
;	rcx	- ilość ramek do opisania
;	r11	- adres fizyczny tablicy PML4 jądra/procesu
; OUT:
;	r8	- adres ostatnio mapowanej strony z tablicy PML1
;
; pozostałe rejestry zachowane
cyjon_page_map_logical_area:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; przygotuj zmienne
	call	cyjon_page_prepare_pml_variables

.loop:
	; sprawdź czy tablica PML1 jest pełna
	cmp	r12,	512
	jb	.ok	; jeśli tak, utwórz nową tablicę PML1

	; utwórz nową tablicę PML1
	call	cyjon_page_new_pml1

.ok:
	; sprawdź czy rekord jest już zarezerwowany
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.continue

	; przesuń wskaźnik na następy rekord
	add	rdi,	0x08

	; następna strona
	jmp	.leave

.continue:
	; zachowaj
	push	rdi

	; pobierz adres strony do opisania w przestrzeni logicznej
	call	cyjon_page_allocate
	call	cyjon_page_clear

	; zapamiętaj adres strony
	mov	rax,	rdi

	; przywróć
	pop	rdi

	; ustaw flagi
	or	ax,	bx
	stosq	; zapisz do tablicy PML1[r12]

	; sprzężenie zwrotne
	; jeśli jest to ostatnia ramka do opisania i zarazem ostatnia jednocześnie w tablicach PML1,2,3 oraz 4
	; może wystąpić przepełnienie stronicowania, jeśli nie wykona się testu ilości pozostałych ramek
	cmp	rcx,	0x0000000000000001
	je	.end

.leave:
	; zwiększ ilość rekordów przechowywanych w tablicy PML1
	inc	r12

	; opisz następne strony w tablicy PML1
	loop	.loop

.end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; PODPROCEDURA tworzy nową tablicę PML1 o podanym adresie logicznym
; IN:
;	rax	- adres przestrzeni fizycznej/logicznej do opisania
;	rbx	- właściwości rekordów/stron
;	r11	- adres fizyczny tablicy PML4 jądra/procesu
; OUT:
;	rdi	- wskaźnik rekordu w tablicy PML1 względem otrzymanego adresu fizycznego/logicznego
;
;	r8	- wskaźnik kolejnego wolnego rekordu w tablicy PML1
;	r9	- wskaźnik kolejnego wolnego rekordu w tablicy PML2
;	r10	- wskaźnik kolejnego wolnego rekordu w tablicy PML3
;	r11	- wskaźnik kolejnego wolnego rekordu w tablicy PML4
;
;	r12	- numer kolejnego wolnego rekordu w tablicy PML1
;	r13	- numer kolejnego wolnego rekordu w tablicy PML2
;	r14	- numer kolejnego wolnego rekordu w tablicy PML3
;	r15	- numer kolejnego wolnego rekordu w tablicy PML4
;
; pozostałe rejestry zachowane
cyjon_page_new_pml1:
	; sprawdź czy tablica pml2 jest pełna
	cmp	r13,	512
	je	.pml3	; jeśli tak, utwórz nową tablicę pml2

	; pobierz nastepny rekord z tablicy pml2
	mov	rdi,	qword [r9]

	; sprawdź czy jest już opisany
	cmp	rdi,	VARIABLE_EMPTY
	je	.continue_pml2	; jesli nie

	; usuń właściwości z adresu tablicy pml1
	and	di,	0xF000

	; zapamiętaj adres tablicy pml1
	mov	r8,	rdi

	; zresetuj numer rekordu w tablicy pml1
	xor	r12,	r12

	; pomiń tworzenie nowej tablicy pml1
	jmp	.leave_pml2

.continue_pml2:
	; przygotuj miejsce na tablicę PML1
	call	cyjon_page_allocate
	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres tablicy pml1
	mov	r8,	rdi

	; zresetuj numer rekordu w tablicy pml1
	xor	r12,	r12

	; ustaw właściwości tablicy pml1
	or	di,	dx

	; podepnij tablice pml1 pod rekord tablicy pml2[r13]
	mov	qword [r9],	rdi

	; usuń właściwości z adresu tablicy pml1
	and	di,	0xF000

.leave_pml2:
	; ustaw numer następnego rekordu w tablicy pml2
	inc	r13

	; ustaw wskaźnik następnego rekordu w tablicy pml2
	add	r9,	 0x08

	; kontynuuj
	ret

.pml3:
	; sprawdź czy tablica pml3 jest pełna
	cmp	r14,	512
	je	.pml4	; jeśli tak, utwórz nową tablicę pml3

	; pobierz nastepny rekord z tablicy pml3
	mov	rdi,	qword [r10]

	; sprawdź czy jest już opisany
	cmp	rdi,	VARIABLE_EMPTY
	je	.continue_pml3	; jesli nie

	; usuń właściwości z adresu tablicy pml2
	and	di,	0xF000

	; zapamiętaj adres tablicy pml2
	mov	r9,	rdi

	; zresetuj numer rekordu w tablicy pml2
	xor	r13,	r13

	; pomiń tworzenie nowej tablicy pml1
	jmp	.leave_pml3

.continue_pml3:
	; przygotuj miejsce na tablicę PML2
	call	cyjon_page_allocate
	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres tablicy pml2
	mov	r9,	rdi

	; zresetuj numer rekordu w tablicy pml2
	xor	r13,	r13

	; ustaw właściwości tablicy pml2
	or	di,	dx

	; podepnij tablice pml2 pod rekord tablicy pml3[r14]
	mov	qword [r10],	rdi

.leave_pml3:
	; ustaw numer następnego rekordu w tablicy pml3
	inc	r14

	; ustaw wskaźnik następnego rekordu w tablicy pml3
	add	r10,	 0x08

	; kontynuuj
	jmp	cyjon_page_new_pml1

.pml4:
	; sprawdź czy tablica pml4 jest pełna
	cmp	r15,	512
	je	cyjon_panic	; jeśli tak, utwórz nową tablicę pml5, o cholewcia!

	; pobierz nastepny rekord z tablicy pml4
	mov	rdi,	qword [r11]

	; sprawdź czy jest już opisany
	cmp	rdi,	VARIABLE_EMPTY
	je	.continue_pml4	; jesli nie

	; usuń właściwości z adresu tablicy pml3
	and	di,	0xF000

	; zapamiętaj adres tablicy pml3
	mov	r10,	rdi

	; zresetuj numer rekordu w tablicy pml3
	xor	r14,	r14

	; pomiń tworzenie nowej tablicy pml3
	jmp	.leave_pml4

.continue_pml4:
	; przygotuj miejsce na tablicę PML3
	call	cyjon_page_allocate
	; wyczyść stronę
	call	cyjon_page_clear

	; zapamiętaj adres tablicy pml3
	mov	r10,	rdi

	; zresetuj numer rekordu w tablicy pml3
	xor	r14,	r14

	; ustaw właściwości tablicy pml3
	or	di,	dx

	; podepnij tablice pml3 pod rekord tablicy pml4[r15]
	mov	qword [r11],	rdi

.leave_pml4:
	; ustaw numer następnego rekordu w tablicy pml4
	inc	r15

	; ustaw wskaźnik następnego rekordu w tablicy pml4
	add	r11,	 0x08

	; kontynuuj
	jmp	.pml3

cyjon_panic:
	jmp	$

;=======================================================================
; procedura przekazuje wykorzystywaną stronę do puli wolnych
; IN:
;	rdi	- adres strony do zwolnienia
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_page_release:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; przelicz na adres względny
	sub	rdi,	0x0000000000100000

	; przenieś bezwzględny adres fizyczny ramki do akumulatora
	mov	rax,	rdi
	; zamień na numer ramki
	shr	rax,	12

	; oblicz przesunięcie względem początku binarnej mapy pamięci
	xor	rdx,	rdx	; wyczyść resztę/"starszą część"
	mov	rcx,	64	; 64 bity na rejestr
	div	rcx	; rdx:rax / rcx

	; ustaw wskaźnik na początek binarnej mapy pamięci
	mov	rdi,	qword [variable_binary_memory_map_address_start]

	; dodaj do adresu wskaźnika przesunięcie
	shl	rax,	3	; zamień na Bajty
	add	rdi,	rax

	; wykonujemy "lustrzane odbicie" numeru pozycji bitu w rejestrze
	mov	rcx,	63	; przekształć wskaźnik bitu
	sub	rcx,	rdx	; w numer pozycji (lustrzane odbicie)

.wait:
	; czekaj na zwolnienie binarnej mapy pamięci
	cmp	byte [variable_page_semaphore_allocate],	VARIABLE_EMPTY
	jne	.wait

	; zarezerwuj binarną mapę pamięci
	mov	byte [variable_page_semaphore_allocate],	0x01

	; pobierz zestaw 64 bitów z binarnej mapy pamięci
	mov	rax,	qword [rdi]
	; ustaw bit odpowiadający za zwalnianą ramkę
	bts	rax,	rcx

	; zaaktualizuj binarną mapę pamięci
	stosq

	; zwiększamy ilość dostępnych stron o jedną
	inc	qword [variable_binary_memory_map_free_pages]

	; zwolnij binarną mapę pamięci
	mov	byte [variable_page_semaphore_allocate],	VARIABLE_EMPTY

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;=======================================================================
; procedura wyszukuje i rezerwuje przestrzeń o podanym rozmiarze (ilość stron) w przestrzeni logicznej
; IN:
;	rcx	- ilość stron do zarezerwowania
; OUT:
;	rdi	- adres przestrzeni zarezerwowanej o podanym rozmiarze
;
; pozostałe rejestry zachowane
cyjon_page_find_free_memory:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; początek przestrzeni przeszukiwanej
	mov	rax,	VARIABLE_MEMORY_FREE_LOGICAL_ADDRESS

	; właściwości rejestrowanej przestrzeni
	mov	bx,	0x07	; flagi Administrator, Odczyt/Zapis, Dostępna

	; adres tablicy PML4 jądra
	mov	r11,	cr3

	; przygotuj procedure
	call	cyjon_page_prepare_pml_variables

	; zachowaj oryginalne rejestry
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	push	rax
	push	rcx

.loop:
	; sprawdź czy koniec tablicy pml1
	cmp	r12,	512
	jb	.nope

	; przygotuj przestrzeń do sprawdzenia
	call	cyjon_page_new_pml1

.nope:
	; przesuń na następny aktualny numer rekordu
	inc	r12
	; przesuń na następny wskaźnik adresu rekordu w tablicy pml1
	add	rdi,	0x08
	; aktualizuj adres początku przestrzeni rozpatrywanej jako dostępna
	add	rax,	0x1000

	; sprawdź czy przestrzeń była nieopisana
	cmp	qword [rdi - 0x08],	VARIABLE_EMPTY
	je	.next

	; przywróć oryginalny rozmiar poszukiwanej przestrzeni
	mov	rcx,	qword [rsp]
	; zachowaj nowy adres przestrzeni
	mov	qword [rsp + 0x08],	rax

	; aktualizuj zmienne
	mov	qword [rsp + 0x10],	r15
	mov	qword [rsp + 0x18],	r14
	mov	qword [rsp + 0x20],	r13
	mov	qword [rsp + 0x28],	r12
	mov	qword [rsp + 0x30],	r11
	mov	qword [rsp + 0x38],	r10
	mov	qword [rsp + 0x40],	r9
	mov	qword [rsp + 0x48],	r8
	mov	qword [rsp + 0x50],	rdi

	; szukaj od nowa
	jmp	.loop

.next:
	; szukaj dalej
	loop	.loop

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rax

	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi

.continue:
	; sprawdź czy znaleziono przestrzeń wolną
	cmp	rax,	VARIABLE_EMPTY
	je	.no

	; zachowaj adres
	push	rax

	; przywróć adres tablicy PML4 jądra
	mov	r11,	cr3

	; opisz znalezioną przestrzeń
	call	cyjon_page_map_logical_area

	; załaduj adres znalezionej i zarejestrowanej przestrzeni
	pop	rdi

	; zakończ obsługę procedury
	jmp	.end

.no:
	; zwróć błąd
	xor	rdi,	rdi

.end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

cyjon_page_release_area:
	; wejdź do następnego poziomu tablicy PML
	dec	rbx
	mov	rcx,	512	; ilość rekordów do zwolnienia w następnym poziomie tablicy PML

	; aktualna tablica PML1?
	cmp	rbx,	0x01
	je	.continue	; jeśli tak, kontynuuj

.loop:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; sprawdź czy rekord jest pusty
	cmp	qword [rdi],	VARIABLE_EMPTY
	je	.empty	; jeśli nie, kontynuuj

	; pobierz adres tablicy następnego poziomu tablicy PML
	mov	rdi,	qword [rdi]
	and	di,	0xFF00	; usuń flagi z adres następnej tablicy PML

	; zapamiętaj adres nowej tablicy PML
	push	rdi

	; rekurencja, do czasu wejścia do tablicy PML1
	call	cyjon_page_release_area

	; przywróć adres tablicy PML aktualnie przetwarzanego rekordu
	pop	rdi

	; zwolnij przestrzeń
	call	cyjon_page_release

	; wróć do poprzedniego poziomu tablicy PML
	inc	rbx

.empty:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; następny rekord aktualnej tablicy PML
	add	rdi,	0x08

	; przeszukaj kolejne rekordy
	loop	.loop

.end:
	; powrót z procedury
	ret

.continue:
	; sprawdź czy rekord jest pusty
	cmp	qword [rdi],	VARIABLE_EMPTY
	jne	.after	; jeśli nie, zwolnij przestrzeń opisywaną przez rekord

.next:
	add	rdi,	0x08	; następny rekord
	loop	.continue

	; powrót z procedury
	ret

.after:
	; zachowaj oryginalny rejestr
	push	rdi

	; pobierz adres przestrzeni do zwolnienia
	mov	rdi,	qword [rdi]
	and	di,	0xFF00	; usuń flagi

	; zwolnij przestrzeń
	call	cyjon_page_clear
	call	cyjon_page_release

	;przywróć oryginalny rejestr
	pop	rdi

	; przetwórz następny rekord
	jmp	.next

;=======================================================================
; procedura udostępnia przestrzeń logiczną znadującą się w pod tym samym adresem fizycznym
; IN:
;	rax	- adres przestrzeni fizycznej do opisania
;	rbx	- właściwości rekordów/stron
;	rcx	- ilość stron do opisania
;	r11	- adres fizyczny tablicy PML4 jądra/procesu
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_page_map_physical_area:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; przygotuj procedure
	call	cyjon_page_prepare_pml_variables

	; zapamiętaj właściwości
	mov	rdx,	rbx

	; połącz właściwości z adresem pierwszej strony fizycznej
	add	rbx,	rax

.record:
	; sprawdź czy tablica pml1 jest pełna
	cmp	r12,	512
	jb	.ok	; jeśli tak, utwórz nową tablicę pml1

	; utwórz nową tablicę pml1
	call	cyjon_page_new_pml1

.ok:
	; załaduj adres i właściwości ramki do akumulatora
	mov	rax,	rbx

	; zapisz do rekordu tablicy pml1[r12]
	stosq

	; przesuń przesuń adres na nastepną ramkę
	add	rbx,	0x1000

	; sprzężenie zwrotne
	cmp	rcx,	1
	je	.end

	; ustaw numer następnego rekordu w tablicy pml1
	inc	r12

	; kontynuuj
	loop	.record

.end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
