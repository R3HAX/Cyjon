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

variable_partition_specification_home	times	8	dq	VARIABLE_EMPTY

kfs_initialization:
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

cyjon_filesystem_kfs_block_read:
	push	rax
	push	rcx
	push	rdx

	mul	qword [r8 + KFS.block_size_in_sectors]
	add	rax,	qword [r8 + KFS.partition_position]

.loop1:
	push	rcx

	mov	rcx,	qword [r8 + KFS.block_size_in_sectors]

.loop2:
	call	cyjon_ide_sector_read
	add	rax,	VARIABLE_INCREMENT
	push	rcx
	mov	rcx,	1
	shl	rcx,	VARIABLE_DISK_SECTOR_SIZE
	add	rdi,	rcx
	pop	rcx
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop2

	pop	rcx
	sub	rcx,	VARIABLE_DECREMENT
	jnz	.loop1

	pop	rdx
	pop	rcx
	pop	rax

	ret

; rax - numer supła
; rdi - gdzie załadować plik
; r8 - specyfikacja systemu plików
cyjon_filesystem_kfs_read_file:
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

	mov	rcx,	1

.loop:
	call	cyjon_filesystem_kfs_block_read

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
