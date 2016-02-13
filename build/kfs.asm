; Copyright (C) 2013-2016 Wataha.net
; All Rights Reserved
;
; LICENSE Creative Commons BY-NC-ND 4.0
; See LICENSE.TXT
;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; [0x00] Superblock [SB]
dq	0x0000000000000100	; rozmiar partycji w blokach
dq	0x0000000000001000	; rozmiar bloku w Bajtach
dq	0x0000000000000080	; rozmiar supła
dq	0x0000000000000001	; rozmiar binarnej mapy bloków
dq	0x0000000000000008	; rozmiar tablicy supłów
dq	' Wataha '			; sygnatura systemu plików KFS

times 0x1000 - ( $ - $$ )	db	0x00

; [0x01] Binary Block Map [BBM]
dq	0x0003ffffffffffff
dq	0xffffffffffffffff
dq	0xffffffffffffffff
dq	0xffffffffffffffff

times 0x2000 - ( $ - $$ )	db	0x00

; [0x02] Knots Table [KT]

; rekord 0 - root directory
dw	0x4000	; directory
dq	0x0000000000000001	; rozmiar w blokach
dq	0x0000000000000014	; rozmiar w Bajtach
dq	0x000000000000000A	; blok indirect
dq	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
dw	0x00, 0x00, 0x00

; rekord 1 - .system
dw	0x4000 ; directory
dq	0x0000000000000001	; rozmiar w blokach
dq	0x000000000000000F	; rozmiar w Bajtach
dq	0x000000000000000C	; blok indirect
dq	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
dw	0x00, 0x00, 0x00

times 0xA000 - ( $ - $$ )	db	0x00

; [0x0A] pierwszy blok indirect rekordu 0

dq	0x000000000000000B

times 0xB000 - ( $ - $$ )	db	0x00

; [0x0B] plik Root Directory

; rekord 0
dq	0x0000000000000001	; identyfikator supła
dw	0x0014	; rozmiar rekordu
db	0x07	; ilość znaków w nazwie pliku
dw	0x4000	; typ pliku "katalog"
db	'.system'

times 0xC000 - ( $ - $$ )	db	0x00

; [0x0C] plik Root Directory

dq	0x000000000000000D

times 0xD000 - ( $ - $$ )	db	0x00

; [0x0D] katalog .system

; rekord 0
dq	0x0000000000000000	; identyfikator supła (powrót do katalogu /)
dw	0x000F	; rozmiar rekordu
db	0x02	; ilość znaków w nazwie pliku
dw	0x4000	; typ pliku "katalog"
db	'..'

times 0xE000 - ( $ - $$ )	db	0x00
