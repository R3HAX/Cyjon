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

struc	RECORD
	.record_size	resb	1
	.reserved	resb	1
	.count		resw	1
	.offset		resw	1
	.segment	resw	1
	.lba		resq	1
endstruc

; 16 Bitowy kod programu
[BITS 16]

; położenie kodu programu w pamięci fizycznej 0x1000:0x0000
[ORG 0x1000]

start:
	; zachowaj numer urzędzenia z którego nastąpił odczyt
	push	dx

	; wyłączamy wszystkie przerwania sprzętowe (PIC)
	mov	al,	11111111b
	out	0xA1,	al
	out	0x21,	al

	; sprawdź typ procesora
	call	check_cpu

	; poinformuj o dostępności procesora 64 bitowego
	mov	si,	text_cpu
	call	print_16bit

	; odblokuj bramę A20
	call	unlock_a20

	; poinformuj o odblokowanej bramie a20
	mov	si,	text_a20
	call	print_16bit

	; utwórz mapę pamięci za pomocą przerwania 0x15, procedury 0xE820
	call	memory_map

	; poinformuj o utworzeniu mapy pamięci
	mov	si,	text_memory
	call	print_16bit

	; przywróć numer urządzenia z którego nastapił odczyt
	pop	dx

	; załaduj plik jądra systemu do przestrzeni tymczasowej
	call	load_kernel

	; poinformuj o załadowaniu jądra do pamięci fizycznej
	mov	si,	text_kernel
	call	print_16bit

	; WYBIERZ TRYB PROCESORA NA PODSTAWIE NAGŁÓWKA ZAŁADOWANEGO JĄDRA SYSTEMU
	;-----------------------------------------------------------------------

	; nie włączaj trybu graficznego dla jądra systemu 16 bitowego
	cmp	byte [es:0x0000],	0x10
	je	.missing

	; ustaw tryb graficzny 800x600@32bpp
	mov	ax,	0x4F00
	mov	edi,	supervga_info
	int	0x10	; pobierz informacje o dostępnych trybach graficznych obsługiwanych przez kartę graficzną

	; przesuń wskaźnik komórkę zawierającą adres tablicy obsługiwanych trybów
	add	edi,	0x0E
	; pobierz adres z komórki
	mov	edi,	dword [edi]

.search:
	mov	ax,	word [di]

	; sprawdź czy koniec tablicy
	cmp	ax,	0xFFFF
	je	.missing	; pozostaw tryb tekstowy

	; szukaj zalecanego trybu graficznego
	cmp	ax,	0x0100	; 640x400@8bpp
	je	.found

	; przesuń wskaźnik na następną pozycję
	add	edi,	0x02

	; kontynuuj przeszukiwanie
	jmp	.search	

.found:
	; pobierz informacje o trybie graficznym
	mov	ax,	0x4F01
	mov	ecx,	0x0100	; 640x400@8bpp
	mov	edi,	supervga_mode
	int	0x10	; wykonaj

	; przełącz na tryb graficzny
	mov	ax,	0x4F02
	mov	ebx,	0x4100	; wyłącz banki pamięci, linear frame buffer
	int	0x10	; wykonaj

.missing:
	; załaduj do rejestru segmentowego ekstra adres położenia kodu jądra systemu
	push	0x1000
	pop	es

	; wyczyść zbędne rejestry
	xor	ebx,	ebx

	; sprawdź czy włączono tryb graficzny
	cmp	word [ds:supervga_mode + 0x12],	0x0000	; rozdzielczość X
	je	.text_mode

	; poinformuj jądro systemu o pozycji tablicy informacyjnej trybu graficznego
	mov	ebx,	supervga_mode

.text_mode:
	; sprawdź, czy kod jądra systemu jest 16 Bitowy
	cmp	byte [es:0x0000],	0x10	; 16
	ja	.no	; kod jądra systemu nie jest 16 Bitowy, przejdź do trybu chronionego (32 Bitowego)

	; wyczyść zbędne rejestry
	xor	ecx,	ecx
	and	edx,	0x000000FF	; zachowaj numer urządzenia z którego nastąpił odczyt jądra systemu
	xor	edi,	edi

	; ustaw segment danych na prawidłowe miejsce
	mov	ax,	0x1000
	mov	ds,	ax
	; zapamiętaj
	push	ax

	; wyczyść zbędne rejestry
	xor	eax,	eax

	; zwróć informacje o pozycji utworzonej mapy pamięci
	mov	esi,	0x00000500

	; ustaw segment ekstra na prawidłowe miejsce
	pop	es

	; skocz do kodu jądra systemu operacyjnego 16 Bitowego
	pushf	; odłóż flagi na stos
	push	0x1000	; odłóż na stos segment kodu jądra systemu
	push	0x0001	; odłóż na stos IP początku kodu jądra systemu
	iretw	; skocz do kodu jądra systemu
	
.no:
	; wyłącz obsługę wyjątków i przerwań
	cli

	; załaduj globalną tablicę deskryptorów
	lgdt	[gdt_structure_32bit]

	; przełącz procesor w tryb 32 bitowy
	mov	eax,	cr0
	bts	eax,	0	; włącz pierwszy bit rejestru cr0
	mov	cr0,	eax	; aktualizuj

	; skocz do 32 bitowego kodu
	jmp	long 0x0008:protected_mode

check_cpu:
	; sprawdź czy procesor obsługuje tryb 64 bitowy
	mov	eax,	0x80000000	; procedura - pobierz numer najwyższej dostępnej procedury
	cpuid	; wykonaj

	cmp	eax,	0x80000000	; spradź czy istnieją procedury powyżej 80000000h
	jbe	.error	; jeśli nie, koniec

	mov	eax,	0x80000001	; procedura - pobierz informacja o procesorze i poszczególnych funkcjach
	cpuid	; wykonaj

	bt	edx,	29	; sprawdź czy wspierany jest tryb 64 bitowy (29 bit "lm" LongMode, rejestru edx)
	jnc	.error	; jeśli nie, koniec

	; procesor wspiera tryb 64-bitowy

	; powrót z procedury
	ret

.error:
	; brak procesora 64 Bitowego
	mov	si,	text_no_cpu
	call	print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

unlock_a20:
	; spradź czy brama a20 jest odblokowana (nie wyważaj otwartych drzwi)
	call	check_a20
	jc	a20_by_bios	; jeśli nie, spróbuj za pomocą BIOSu

	; brama a20 odblokowana

	; powrót z procedury
	ret

a20_by_bios:
	; odblokuj brama a20 za pomocą funkcji BIOSu
	mov	ax,	0x2401
	int	0x15	; wykonaj

	; spradź czy brama a20 jest odblokowana
	call	check_a20
	jc	a20_by_keyboard	; jeśli nie, odblokuj za pomocą kontrolera klawiatury

	; brama a20 odblokowana

	; powrót z procedury
	ret

a20_by_keyboard:
	; wyłącz przerwania
	cli

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    wait_for_keyboard_in

	; wyłącz klawiaturę
	mov	al,	0xAD
	out	0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    wait_for_keyboard_in

	; poproś o możliwość odczytania danych z portu klawiatury
	mov     al,	0xD0
	out     0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa dać odpowiedź
	call    wait_for_keyboard_out

	; pobierz z portu klawiatury informacje
	in      al,	0x60

	; zapamiętaj wiadomość
	push    ax

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    wait_for_keyboard_in

	; poproś o możliwość zapisania danych do portu klawiatury
	mov     al,	0xD1
	out     0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    wait_for_keyboard_in

	; przywróć poprzednią wiadomość
	pop     ax

	; ustaw drugi bit rejestru AL
	or      al,	2
	out     0x60,	al	; wyślij do konrolera klawiatury

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    wait_for_keyboard_in

	; włącz klawiaturę
	mov     al,	0xAE
	out     0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    wait_for_keyboard_in

	; włącz przerwania
	sti

	; spradź czy brama a20 jest odblokowana
	call	check_a20
	jc	a20_by_fastgate	; jeśli nie, spróbuj za pomocą FatGate

	; brama a20 odblokowana

	; powrót z procedury
	ret

a20_by_fastgate:
	; pobierz status z rejestru System Control Port A
	in	al,	0x92
	test	al,	2	; sprawdź czy drugi bit jest równy zero
	jnz	.end		; jeśli nie, koniec

	; włącz 2 bit
	or	al,	2
	and	al,	0xFE
	out	0x92,	al	; wyślij

.end:
	; spradź czy brama a20 jest odblokowana
	call	check_a20
	jc	.error	; no i pies pogrzebany

	; brama a20 odblokowana

	; powrót z procedury
	ret

.error:
	; wyświetl informacje o zablokowanej linii A20
	mov	si,	text_no_a20
	call	print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

check_a20:
	; zapamiętaj adres segmentu danych
	push	ds

	; ustaw semgent danych na koniec pamięci
	mov	ax,	0xFFFF
	mov	ds,	ax

	; zapisz wartość 0xFF pod adres fizyczny 0xFFFF0 + 0x0510 = 0x100500
	mov	byte [ds:0x0510],	0xFF

	; przywróć adres segmentu danych
	pop	ds

	; sprawdź czy wartość spod adresu fizycznego 0x0000:0x0500 jest równa z poprzednio zapisaną
	mov	al,	byte [ds:0x0500]
	cmp	byte [ds:0x0500],	0xFF
	jne	.end	; jeśli różne, linia a20 odblokowana

	; brama a20 zablokowana
	sti	; włącz flagę CF (CarryFlag)

	; powrót z procedury
	ret

.end:
	; wyłącz flagę CF (CarryFlag)
	clc

	; powrót z procedury
	ret

wait_for_keyboard_in:
	; pobierz status bufora klawiatury do al
	in	al,	0x64
	test	al,	2	; sprawdź czy drugi bit jest równy zero

	; jeśli nie, powtórz operacje
	jnz	wait_for_keyboard_in

	ret

wait_for_keyboard_out:
	; pobierz status bufora klawiatury do al
	in	al,	0x64
	test	al,	1	; sprawdź czy pierwszy bit jest równy zero

	; jeśli nie, powtórz operacje
	jz	wait_for_keyboard_out

	ret

memory_map:
	; zachowaj oryginalny rejestr
	push	di
	; zachowaj adres segmentu ekstra
	push	es

	; utwórz pod adresem 0x0000:0x0500, mapę pamięci z procedury 0xE820, przerwania 0x15
	xor	ax,	ax
	mov	es,	ax
	mov	di,	0x0500

	; przygotowanie rejestrów pod procedurę mapowania
	xor	ebx,	ebx	; wyczyść
	mov	edx,	0x534D4150	; tekst "SMAP", specjalna wartość wymagana przez procedurę

.loop:
	; procedura przerwania 0x15
	mov	eax,	0xE820
	mov	ecx,	24	; rozmiar rekordu opisującego daną przestrzeń pamięci
	mov	dword [es:di + 20],	0x0001	; wsparcie dla ACPI 3.0+
	int	0x15	; wykonaj

	; jeśli wystąpi błąd podczas mapowania pamięci, program rozruchowy kończy działanie!
	jnc	.continue

	; przywróc adres segmentu ekstra
	pop	es
	; przywróć oryginalny rejestr
	pop	di

	; brak możliwości utworzenia mapy pamięci, koniec
	mov	si,	text_no_a20
	call	print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$


.continue:
	; wszystko jest w porządku, więc przesuwamy wskaźnik na następne miejsce (rekord)
	add	di,	24

	; jeśli bx jest równe zero, procedura zakończyła mapować całą przestrzeń pamięci fizycznej
	cmp	bx,	0x0000
	jne	.loop	; kontynuuj

	; utwórz pusty rekord, określający koniec mapy pamięci
	xor	al,	al
	rep	stosb	; wykonaj

	; przywróc adres segmentu ekstra
	pop	es
	; przywróć oryginalny rejestr
	pop	di

	; powrót z procedury
	ret

load_kernel:
	; zachowaj oryginalne rejestry
	mov	bx,	dx

	; oblicz pozycję jądra systemu na nośniku (nr sektora)

	; wylicz rozmiar programu rozruchowego stage2
	mov	eax,	stage2
	sub	eax,	start
	shr	eax,	9	; /512

	; koryguj o rozmiar stage1
	inc	eax

	; zapisz informacje o początku kodu jądra systemu na nośniku
	mov	dword [packet + 0x08],	eax

	; oblicz rozmiar kodu jądra systemu do załadowania
	mov	eax,	kernel	; koniec kodu jądra systemu
	sub	eax,	stage2	; odejmij rozmiar programu rozruchowego stage2
	mov	ecx,	512 * 64	; przelicz na ilość paczek sektorów
	xor	edx,	edx	; wyczyść starszą część / resztę
	div	ecx	; wylicz

	; zachowaj resztę z dzielenia
	push	dx

	; sprawdź czy kod jądra zawiera fragmenty po 32 kiB do załadowania
	cmp	eax,	0x00000000
	je	modulo	; nie, załaduj pozostałą część kodu jądra do pamięci

	; ustaw licznik fragmentów
	mov	ecx,	eax

	; ustaw numer urządzenia
	mov	dx,	bx

.loop:
	; załaduj fragment kodu jądra systemu do pamięci
	call	read

	; przesuń offset o 0x8000 Bajtów do przodu
	cmp	word [packet + RECORD.offset],	0x8000
	jne	.offset

	mov	word [packet + RECORD.offset],	0x0000
	add	word [packet + RECORD.segment],	0x1000

	jmp	.segment

.offset:
	add	word [packet + RECORD.offset],	0x8000

.segment:
	add	word [packet + RECORD.lba],	0x40

	; kontynuuj z pozostałymi fragmentami
	loop	.loop

modulo:
	; przywróć resztę z dzielenia
	pop	ax

	; zamień na pozostałą ilość sektorów do załadowania
	shr	eax,	9

	; koryguj rozmiar o możliwą resztę z dzielenia
	inc	eax

	; zapisz informację do pakietu
	mov	word [packet + RECORD.count],	ax

	; ustaw numer urządzenia
	mov	dx,	bx

	; odczytaj pozostałe sektory kodu jądra
	call	read

	; powrót z procedury
	ret

read:
	; rozpoczynamy wczytanie programu rozruchowego do pamięci
	mov	ah,	0x42	; procedura - rozszerzony odczyt danych
	mov	si,	packet	; o rozmiarze i miejscu docelowym opisanym za pomocą pakietu danych
	int	0x13	; wykonaj funkcje - rozszerzony odczyt z nośnika

	; błąd podczas odczytywania danych z nośnika
	jc	.error

	; powrót z procedury
	ret

.error:
	; poinformuj o błędzie podczas ładowania pliku jądra do pamięci fizycznej
	mov	si,	text_read_fail
	call	print_16bit

	; przesuń kod błędu do AL
	movzx	eax,	ah
	; podstawa heksadecymalna
	mov	ecx,	0x10
	; wyświetl kod błędu
	call	print_number_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

print_16bit:
	; zachowaj oryginalne rejestry
	push	ax
	push	si

	; procedura - wyświetl znak w miejscu kursora, przesuń kursor w prawo
	mov	ah,	0x0E

.loop:
	; pobierz do AL wartość z adresu pod wskaźnikiem SI, zwiększ wskaźnik SI o 1
	lodsb

	; sprawdź czy koniec tekstu do wyświetlenia
	cmp	al,	0x00	; jeśli ZERO, zakończ
	je	.end

	; wyświetl znak na ekranie
	int	0x10

	; załaduj i wyświetl następny znak
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	si
	pop	ax

	; powrót z procedury
	ret

print_number_16bit:
	; zachowaj oryginalne rejestry
	push	ax
	push	cx
	push	dx
	push	sp
	push	bp

	; wyczść resztę/ starszą część
	xor	dx,	dx

	; zapamiętaj koniec bufora danych
	mov	bp,	sp

.calculate:
	; podziel dx:ax przez cx
	div	cx

	; odstaw resztę z dzielenia do bufora
	push	dx

	; wyczść resztę/ starszą część
	xor	dx,	dx

	; sprawdź czy zostało jeszcze coś do przeliczenia
	cmp	ax,	0x0000
	jne	.calculate	; jeśli tak, powtórz operacje

.print:
	; pobierz z bufora najstarszą cyfre
	pop	ax

	; procedura - wyświetl znak w miejscu kursora, przesuń kursor w prawo
	mov	ah,	0x0E

	; sprawdź czy znak spoza cyfr
	cmp	al,	0x0A
	jb	.digit

	; zamień cyfre na kod ASCII (A..F)
	add	al,	0x3A

	; kontynuuj
	jmp	.continue

.digit:
	; zamień cyfre na kod ASCII (0..9)
	add	al,	0x30	

.continue:
	; wyświetl cyfre na ekranie
	int	0x10

	; sprawdź czy zostało coś jeszcze w buforze
	cmp	bp,	sp
	jne	.print	; jeśli tak, kontynuuj

	; przywróć oryginalne rejestry
	pop	bp
	pop	sp
	pop	dx
	pop	cx
	pop	ax

	; powrót z procedury
	ret



packet:
	db	0x10	; rozmiar pakietu (16 bajtów)
	db	0x00	; zarezerwowane/zawsze zero
	dw	0x0040	; ilość sektorów do odczytania (32 KiB)
	; gdzie zapisać odczytane dane
	dw	0x0000	; przesunięcie
	dw	0x1000	; segment
	; pierwszy bezwzględny (LBA, liczony od zera) numer sektora do odczytu
	dq	0x0000000000000001	; drugi sektor, w pierwszym jest MBR

; umieść tablicę GDT w pełnym adresie
align	0x08

gdt_specification_32bit:
	; deskryptor zerowy
	dw	0x0000	; Limit 15:0
	dw	0x0000	; Baza 15:0
	db	0x00	; Baza 23:16
	db	00000000b	; P, DPL (2 bity), S, Type (4 bity)
	db	00000000b	; G, D/B, Zarezerwowane, AVL, Limit 19:16
	db	0x00	; Baza 31:24

	; deskryptor kodu
	dw	0xffff	; Limit 0:15
	dw	0x0000	; Baza	0:15
	db	0x00	; Baza 23:16
	db	10011000b	; P, DPL (2 bity), 1, 1, C, R, A
	db	11001111b	; G, D/B, Zarezerwowane, AVL, Limit 19:16
	db	0x00	; Baza 31:24

	; deskryptor danych
	dw	0xffff	; Limit 0:15
	dw	0x0000	; Baza	0:15
	db	0x00	; Baza 23:16
	db	10010010b	; P, DPL (2 bity), 1, 0, E, W, A
	db	11001111b	; G, D/B, Zarezerwowane, AVL, Limit 19:16
	db	0x00	; Baza 31:24
gdt_specification_32bit_end:

gdt_structure_32bit:
	dw	gdt_specification_32bit_end - gdt_specification_32bit - 1	; rozmiar
	dd	gdt_specification_32bit	; adres

; rozpocznij kod 32 Bitowy od pełnego adresu
align	0x08

; 32 Bitowy kod programu =======================================================
[BITS 32]

protected_mode:
	; ustaw deskryptory danych, ekstra i stosu
	mov	ax,	0x0010

	; podstawowe segmenty
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	; ustaw wskaźnik szczytu stosu na adres przed załadowanym jądrem systemu
	mov	esp,	0x00010000	; wystarczająca ilość miejsca dla programu rozruchowego

	; skopiuj kod jądra systemu operacyjnego w prawidłowe miejsce
	mov	esi,	0x00010000
	mov	edi,	0x00100000
	; oblicz rozmiar kodu jądra systemu
	mov	ecx,	kernel	; koniec
	sub	ecx,	stage2	; koniec kodu programu rozruchowego
	rep	movsb	; kopiuj

	; WYBIERZ TRYB PROCESORA NA PODSTAWIE NAGŁÓWKA ZAŁADOWANEGO JĄDRA SYSTEMU
	cmp	byte [0x00100000],	0x20	; 32
	ja	.no	; kod jądra systemu nie jest 32 Bitowy, przejdź do trybu dalekiego (64 Bitowego)

	; wyczyść zbędne rejestry
	xor	eax,	eax
	xor	ebx,	ebx
	xor	ecx,	ecx
	xor	edx,	edx
	xor	edi,	edi

	; sprawdź czy włączono tryb graficzny
	cmp	word [supervga_mode + 0x12],	0x0000	; rozdzielczość X
	je	.text_mode

	; poinformuj jądro systemu o pozycji tablicy informacyjnej trybu graficznego
	mov	ebx,	supervga_mode

.text_mode:
	; zwróć informacje gdzie znajduje się mapa pamięci
	mov	esi,	0x00000500

	; skocz do kodu jądra systemu operacyjnego
	jmp	long 0x08:0x00100001

.no:
	; utwórz podstawowe stronicowanie dla trybu 64 Bitowego

	; wyczyść przestrzeń pod stronicowanie
	mov	edi,	0x00010000	; adres tablic stronicowania (PML4, PML3, PML2)
	xor	eax,	eax	; wyczyść
	mov	ecx,	0x1000 * 6 / 4	; cała 32 bitowa fizyczna przestrzeń (4 GiB)
	rep	stosd	; wykonaj

	; pml4[ 0 ]
	mov	edi,	0x10000
	mov	eax,	0x11000 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml4[ 0 ]
	xor	eax,	eax	; starsza część adresu pml3
	stosd	; zapisz do pml4[ 0 ]

	; pml3[ 0 ]
	mov	edi,	0x11000
	mov	eax,	0x12000 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 0 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 0 ]

	; pml3[ 1 ]
	mov	eax,	0x13000 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 1 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 1 ]

	; pml3[ 2 ]
	mov	eax,	0x14000 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 2 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 2 ]

	; pml3[ 3 ]
	mov	eax,	0x15000 + 0x03	; bbity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 3 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 3 ]

	; pml2[ x ]
	mov	edi,	0x12000	; pml2[ 0 ]
	mov	eax,	0x00000000 + 0x83	; pierwsze 2 MiB pamięci fizycznej + bity "2 MiB", Administrator, Zapis, Aktywna
	mov	ecx,	512 * 4	; ilość wpisów: 512 * 2 MiB => 1 GiB * 4 = 4 GiB

.loop:
	; zapisz do pml2[ x ]
	stosd

	; zapamiętaj adres aktualnej strony
	push	eax

	; starsza część adresu strony
	xor	eax,	eax
	stosd	; zapisz do pml2[ x ]

	; przywróć adres aktualnej strony
	pop	eax

	; następna strona
	add	eax,	0x00200000
	; kontynuuj
	loop	.loop

	; załaduj globalną tablicę deskryptorów
	lgdt	[gdt_structure_64bit]

	; włącz PGE, PAE i PSE w CR4
	mov	eax,	cr4
	or	eax,	0x0000000B0		; PGE (bit 7), PAE (bit 5) i PSE (bit 4)
	mov	cr4,	eax

	; załaduj do CR3 adres PML4
	mov	eax,	0x00010000
	mov	cr3,	eax

	; włącz w rjestrze EFER MSR tryb długi oraz SYSCALL/SYSRET
	mov	ecx,	0xC0000080	; numer EFER MSR
	rdmsr	; odczytaj
	or	eax,	00000000000000000000000100000001b	; ustawiamy bit 7 (LME) i bit 0
	wrmsr	; zapisz

	; włącz stronicowanie i zarazem tryb kompatybilności (64 bit)
	mov	eax,	cr0
	or	eax,	0x80000000	; włącz 31 bit (PG)
	mov	cr0,	eax

	; skocz do 64 bitowego kodu
	jmp	0x0008:long_mode

; rozpocznik tablicę od pełnego adresu
align	0x08

gdt_specification_64bit:
	; deskryptor zerowy
	dw	0x0000	; Limit 15:0
	dw	0x0000	; Baza 15:0
	db	0x00	; Baza 23:16
	db	00000000b	; P, DPL (2 bity), 1, 1, C, R, A
	db	00000000b	; G, D, L, AVL, Limit 19:16
	db	0x00	; Baza 31:24

	; deskryptor kodu
	dw	0x0000	; ignorowany
	dw	0x0000	; ignorowany
	db	0x00	; ignorowany
	db	10011000b	; P, DPL (2 bity), 1, 1, C, ignorowany, ignorowany
	db	00100000b	; ignorowany, D, L, ignorowany, ignorowany 19:16
	db	0x00	; ignorowany

	; deskryptor danych
	dw	0x0000	; ignorowany
	dw	0x0000	; ignorowany
	db	0x00	; ignorowany
	db	10010010b	; P, ignorowany (2 bity), 1, ignorowany, ignorowany, ignorowany/bochs wymaga!!!, ignorowany
	db	00100000b	; ignorowany, D, L, ignorowany, ignorowany 19:16
	db	0x00	; ignorowany
gdt_specification_64bit_end:

gdt_structure_64bit:
	dw	gdt_specification_64bit_end - gdt_specification_64bit - 1	; rozmiar
	dd	gdt_specification_64bit	; adres

; rozpocznij kod 64 Bitowy od pełnego adresu
align 0x08

; 64 Bitowy kod programu =======================================================
[BITS 64]

long_mode:
	; wyczyść zbędne informacje
	xor	rax,	rax
	xor	rbx,	rbx
	xor	rcx,	rcx
	xor	rdx,	rdx
	xor	rdi,	rdi

	; sprawdź czy włączono tryb graficzny
	cmp	word [supervga_mode + 0x12],	0x0000	; rozdzielczość X
	je	.text_mode

	; poinformuj jądro systemu o pozycji tablicy informacyjnej trybu graficznego
	mov	ebx,	supervga_mode

.text_mode:
	; zwróć informacje gdzie znajduje się mapa pamięci
	mov	rsi,	0x00000500

	; skocz do kodu jądra systemu operacyjnego
	jmp	0x0000000000100001

text_cpu		db	'64 Bit CPU available.', 0x0D, 0x0A, 0x00
text_no_cpu		db	'No 64 Bit instructions available with this CPU!', 0x0D, 0x0A, 0x00
text_a20		db	'Gate A20 unlocked.', 0x0D, 0x0A, 0x00
text_no_a20		db	'Unable to open gate A20!', 0x0D, 0x0A, 0x00
text_memory		db	'Memory map prepared.', 0x0D, 0x0A, 0x00
text_no_memory		db	'An error occurred while performing memory map!', 0x0D, 0x0A, 0x00
text_kernel		db	'Kernel system loaded.', 0x0D, 0x0A, 0x00
text_kernel_oversized	db	'Kenrel file oversized!', 0x0D, 0x0A, 0x00
text_read_fail		db	'Read error, code 0x',	0x00

align	0x08

; tablica informacyjna o dostępnych trybach graficznych
supervga_info	times	256	db	0x00
; tablica informacyjna o wybranym trybie graficznym
supervga_mode	times	256	db	0x00

; wyrównaj pozycje kodu jądra systemu do pełnego sektora
align	0x0200

; początek kodu jądra
stage2:

incbin	'kernel.bin'

; koniec kodu jądra
kernel:
