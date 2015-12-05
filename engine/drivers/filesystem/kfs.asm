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

struc	SUPERBLOCK
	.s_block_count			resq	1
	.s_block_size			resq	1
	.s_knot_size			resq	1
	.s_bit_block_map_size		resq	1
	.s_knots_table_size		resq	1
endstruc

struc	KFS
	.partition_position		resq	1
	.block_size			resq	1
	.block_size_in_sectors		resq	1
	.knot_size			resq	1
	.bit_block_map_address		resq	1
	.bit_block_map_size		resq	1
	.knots_table_address		resq	1
	.knots_table_size		resq	1
endstruc

struc	KNOT
	.type				resw	1
	.size				resq	1
	.size_in_bytes			resq	1
	.first_block			resq	1
endstruc

struc	ENTRY
	.knot_id			resq	1
	.record_size			resw	1
	.chars				resb	1
	.type				resb	1
	.name				resb	1
endstruc

variable_semaphore_lock_knot_find_free			db	VARIABLE_EMPTY

variable_partition_specification_home	times	8	dq	VARIABLE_EMPTY

cyjon_filesystem_kfs_initialization:
	push	rax
	push	rcx
	push	rdi
	push	r8

	call	cyjon_page_allocate
	call	cyjon_page_clear
	call	cyjon_ide_sector_read

	mov	qword [r8 + KFS.partition_position],	rax

	mov	rcx,	qword [rdi + SUPERBLOCK.s_block_size]
	mov	qword [r8 + KFS.block_size],	rcx
	shr	rcx,	VARIABLE_DISK_SECTOR_SIZE
	mov	qword [r8 + KFS.block_size_in_sectors],	rcx

	mov	rcx,	qword [rdi + SUPERBLOCK.s_knot_size]
	mov	qword [r8 + KFS.knot_size],	rcx

	mov	rcx,	qword [rdi + SUPERBLOCK.s_bit_block_map_size]
	mov	qword [r8 + KFS.bit_block_map_size],	rcx

	mov	eax,	1
	push	rdi
	call	cyjon_page_find_free_memory
	mov	qword [r8 + KFS.bit_block_map_address],	rdi
	call	cyjon_filesystem_kfs_block_read
	pop	rdi

	mov	rcx,	qword [rdi + SUPERBLOCK.s_knots_table_size]
	mov	qword [r8 + KFS.knots_table_size],	rcx

	add	rax,	qword [r8 + KFS.bit_block_map_size]
	push	rdi
	call	cyjon_page_find_free_memory
	mov	qword [r8 + KFS.knots_table_address],	rdi
	call	cyjon_filesystem_kfs_block_read
	pop	rdi

	pop	r8
	pop	rdi
	pop	rcx
	pop	rax

	ret

; rax - numer bloku
; rcx - ilość kolejnych bloków
; rdi - adres docelowy
; r8 - specyfikacja systemu plików
cyjon_filesystem_kfs_block_read:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; numer bloku zamień na sektor
	mul	qword [r8 + KFS.block_size_in_sectors]
	add	rax,	qword [r8 + KFS.partition_position]

.loop:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi

	; poszukaj adresu wolnego rekordu w demonie obsługi dysków
	call	cyjon_disk_io_find_free_record

	; uzupełnij rekord
	mov	byte [rdi + STATIC_DISK_IO_RECORD.io],	STATIC_DISK_IO_RECORD_IO_READ
	mov	qword [rdi + STATIC_DISK_IO_RECORD.lba],	rax
	mov	rax,	qword [r8 + KFS.block_size_in_sectors]
	mov	qword [rdi + STATIC_DISK_IO_RECORD.count],	rax
	mov	rax,	cr3
	mov	qword [rdi + STATIC_DISK_IO_RECORD.cr3],	rax
	mov	rax,	qword [rsp]
	mov	qword [rdi + STATIC_DISK_IO_RECORD.address],	rax

	; oznacz rekord na gotowy do przetworzenia
	mov	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_READY

.wait:
	; czekaj na przetworzenie zadania przez demona
	cmp	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_READY
	je	.wait

	; zwolnij rekord
	mov	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_CLOSED

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rax

	; odczytaj następny blok
	add	rax,	qword [r8 + KFS.block_size_in_sectors]
	; przesuń wskaźnik na następne miejsce dla bloku
	add	rdi,	qword [r8 + KFS.block_size]

	; sprawdź czy pozostały inne bloki do wczytania
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

; rax - numer bloku
; rcx - rozmiar danych w blokach
; rsi - adres źródłowy
; r8 - specyfikacja systemu plików
cyjon_filesystem_kfs_block_write:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi

	; numer bloku zamień na sektor
	mul	qword [r8 + KFS.block_size_in_sectors]
	add	rax,	qword [r8 + KFS.partition_position]

.loop:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi

	; poszukaj adresu wolnego rekordu w demonie obsługi dysków
	call	cyjon_disk_io_find_free_record

	; uzupełnij rekord
	mov	byte [rdi + STATIC_DISK_IO_RECORD.io],	STATIC_DISK_IO_RECORD_IO_WRITE
	mov	qword [rdi + STATIC_DISK_IO_RECORD.lba],	rax
	mov	rax,	qword [r8 + KFS.block_size_in_sectors]
	mov	qword [rdi + STATIC_DISK_IO_RECORD.count],	rax
	mov	rax,	cr3
	mov	qword [rdi + STATIC_DISK_IO_RECORD.cr3],	rax
	mov	qword [rdi + STATIC_DISK_IO_RECORD.address],	rsi

	; oznacz rekord na gotowy do przetworzenia
	mov	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_READY

.wait:
	; czekaj na przetworzenie zadania przez demona
	cmp	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_READY
	je	.wait

	; zwolnij rekord
	mov	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_CLOSED

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rax

	; odczytaj następny blok
	add	rax,	qword [r8 + KFS.block_size_in_sectors]
	; przesuń wskaźnik na następne miejsce dla bloku
	add	rsi,	qword [r8 + KFS.block_size]

	; sprawdź czy pozostały inne bloki do wczytania
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

; rax - numer supła
; rdi - gdzie załadować plik
; r8 - specyfikacja systemu plików
cyjon_filesystem_kfs_file_read:
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	mul	qword [r8 + KFS.knot_size]
	mov	rsi,	qword [r8 + KFS.knots_table_address]
	add	rsi,	rax

	mov	rax,	qword [rsi + KNOT.first_block]
	mov	rdx,	qword [rsi + KNOT.size]

.loop:
	mov	rcx,	qword [r8 + KFS.block_size_in_sectors]

.loopS:
	push	rax
	push	rdx
	push	rdi
	call	cyjon_disk_io_find_free_record
	mov	byte [rdi + STATIC_DISK_IO_RECORD.io],	STATIC_DISK_IO_RECORD_IO_READ
	mul	qword [r8 + KFS.block_size_in_sectors]
	add	rax,	qword [r8 + KFS.partition_position]
	mov	qword [rdi + STATIC_DISK_IO_RECORD.lba],	rax
	mov	qword [rdi + STATIC_DISK_IO_RECORD.count],	1
	mov	rax,	cr3
	mov	qword [rdi + STATIC_DISK_IO_RECORD.cr3],	rax
	mov	rax,	qword [rsp]
	mov	qword [rdi + STATIC_DISK_IO_RECORD.address],	rax
	mov	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_READY

.wait:
	cmp	byte [rdi + STATIC_DISK_IO_RECORD.type],	STATIC_DISK_IO_RECORD_TYPE_READY
	je	.wait

	xor	al,	al
	mov	rcx,	STATIC_DISK_IO_RECORD.size
	rep	stosb

	pop	rdi
	pop	rdx
	pop	rax

	sub	rdi,	0x08
	mov	rdi,	qword [rdi]
	cmp	rdi,	VARIABLE_EMPTY
	je	.end

	sub	rdx,	VARIABLE_DECREMENT
	jnz	.loop

.end:
	mov	rdx,	qword [rsi + KNOT.size_in_bytes]

	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

cyjon_filesystem_kfs_file_create:
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rax

	call	cyjon_filesystem_kfs_knot_find_free
	cmp	rdx,	VARIABLE_EMPTY
	je	.end

	mov	rcx,	qword [rsp + 0x20]
	call	cyjon_filesystem_kfs_directory_entry_add

	cmp	bl,	1
	

.end:
	pop	rax
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	ret

cyjon_filesystem_kfs_knot_find_free:
	push	rcx

.lock:
	cmp	byte [variable_semaphore_lock_knot_find_free],	VARIABLE_TRUE
	je	.lock

	mov	byte [variable_semaphore_lock_knot_find_free],	VARIABLE_TRUE

	mov	rcx,	qword [r8 + KFS.knots_table_size]
	shl	rcx,	12
	mov	rdi,	qword [r8 + KFS.knots_table_address]

.loop:
	; jeśli brak informacji o typie - wolny rekord
	cmp	word [rdi],	VARIABLE_EMPTY
	je	.found

	add	rdi,	qword [r8 + KFS.knot_size]
	sub	rcx,	qword [r8 + KFS.knot_size]
	jnz	.loop

	jmp	.end

.found:
	mov	rdx,	rdi
	sub	rdx,	qword [r8 + KFS.knots_table_address]
	shr	rdx,	7

.end:
	mov	byte [variable_semaphore_lock_knot_find_free],	VARIABLE_FALSE

	pop	rcx

	ret

cyjon_filesystem_kfs_directory_entry_add:
	push	rax
	push	rdi
	push	rcx


	shl	rax,	7
	mov	rdi,	qword [r8 + KFS.knots_table_address]
	mov	rcx,	qword [rdi + rax + KNOT.size]
	call	cyjon_page_find_free_memory
	shr	rax,	7
	call	cyjon_filesystem_kfs_file_read

	shl	rcx,	12

.free_entry:
	cmp	word [rdi + 0x08],	VARIABLE_EMPTY
	je	.found

	movzx	rax,	word [rdi + 0x08]
	add	rdi,	 rax
	sub	rcx,	rax

	cmp	rcx,	0x08 + ENTRY
	jnb	.free_entry

	jmp	$

.found:
	mov	qword [rdi + ENTRY.knot_id],	rdx
	mov	rax,	qword [rsp]	; ilość znaków w nazwie pliku
	mov	byte [rdi + ENTRY.chars],	al
	add	rax,	ENTRY.name
	mov	word [rdi + ENTRY.record_size],	ax
	mov	byte [rdi + ENTRY.type],	bl
	add	rdi,	ENTRY.name
	mov	rcx,	qword [rsp]
	rep	movsb

.end:
	pop	rcx
	pop	rdi
	pop	rax

	ret
