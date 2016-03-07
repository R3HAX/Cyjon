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

VARIABLE_FILESYSTEM_NTFS_SIGNATURE	equ	"NTFS"
VARIABLE_FILESYSTEM_NTFS_SECTOR_SIZE	equ	512	; wartość domyślna

struc	NTFS_BOOTSECTOR_SPECIFICATION
	.jump			resb	3
	.signature		resb	8
	.bytes_per_sector	resb	2
	.sectors_per_cluster	resb	1
	.ignore0		resb	26
	.total_sectors		resb	8
	.mft			resb	8
	.mftmirr		resb	8
endstruc


variable_filesystem_ntfs_partition_position	dq	VARIABLE_EMPTY
variable_filesystem_ntfs_sectors_per_cluster	dq	VARIABLE_EMPTY
variable_filesystem_ntfs_bytes_per_sector	dq	VARIABLE_EMPTY
variable_filesystem_ntfs_mft			dq	VARIABLE_EMPTY

align	0x0100

filesystem_ntfs_initialization:
	; przygotuj miejsce na superblock
	call	cyjon_page_allocate

	; zapamiętaj adres LBA partycji
	mov	qword [variable_filesystem_ext_partition_position],	rax

	; przesuń sektor LBA na pozycje 
	mov	rcx,	1
	call	cyjon_disk_io

	; sprawdź sygnature systemu plików
	cmp	dword [rdi + NTFS_BOOTSECTOR_SPECIFICATION.signature],	VARIABLE_FILESYSTEM_NTFS_SIGNATURE
	jne	.not_ntfs

	; sprawdź rozmiar sektora
	cmp	byte [rdi + NTFS_BOOTSECTOR_SPECIFICATION.bytes_per_sector],	VARIABLE_FILESYSTEM_NTFS_SECTOR_SIZE
	jne	.big_sector

	; pobierz rozmiar klastra w sektorach
	movzx	rax,	byte [rdi + NTFS_BOOTSECTOR_SPECIFICATION.sectors_per_cluster]
	mov	qword [variable_filesystem_ntfs_sectors_per_cluster],	rax

	jmp	$

.not_ntfs:
	; nie rozpoznano
	stc

	; powrót z procedury
	ret

.big_sector:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rsi

	; wyświetl informacje o zasobach pamięci RAM
	mov	rbx,	VARIABLE_COLOR_RED
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_filesystem_ntfs_big_sector
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rbx

	; brak obsługi
	jmp	.not_ntfs

text_filesystem_ntfs_big_sector	db	" NTFS driver: sector size not supported.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
