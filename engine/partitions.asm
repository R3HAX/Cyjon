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

struc	PARTITION_TABLE_STRUCTURE
	.boot		resb	1
	.chs_start	resb	3
	.type		resb	1
	.chs_stop	resb	3
	.lba		resd	1
	.count		resd	1
	.record_size	resb	1
endstruc

text_partitions_not_recognized	db	" Not recognized any of available partitions.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

; 64 Bitowy kod programu
[BITS 64]

check_partitions:
	; sprawdź dostępność dysku
	cmp	byte [variable_disk_io_ready],	VARIABLE_FALSE
	je	.end

	; przygotuj miejsce na bootsector
	call	cyjon_page_allocate

	; zapamiętaj, by zwolnić później
	push	rdi

	; pobierz bootsector 
	xor	rax,	rax	; sektor 0 (lba)
	mov	bl,	STATIC_DISK_IO_RECORD_IO_READ
	mov	rcx,	1	; ilość
	call	cyjon_disk_io

	; sprawdź 4 partycje podstawowe
	mov	rcx,	4

	; przesuń wskaźnik na początek tablicy partycji
	add	rdi,	436 + 10	; +10 pomiń identyfikator nośnika

.next_partition:
	mov	eax,	dword [rdi + PARTITION_TABLE_STRUCTURE.lba]
	cmp	eax,	VARIABLE_EMPTY
	je	.no_partition

	align	0x0100

	; sprawdź system plików ext
	call	filesystem_ext_initialization
	jnc	.finish

	; sprawdź system plików ntfs
	call	filesystem_ntfs_initialization
	jnc	.finish

.no_partition:
	; przesun wskaźnik na następny rekord
	add	rdi,	PARTITION_TABLE_STRUCTURE.record_size

	; pozostały partycje do sprawdzenia
	dec	rcx
	jnz	.next_partition

	; wyświetl informacje o zasobach pamięci RAM
	mov	rbx,	VARIABLE_COLOR_YELLOW
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_partitions_not_recognized
	call	cyjon_screen_print_string

.finish:
	; przywróć adres przestrzeni tymczasowej
	pop	rdi

	; zwolnij przestrzeń
	call	cyjon_page_release

.end:
	; powrót z procedury
	ret
