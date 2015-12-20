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
	.type				resw	1
	.name				resb	1
endstruc

variable_semaphore_lock_knot_find_free			db	VARIABLE_EMPTY

variable_partition_specification_home	times	8	dq	VARIABLE_EMPTY

cyjon_filesystem_kfs_find_file:
	push	rax
	push	rdx
	push	rdi

	mov	rdi,	qword [r8 + KFS.knots_table_address]
	mul	qword [r8 + KFS.knot_size]
	mov	rax,	qword [rdi + KNOT.size_in_bytes]

	pop	rdi
	pop	rdx
	pop	rax

	ret

cyjon_filesystem_kfs_update:
	push	rax
	push	rcx
	push	rsi

	; bit block map
	mov	rax,	1
	mov	rcx,	qword [r8 + KFS.bit_block_map_size]
	mov	rsi,	qword [r8 + KFS.bit_block_map_address]

.bit_block_map:
	call	cyjon_filesystem_kfs_block_write

	add	rax,	VARIABLE_INCREMENT
	add	rsi,	qword [r8 + KFS.block_size]
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.bit_block_map

	; rax - tablica supłów znajduje się zaraz za bit block map
	mov	rcx,	qword [r8 + KFS.knots_table_size]
	mov	rsi,	qword [r8 + KFS.knots_table_address]

.knot_table:
	call	cyjon_filesystem_kfs_block_write

	add	rax,	VARIABLE_INCREMENT
	add	rsi,	qword [r8 + KFS.block_size]
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.knot_table

.end:
	pop	rsi
	pop	rcx
	pop	rax

	ret
	

; rax - numer supła
; rbx - rozmiar danych w blokach
; rdx - rozmiar pliku w Bajtach
; rsi - gdzie są dane
; r8 - specyfikacja systemu plików
cyjon_filesystem_kfs_file_update:
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	rdx

	mul	qword [r8 + KFS.knot_size]
	mov	rdi,	qword [r8 + KFS.knots_table_address]
	add	rdi,	rax

	; nowy rozmiar pliku +rbx Bloków
	mov	qword [rdi + KNOT.size],	rbx

	; nowy rozmiar pliku +rdx Bajtów
	pop	rdx
	mov	qword [rdi + KNOT.size_in_bytes],	rdx

	mov	rax,	qword [rdi + KNOT.first_block]
	cmp	rax,	VARIABLE_EMPTY
	ja	.first_block_exists

	call	cyjon_filesystem_kfs_find_free_block
	call	cyjon_filesystem_kfs_clear_block

	mov	qword [rdi + KNOT.first_block],	rax

.first_block_exists:
	mov	rcx,	1
	call	cyjon_page_find_free_memory
	push	rdi
	call	cyjon_filesystem_kfs_block_read
	mov	rdi,	qword [rsp]
	push	rax

.indirect:
	mov	rax,	qword [rdi]
	cmp	rax,	VARIABLE_EMPTY
	ja	.direct

	call	cyjon_filesystem_kfs_find_free_block
	mov	qword [rdi],	rax

.direct:
	cmp	rdx,	qword [r8 + KFS.block_size]
	jae	.block_ok

	; to jest ostatni blok, na dodatek nie pełny
	push	rdi
	call	cyjon_page_allocate
	call	cyjon_page_clear
	push	rdi
	mov	rcx,	rdx
	rep	movsb
	mov	rsi,	qword [rsp]
	mov	rcx,	1
	call	cyjon_filesystem_kfs_block_write
	pop	rdi
	call	cyjon_page_release
	pop	rdi

	jmp	.block_prepared

.block_ok:
	call	cyjon_filesystem_kfs_block_write

.block_prepared:
	sub	rbx,	VARIABLE_DECREMENT
	jz	.end

	add	rdi,	0x08
	add	rsi,	qword [r8 + KFS.block_size]
	jmp	.indirect

.end:
	pop	rax
	mov	rcx,	1
	pop	rsi
	call	cyjon_filesystem_kfs_block_write

.the_end:
	; sprawdź czy plik był większy, zwolnij pozostałe miejsce w przeestrzeni partycji
	; cdn.

	; zaktualizuj system plików
	call	cyjon_filesystem_kfs_update

	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

; rax - numer bloku do wyczyszczenia na nośniku
cyjon_filesystem_kfs_clear_block:
	push	rcx
	push	rsi
	push	rdi

	mov	rcx,	1
	call	cyjon_page_allocate
	call	cyjon_page_clear

	push	rdi

	mov	rsi,	rdi
	call	cyjon_filesystem_kfs_block_write

	pop	rdi

	call	cyjon_page_release

	pop	rdi
	pop	rsi
	pop	rcx

	ret

; r8 - specyfikacja systemu plików
cyjon_filesystem_kfs_find_free_block:
	push	rsi
	push	rdi

	mov	rsi,	qword [r8 + KFS.bit_block_map_address]
	mov	rdi,	qword [r8 + KFS.bit_block_map_size]
	call	library_find_free_bit

	pop	rdi
	pop	rsi

	ret

cyjon_filesystem_kfs_initialization:
	push	rax
	push	rcx
	push	rdi
	push	r8

	call	cyjon_page_allocate
	call	cyjon_page_clear
	push	rdi
	call	ide_read_sectors

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

	pop	rdi
	call	cyjon_page_release

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

	; zapisz następny blok
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
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	mul	qword [r8 + KFS.knot_size]
	mov	rsi,	qword [r8 + KFS.knots_table_address]
	add	rsi,	rax

	mov	rax,	qword [rsi + KNOT.first_block]
	mov	rbx,	qword [rsi + KNOT.size]

	cmp	rax,	VARIABLE_EMPTY
	je	.end	; plik pusty

.read:
	mov	rcx,	1
	call	cyjon_page_find_free_memory
	push	rdi
	call	cyjon_filesystem_kfs_block_read
	pop	rsi
	mov	rdi,	qword [rsp]

.indirect:
	mov	rax,	qword [rsi]
	cmp	rax,	VARIABLE_EMPTY
	ja	.direct

	call	cyjon_filesystem_kfs_find_free_block
	mov	qword [rdi],	rax

.direct:
	call	cyjon_filesystem_kfs_block_read

	sub	rbx,	VARIABLE_DECREMENT
	jz	.end

	add	rsi,	0x08
	add	rdi,	qword [r8 + KFS.block_size]
	jmp	.indirect

.end:
	pop	rdi

	mov	rdx,	qword [rsi + KNOT.size_in_bytes]

	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

cyjon_filesystem_kfs_file_create:
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	call	cyjon_filesystem_kfs_knot_find_free
	cmp	rdx,	VARIABLE_EMPTY
	je	.end

	mov	rcx,	qword [rsp + 0x18]
	call	cyjon_filesystem_kfs_directory_entry_add

	; zwróć numer supła utworzonego pliku
	mov	rax,	rdx

	mov	rbx,	qword [rsp + 0x20]
	call	cyjom_filesystem_kfs_knot_create_empty

.end:
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	ret

cyjom_filesystem_kfs_knot_create_empty:
	push	rax
	push	rdi

	mov	rdi,	qword [r8 + KFS.knots_table_address]
	mul	qword [r8 + KFS.knot_size]
	mov	word [rdi + rax + KNOT.type],	bx

	pop	rdi
	pop	rax

	ret

cyjon_filesystem_kfs_knot_find_free:
	push	rcx
	push	rdi

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

	pop	rdi
	pop	rcx

	ret

cyjon_filesystem_kfs_directory_entry_add:
	push	rdx
	push	rax
	push	rcx
	push	rdi
	push	rcx

	mov	rcx,	qword [r8 + KFS.knot_size]
	mul	rcx
	mov	rdi,	qword [r8 + KFS.knots_table_address]
	mov	rcx,	qword [rdi + rax + KNOT.size]
	push	rcx
	call	cyjon_page_find_free_memory
	mov	rcx,	qword [r8 + KFS.knot_size]
	div	rcx
	call	cyjon_filesystem_kfs_file_read

	push	rax

	mov	rcx,	qword [rsp + 0x08]
	shl	rcx,	12

	push	rdi

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
	mov	rax,	qword [rsp + 0x38]
	mov	qword [rdi + ENTRY.knot_id],	rax
	mov	rax,	qword [rsp + 0x28]	; ilość znaków w nazwie pliku
	mov	byte [rdi + ENTRY.chars],	al
	add	rax,	ENTRY.name
	mov	word [rdi + ENTRY.record_size],	ax
	mov	word [rdi + ENTRY.type],	bx
	add	rdi,	ENTRY.name
	mov	rcx,	qword [rsp + 0x18]
	rep	movsb

	; aktualizuj tablice supłów na nośniku
	pop	rsi
	mov	rax,	VARIABLE_MEMORY_PAGE_SIZE
	mul	qword [rsp + 0x08]
	mov	rdx,	rax
	pop	rax
	pop	rbx
	call	cyjon_filesystem_kfs_file_update

.end:
	pop	rcx
	pop	rdi
	pop	rcx
	pop	rax
	pop	rdx

	ret
