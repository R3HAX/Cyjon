; Superblock [SB]
dq	0x100
dq	0x1000
dq	0x80

times 0x1000 - ( $ - $$ )	db	0x00

; Binary Block Map [BBM]
dq	0x003fffffffffffff
dq	0xffffffffffffffff
dq	0xffffffffffffffff
dq	0xffffffffffffffff

times 0x2000 - ( $ - $$ )	db	0x00

; Knots Table [KT]
dw	0x4000	; directory
dq	0x0000000000000001	; rozmiar w blokach
dq	0x000000000000000A	; numer pierwszego bloku danych pliku

times 512 * 2048 - ( $ - $$ )	db	0x00
