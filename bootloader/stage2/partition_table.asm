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

; 16 Bitowy kod programu
[BITS 16]

; === TABLICA PARTYCJI =========================================================
disk_identificator		db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; 10 Bajtów, wartość niewymagana

; pp0 - partycja podstawowa nr ZERO
pp0_boot			db	0x80	; partycja jest aktywna (znacznik przesiadującego tu systemu)
pp0_chs_start			db	0x00, 0x00, 0x00	; zbędne
pp0_type			db	0x3a	; typ partycji (numer niewykorzystany, zarezerwowałem :)
pp0_chs_end			db	0x00, 0x00, 0x00	; zbędne
pp0_lba				dd	2048	; bezwzględny numer sektora poczatku partycji (partycja zaczyna się od drugiego MiB)
pp0_size			dd	2048	; rozmiar partycji w sektorach (1 MiB)

; brak informacji o pozostałych partycjach

; === KONIEC TABLICY PARTYCJI ==================================================
