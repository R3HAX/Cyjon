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

; 64 Bitowy kod programu
[BITS 64]

VARIABLE_IDE_PRIMARY			equ	0x01F0
VARIABLE_IDE_PRIMARY_REG_DATA		equ	0x01F0
VARIABLE_IDE_PRIMARY_REG_FEATURES	equ	0x01F1
VARIABLE_IDE_PRIMARY_REG_COUNTER	equ	0x01F2
VARIABLE_IDE_PRIMARY_REG_LBA_LOW	equ	0x01F3
VARIABLE_IDE_PRIMARY_REG_LBA_MIDDLE	equ	0x01F4
VARIABLE_IDE_PRIMARY_REG_LBA_HIGH	equ	0x01F5
VARIABLE_IDE_PRIMARY_REG_DRIVE		equ	0x01F6
VARIABLE_IDE_PRIMARY_REG_STATUS		equ	0x01F7
VARIABLE_IDE_PRIMARY_REG_COMMAND	equ	0x01F7
VARIABLE_IDE_PRIMARY_REG_ALTERNATE	equ	0x03F6
VARIABLE_IDE_PRIMARY_REG_CONTROL	equ	0x03F6

VARIABLE_IDE_PRIMARY_MASTER		equ	0xA0
VARIABLE_IDE_PRIMARY_SLAVE		equ	0xB0

VARIABLE_IDE_CMD_READ_PIO_EXT		equ	0x24
VARIABLE_IDE_CMD_IDENTIFY		equ	0xEC

VARIABLE_IDE_SR_ERR			equ	1
VARIABLE_IDE_SR_DRQ			equ	3
VARIABLE_IDE_SR_DF			equ	5
VARIABLE_IDE_SR_BSY			equ	7

VARIABLE_IDE_IDENTIFY_SERIAL		equ	20
VARIABLE_IDE_IDENTIFY_MODEL		equ	54
VARIABLE_IDE_IDENTIFY_SIZE		equ	100

variable_ide_buffor	times	2048	db	VARIABLE_EMPTY

text_ide_disk_found			db	" Disk ATA found ", VARIABLE_ASCII_CODE_TERMINATOR
text_ide_disk_size			db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, "    Size: ", VARIABLE_ASCII_CODE_TERMINATOR
text_ide_disk_serial			db	", serial: ", VARIABLE_ASCII_CODE_TERMINATOR

variable_disk_name	times	41	db	0x00
variable_disk_size_in_sectors		dq	VARIABLE_EMPTY

ide_initialize:
	; wyłącz przerwania dla kontrolera IDE PRIMARY
	mov	al,	2	; wartość
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_CONTROL
	out	dx,	al

	; wybierz dysk podpięty pod IDE PRIMARY
	mov	al,	VARIABLE_IDE_PRIMARY_MASTER
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_DRIVE
	out	dx,	al

	call	ide_wait

	; wyślij polecenie identyfikacji podpiętego urządzenia
	mov	al,	VARIABLE_IDE_CMD_IDENTIFY
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_COMMAND
	out	dx,	al

	call	ide_wait

	; sprawdź odpowiedź z podpiętego urządzenia
	mov	rdx,	VARIABLE_IDE_PRIMARY_REG_STATUS
	in	al,	dx
	cmp	al,	VARIABLE_EMPTY
	je	.error

.loop:
	; pobierz status urządzenia
	in	al,	dx

	bt	ax,	VARIABLE_IDE_SR_BSY
	jc	.loop	; urządzenie jest zajęte przetwarzaniem polecenia
	bt	ax,	VARIABLE_IDE_SR_DRQ
	jnc	.loop	; urządzenia nie jest gotowe do przesłania danych

	; pobierz odpowiedź z urządzenia
	mov	rcx,	128
	mov	rdx,	VARIABLE_IDE_PRIMARY_REG_DATA
	mov	rdi,	variable_ide_buffor
	rep	insw

	; wyświetl informacje podłączonym nośniku
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_ide_disk_found
	call	cyjon_screen_print_string

	mov	rcx,	40
	mov	rsi,	variable_ide_buffor
	add	rsi,	VARIABLE_IDE_IDENTIFY_MODEL
	mov	rdi,	variable_disk_name

.rename:
	lodsw
	rol	ax,	8
	stosw

	sub	rcx,	VARIABLE_DECREMENT
	jnz	.rename

	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	rcx,	40
	mov	rsi,	variable_disk_name
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_ide_disk_size
	call	cyjon_screen_print_string

	mov	rdi,	variable_ide_buffor
	mov	eax,	dword [rdi + VARIABLE_IDE_IDENTIFY_SIZE]
	mov	qword [variable_disk_size_in_sectors],	rax

	; zamień rozmiar BCD (bajty) na binarny (MiB)
	shr	rax,	12
	shr	rax,	12

	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	rcx,	10	; podstawa
	call	cyjon_screen_print_number

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_mib
	call	cyjon_screen_print_string

	mov	rsi,	text_paragraph
	call	cyjon_screen_print_string

	; powrót z procedury
	ret

.error:
	; 0 - nośnika nie znaleziono
	; 1 - to nie jest urządzenie ATA, prawdopodobnie PATA
	jmp	$

.end:
	; powrót z procedury
	ret

ide_wait:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	; zmarnuj 400ms czasu
	mov	rdx,	VARIABLE_IDE_PRIMARY_REG_ALTERNATE
	in	al,	dx

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

; rax - lba
; rcx - ilość sektorów
; rdi - gdzie zapisać
ide_read_sectors:
	push	rbx
	push	rdx
	push	rax

.wait:
	; pobierz status urządzenia
	in	al,	dx

	bt	ax,	VARIABLE_IDE_SR_BSY
	jc	.wait	; urządzenie jest zajęte przetwarzaniem polecenia

	; tryb LBA
	mov	ax,	0xE0
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_DRIVE
	out	dx,	al

	pop	rax

	call	ide_lba

	mov	al,	VARIABLE_IDE_CMD_READ_PIO_EXT
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_COMMAND
	out	dx,	al

.read:
	call	ide_pool
	cmp	al,	VARIABLE_EMPTY
	je	.ok

	; wystąpił błąd urządzenia
	jmp	$

.ok:
	push	rcx

	mov	rcx,	256
	rep	insw

	pop	rcx

	sub	rcx,	VARIABLE_DECREMENT
	jnz	.read

	jmp	$

ide_pool:
	push	rcx
	push	rdx

	; 400ns
	mov	cl,	4

.wait:
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_ALTERNATE
	in	al,	dx

	sub	rcx,	VARIABLE_DECREMENT
	jnz	.wait	; czekaj kolejne 100ns

.bsy_bit:
	; pobierz status urządzenia
	in	al,	dx

	bt	ax,	VARIABLE_IDE_SR_BSY
	jc	.bsy_bit	; urządzenie jest zajęte przetwarzaniem polecenia

	in	al,	dx

	bt	ax,	VARIABLE_IDE_SR_ERR
	jnc	.no_err

	; błąd
	mov	ax,	2

	jmp	.end

.no_err:
	bt	ax,	VARIABLE_IDE_SR_DF
	jnc	.no_df

	; błąd urządzenia
	mov	al,	1

	jmp	.end

.no_df:
	bt	ax,	VARIABLE_IDE_SR_DRQ
	jc	.ok

	; błąd - brak danych do przesłania
	mov	al,	3

	jmp	.end

.ok:
	xor	al,	al

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

ide_lba:
	; zachowaj
	mov	rbx,	rax

	; starsza część ilości odczytywanych sektorów
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_COUNTER
	mov	al,	0x00
	out	dx,	al

	; al = 31..24
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_LOW
	mov	rax,	rbx
	shr	rax,	24
	out	dx,	al

	; al = 39..32
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_MIDDLE
	mov	rax,	rbx
	shr	rax,	32
	out	dx,	al

	; al = 47..40
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_HIGH
	mov	rax,	rbx
	shr	rax,	40
	out	dx,	al

	; młodsza część ilości odczytywanych sektorów
	mov	dx,	VARIABLE_IDE_PRIMARY + IDE_PORT.COUNTER
	mov	al,	cl
	out	dx,	al

	; al = 7..0
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_LOW
	mov	rax,	rbx
	out	dx,	al

	; al = 15..8
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_MIDDLE
	mov	al,	bh
	out	dx,	al

	; al = 23..16
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_HIGH
	mov	rax,	rbx
	shr	rax,	16
	out	dx,	al

	; powrót z procedury
	ret
