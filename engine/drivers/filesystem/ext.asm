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

struc	EXT_SUPERBLOCK
	.ignore0					resb	24
	.s_log_block_size				resb	4
	.ignore1					resb	28
	.s_magic					resb	4
	.ignore2					resb	28
	.s_inode_size					resb	2
endstruc

struc	EXT_BLOCK_GROUP_DESCRIPTOR
	.ignore0					resb	8
	.bd_inode_table_lo				resd	1
endstruc

struc	EXT_INODE_STRUCTURE
	.i_mode		resw	1
	.i_uid		resw	1
	.i_size_lo	resd	1
	.i_atime	resd	1
	.i_ctime	resd	1
	.i_mtime	resd	1
	.i_dtime	resd	1
	.i_gid		resw	1
	.i_links_count	resw	1
	.i_blocks_lo	resd	1
	.i_flags	resd	1
	.i_osd1		resd	1
	.i_block	resb	60
	.i_generation	resd	1
	.i_file_acl_lo	resd	1
	.i_size_high	resd	1
	.i_obso_faddr	resd	1
	.i_osd2		resb	12
	.i_extra_isize	resw	1
	.i_checksum_hi	resw	1
	.i_ctime_extra	resd	1
	.i_mtime_extra	resd	1
	.i_atime_extra	resd	1
	.i_crtime	resd	1
	.i_crtime_extra	resd	1
	.i_version_hi	resd	1
	.i_projid	resd	1
endstruc

struc	EXT_INODE_FLAGS
	.ignore0	resb	19
	.extents	resb	1
endstruc

VARIABLE_EXT_SUPERBLOCK_OFFSET				equ	2	; 1 KiB (2 sektory)
VARIABLE_EXT_SUPERBLOCK_MAGIC				equ	0xEF53
VARIABLE_EXT_SUPERBLOCK_DEFAULT_BLOCK_SIZE		equ	0x0400	; 1 KiB
VARIABLE_EXT_SUPERBLOCK_DEFAULT_BLOCK_SIZE_IN_SECTORS	equ	2

variable_filesystem_ext_partition_position		dq	VARIABLE_EMPTY
variable_filesystem_ext_s_log_block_size		dq	VARIABLE_EMPTY
variable_filesystem_ext_s_log_block_size_in_bytes	dq	VARIABLE_EMPTY
variable_filesystem_ext_s_inode_size			dq	VARIABLE_EMPTY
variable_filesystem_ext_bd_inode_table_lo		dq	VARIABLE_EMPTY

text_filesystem_ext_found				db	" Ext filesystem found.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

align	0x0100

filesystem_ext_initialization:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; przygotuj miejsce na superblock
	call	cyjon_page_allocate

	; zapamiętaj adres LBA partycji
	mov	qword [variable_filesystem_ext_partition_position],	rax

	; przesuń sektor LBA na pozycje 
	add	rax,	VARIABLE_EXT_SUPERBLOCK_OFFSET
	mov	rcx,	2	; załaduj 2 sektory (1 KiB)
	call	cyjon_disk_io

	; sprawdź sygnature systemu plików
	cmp	word [rdi + EXT_SUPERBLOCK.s_magic],	VARIABLE_EXT_SUPERBLOCK_MAGIC
	jne	.not_ext

	xor	rax,	rax

	; pobierz rozmiar i-węzła
	mov	ax,	word [rdi + EXT_SUPERBLOCK.s_inode_size]
	mov	qword [variable_filesystem_ext_s_inode_size],	rax	; zapisz

	; pobierz rozmiar bloku
	mov	rax,	VARIABLE_EXT_SUPERBLOCK_DEFAULT_BLOCK_SIZE
	mov	ecx,	dword [rdi + EXT_SUPERBLOCK.s_log_block_size]
	; przelicz na Bajty
	shl	rax,	cl
	; zapamiętaj rozmiar w Bajtach
	mov	qword [variable_filesystem_ext_s_log_block_size_in_bytes],	rax
	; przelicz na sektory
	shr	rax,	9	; /512
	mov	qword [variable_filesystem_ext_s_log_block_size],	rax	; zapisz

	; przesuń sektor LBA na pozycje Block Group Descriptor
	mov	rax,	qword [variable_filesystem_ext_partition_position]
	mov	rcx,	qword [variable_filesystem_ext_s_log_block_size]	; rozmiar Superbloku
	add	rax,	rcx

	; jeśli rozmiar bloku jest równy lub mniejszy od superbloku
	cmp	qword [variable_filesystem_ext_s_log_block_size],	VARIABLE_EXT_SUPERBLOCK_DEFAULT_BLOCK_SIZE_IN_SECTORS
	ja	.greater

	add	rax,	VARIABLE_EXT_SUPERBLOCK_OFFSET

.greater:
	; odczytaj Block Group Descriptor
	call	cyjon_disk_io

	; pobierz numer pierwszego bloku tablicy i-węzłów
	mov	eax,	dword [rdi + EXT_BLOCK_GROUP_DESCRIPTOR.bd_inode_table_lo]
	mov	qword [variable_filesystem_ext_bd_inode_table_lo],	rax

	; poinformuj jądro systemu o zainicjalizowanym domyślnym sterowniku systemu plików
	mov	byte [variable_filesystem_io_ready],	VARIABLE_TRUE

	; udostępnij interfejs
	mov	rax,	filesystem_ext_file_read
	mov	qword [variable_partition_interface_file_read],	rax

	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rsi

	; wyświetl informacje o zasobach pamięci RAM
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_filesystem_ext_found
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rbx

	; rozpoznano system plików
	clc

	; koniec inicjalizacji
	jmp	.end

.not_ext:
	; nie rozpoznano systemu plików
	stc

.end:
	; zwolnij pamięć tymczasową
	call	cyjon_page_release

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

align 0x0100

filesystem_ext_file_read:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; przygotuj miejsce na przetwarzanie danych
	call	cyjon_page_allocate
	; zapamiętaj, by zwolnij na koniec
	push	rdi

	; oblicz numer sektora w tablicy i-węzłów przechowującego numer i-węzła
	dec	rax	; numery i-węzłów liczone są od 1
	xor	rdx,	rdx	; wyczyść starszą część
	mul	qword [variable_filesystem_ext_s_inode_size]
	; zamień na numer sektora
	div	qword [variable_disk_sector_size_in_bytes]
	; zapamiętaj przesunięcie i-węzła wew. sektora
	push	rdx
	; zapamiętaj numer sektora w tablicy i-węzłów
	push	rax

	; oblicz numer sektora rozpoczynającego tablicę i-węzłów
	mov	rax,	qword [variable_filesystem_ext_bd_inode_table_lo]
	xor	rdx,	rdx	; wyczyść starszą część
	mul	qword [variable_filesystem_ext_s_log_block_size]
	; skoryguj numer sektora o adres LBA początku partycji
	add	rax,	qword [variable_filesystem_ext_partition_position]
	; dodaj numer sektora wew. tablicy i-węzłów
	add	rax,	qword [rsp]
	add	rsp,	VARIABLE_QWORD_SIZE	; zwolnij zmienną lokalną

	; odczytaj sektor zawierający i-węzeł
	mov	rcx,	1
	call	cyjon_disk_io

	; przywróć przesunięcie wew. sektora
	pop	rax

	; sprawdź czy system plików ma wyłączoną flagę Extent
	bt	dword [rdi + rax + EXT_INODE_STRUCTURE.i_flags],	EXT_INODE_FLAGS.extents
	jc	.flag_extent	; nie, brak wsparcia

	; przesuń przesunięcie na pierwszy blok danych
	add	rax,	EXT_INODE_STRUCTURE.i_block
	; odczytaj maksymalnie 12 bloków (brak wsparcia dla większej ilości)
	mov	rcx,	12
	; przywróć adres docelowy
	mov	rbx,	qword [rsp + VARIABLE_QWORD_SIZE]

.loop:
	; zachowaj przesunięcie wskaźnika
	push	rax

	; pobierz numer bloku do odczytania
	mov	eax,	dword [rdi + rax]

	; sprawdź czy odczytać następny blok danych
	cmp	rax,	VARIABLE_EMPTY
	je	.no_more_blocks

	; zachowaj licznik
	push	rcx
	
	; odczytaj
	mov	rcx,	1
	mov	rdi,	rbx
	call	filesystem_ext_block_read

	; przywróć licznik
	pop	rcx

	; przywróć przesunięcie wskaźnika
	pop	rax

	; przesuń na następny rekord i adres
	add	rax,	VARIABLE_DWORD_SIZE
	add	rbx,	qword [variable_filesystem_ext_s_log_block_size_in_bytes]

	; zmniejsz ilość 
	dec	rcx
	jnz	.loop

	; koniec
	jmp	.end

.no_more_blocks:
	pop	rax

.end:
	; przywróć adres przestrzeni
	pop	rdi
	; zwolnij przestrzeń
	call	cyjon_page_release

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

.flag_extent:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rsi

	; wyświetl informacje o zasobach pamięci RAM
	mov	rbx,	VARIABLE_COLOR_LIGHT_RED
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_filesystem_ext_flag_extent
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rbx

	; zwróć kod błędu
	mov	qword [rsp + 0x20],	0x01

	; koniec
	jmp	.end

text_filesystem_ext_flag_extent	db	" Ext driver: no support for Extent flag.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

filesystem_ext_block_read:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rax

	; zamień ilość bloków do odczytania na sektory
	mov	rax,	qword [variable_filesystem_ext_s_log_block_size]
	xor	rdx,	rdx
	mul	rcx
	; koryguj ilość
	mov	rcx,	rax

	; oblicz numer sektora bloku
	mov	rax,	qword [rsp]
	xor	rdx,	rdx	; wyczyść starszą część
	mul	qword [variable_filesystem_ext_s_log_block_size]
	; skoryguj numer sektora o adres LBA początku partycji
	add	rax,	qword [variable_filesystem_ext_partition_position]

	; odczytaj
	call	cyjon_disk_io

	; przywróć oryginalne rejestry
	pop	rax
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret
