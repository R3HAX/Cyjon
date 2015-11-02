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

; 16 bitowy kod programu
[BITS 16]

; położenie kodu programu w pamięci fizycznej 0x0000:0x7C00
[ORG 0x7C00]

start:
	; wyłącz przerwania
	cli

	; niektóre BIOSy mogą ustawiać niepoprawny segment kodu tj. 0x07C0:0x0000
	; wykonaj daleki skok, by naprawić tą przypadłość
	jmp	0x0000:repair_cs

repair_cs:
	; wyczyść AX
	xor	ax,	ax
	; ustaw segmenty danych, ekstra i stosu na pierwsze 64 KiB pamięci fizycznej
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	; ustaw wskaźnik stosu na "koniec" segmentu danych/stosu
	xor	sp,	sp

	; włącz przerwania
	sti

	; wyświetl informację o przystąpieniu do pracy
	mov	si,	text_ready
	call	print_16bit

	; skorzystamy z przerwania 0x13, procedury 0x42
	; istnieją jednostki lub inne złomy, których BIOS nie udostępnia danej procedury, gdy o nią wpierw nie zapytamy
	mov	ah,	0x41	; procedura - sprawdź dostępne rozszerzenia
	mov	bx,	0x55AA	; wartość wymagana przez procedurę
	int	0x13	; wykonaj

	; jeśli flaga CF została ustawiona to pewnym jest, że procedura 0x42 nie jest dostępna w danym BIOSie
	jc	bios_not_supported

	; sprawdź czy BH i BL zostało zamienione miejscami
	; jeśli nie, brak dostępnej procedury
	cmp	bx,	0x55AA
	je	bios_not_supported

	; ostatnie co potrzebujemy sprawdzić to bit 0 w rejestrze CL
	bt	cx,	0	; skopiuj bit 0 do flagi CF
	jnc	bios_not_supported	; jeśli flaga nie jest ustawiona, brak procedury

	; wszystko przebiegło pomyślnie, procedura dostępna w tej wersji BIOSu
	mov	si,	text_bios
	call	print_16bit

	; obliczamy rozmiar programu rozruchowego do załadowania
	mov	eax,	end	; od adresu końca programu rozruchowego
	sub	eax,	stage2	; odejmij rozmiar MBR
	shr	eax,	9	; eax / 512 - zamień na ilość sektorów

	; zwiększ rozmiar programu rozruchowego o jeden sektor
	inc	eax	; gdyby z dzielenia pozostała reszta

	; sprawdź czy rozmiar jest dopuszczalny dla przerwania 0x13
	cmp	eax,	0x0000007F	; 0x7F(max) * 512 = 63,5 KiB
	ja	stage2_size_fail

	; zaaktualizuj pakiet danych o rozmiar programu rozruchowego w sektorach
	mov	word [packet + 0x02],	ax

	; wyświetl informację o prawidłowym rozmiarze
	mov	ax,	0x072E	; jasnoszara kropka
	stosw	; zapisz do pamięci ekranu

	; rozpoczynamy wczytanie programu rozruchowego do pamięci
	mov	ah,	0x42	; procedura - rozszerzony odczyt danych
	mov	si,	packet	; o rozmiarze i miejscu docelowym opisanym za pomocą pakietu danych
	int	0x13	; wykonaj funkcje - rozszerzony odczyt z nośnika

	; sprawdź czy operacja wczytania danych przebiegła pomyślnie
	jc	read_error	; jeśli nie, wyświetl stosowną informację

	; wyświetl informację o załadowaniu oprogramowania
	mov	si,	text_stage2
	call	print_16bit

	; posprzątaj po sobie
	xor	eax,	eax
	xor	ebx,	ebx
	xor	ecx,	ecx
	; zachowaj numer urządzenia z którego nastapił odczyt
	; xor	edx,	edx
	xor	ebp,	ebp
	xor	esi,	esi
	xor	edi,	edi

	; skocz do załadowanego programu rozruchowego
	jmp	0x0000:0x1000

bios_not_supported:
	; wyświetl informacje o braku możliwości załadowania drugiej części programu rozruchowego
	mov	si,	text_bios_unsupported
	call	print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

stage2_size_fail:
	; wyświetl informacje o nieprawidłowej wielkości programu Stage2
	mov	si,	text_stage2_oversized
	call	print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

read_error:
	; wystąpił błąd podczas wczytywania pliku Stage2
	mov	si,	text_read_fail
	call	print_16bit

	; przesuń kod błędu do AL
	movzx	eax,	ah
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

	; system heksadecymalny
	mov	cx,	16

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
	dw	0x001B	; ilość sektorów do odczytania (27 KiB)
	; gdzie zapisać odczytane dane
	dw	0x1000	; przesunięcie
	dw	0x0000	; segment
	; pierwszy bezwzględny (LBA, liczony od zera) numer sektora do odczytu
	dq	0x0000000000000001	; drugi sektor, w pierwszym jest MBR

text_ready			db	'Bootloader ready.', 0x0A, 0x0D, 0x00
text_stage2			db	'Stage2, prepared.', 0x0A, 0x0D, 0x00
text_stage2_oversized		db	'Oversized Stage2 file!', 0x0A, 0x0D, 0x00
text_bios			db	'BIOS version supported.', 0x0A, 0x0D, 0x00
text_bios_unsupported		db	'Unsupported BIOS version!', 0x0A, 0x0D, 0x00
text_read_fail			db	'Read error, code 0x',	0x00

; uzupełniamy niewykorzystaną przestrzeń po samą tablicę partycji
times	436 - ( $ - $$ )	db	0x00

; === TABLICA PARTYCJI =========================================================
disk_identificator		db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 10 Bajtów, wartość niewymagana

; pp0 - partycja podstawowa nr ZERO
pp0_boot			db	0x00	; partycja nie jest aktywna
pp0_chs_start			db	0x00, 0x00, 0x00	; zbędne
pp0_type			db	0x3a	; typ partycji
pp0_chs_end			db	0x00, 0x00, 0x00	; zbędne
pp0_lba				dd	2048	; bezwzględny numer sektora poczatku partycji
pp0_size			dd	2048	; rozmiar partycji w sektorach

; brak informacji o pozostałych partycjach

; === KONIEC TABLICY PARTYCJI ==================================================

; uzupełniamy niewykorzystaną przestrzeń
times	510 - ( $ - $$ )	db	0x00

; znacznik sektora rozruchowego	
dw	0xAA55	; czysta magija

; początek programu stage2
stage2:

incbin	'stage2.bin'

; koniec programu stage2
end:

; na systemach z rodziny MS/Windows, oprogramowanie Bochs wymaga obrazu dysku o rozmiarze > 1MiB i wyrównanego do pełnego sektora (512 Bajtów)
times	512 * 2048 - ( $ - $$ )	db	0x00

incbin	'build/kfs.raw'
