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

VARIABLE_AHCI_PCI					equ	0x0106

VARIABLE_AHCI_HBA_MEMORY_REGISTER_CAP			equ	0x00	; Host Capabilities
VARIABLE_AHCI_HBA_MEMORY_REGISTER_GHC			equ	0x04	; Global Host Control
VARIABLE_AHCI_HBA_MEMORY_REGISTER_IS			equ	0x08	; Interrupt Status
VARIABLE_AHCI_HBA_MEMORY_REGISTER_PI			equ	0x0C	; Ports Implemented
VARIABLE_AHCI_HBA_MEMORY_REGISTER_VS			equ	0x10	; Version
VARIABLE_AHCI_HBA_MEMORY_REGISTER_CCC_CTL		equ	0x14	; Command Completion Coalescing Control
VARIABLE_AHCI_HBA_MEMORY_REGISTER_CCC_PORTS		equ	0x18	; Command Completion Coalescing Ports
VARIABLE_AHCI_HBA_MEMORY_REGISTER_EM_LOC		equ	0x1C	; Enclosure Management Location
VARIABLE_AHCI_HBA_MEMORY_REGISTER_EM_CTL		equ	0x20	; Enclosure Management Control
VARIABLE_AHCI_HBA_MEMORY_REGISTER_CAP2			equ	0x24	; Host Capabilities Extended
VARIABLE_AHCI_HBA_MEMORY_REGISTER_BOHC			equ	0x28	; BIOS/OS Handoff Control and Status

VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS		equ	0x0100
VARIABLE_AHCI_PORT_REGISTER_CLBA			equ	0x0000	; Command List Base Address
VARIABLE_AHCI_PORT_REGISTER_FB				equ	0x0008	; FIS Base Address
VARIABLE_AHCI_PORT_REGISTER_IS				equ	0x0010	; Interrupt Status
VARIABLE_AHCI_PORT_REGISTER_IE				equ	0x0014	; Interrupt Enable
VARIABLE_AHCI_PORT_REGISTER_CMD				equ	0x0018	; Command and Status
VARIABLE_AHCI_PORT_REGISTER_TFD				equ	0x0020	; Task File Data
VARIABLE_AHCI_PORT_REGISTER_SIG				equ	0x0024	; Signature
VARIABLE_AHCI_PORT_REGISTER_SSTS			equ	0x0028	; Serial ATA Status
VARIABLE_AHCI_PORT_REGISTER_SCTL			equ	0x002C	; Serial ATA Control
VARIABLE_AHCI_PORT_REGISTER_SERR			equ	0x0030	; Serial ATA Error
VARIABLE_AHCI_PORT_REGISTER_SACT			equ	0x0034	; Serial ATA Active
VARIABLE_AHCI_PORT_REGISTER_CI				equ	0x0038	; Command Issue
VARIABLE_AHCI_PORT_REGISTER_SNTF			equ	0x003C	; Serial ATA Notification
VARIABLE_AHCI_PORT_REGISTER_FBS				equ	0x0040	; FIS-based Switching Control
VARIABLE_AHCI_PORT_REGISTER_DEVSLP			equ	0x0044	; Device Sleep
VARIABLE_AHCI_PORT_REGISTER_VS				equ	0x0070	; Vendor Specific

VARIABLE_AHCI_COMMAND_HEADER_CFL			equ	0x00000005	; Command FIS Length 4 DW (default)
VARIABLE_AHCI_COMMAND_HEADER_A				equ	0x00000020	; ATAPI
VARIABLE_AHCI_COMMAND_HEADER_W				equ	0x00000040	; Write
VARIABLE_AHCI_COMMAND_HEADER_P				equ	0x00000080	; Prefetchable
VARIABLE_AHCI_COMMAND_HEADER_R				equ	0x00000100	; Reset
VARIABLE_AHCI_COMMAND_HEADER_B				equ	0x00000200	; BIST
VARIABLE_AHCI_COMMAND_HEADER_C				equ	0x00000400	; Clear Busy upon R_OK
VARIABLE_AHCI_COMMAND_HEADER_PRDTL			equ	0x00010000	; Physical Region Descriptor Table Length (default)

VARIABLE_AHCI_COMMAND_TABLE_CFIS			equ	0x00	; Command FIS (up to 64 bytes)
VARIABLE_AHCI_COMMAND_TABLE_ACMD			equ	0x40	; ATAPI Command (12 or 16 bytes)
VARIABLE_AHCI_COMMAND_TABLE_PRDT			equ	0x80	; Physical Region Descriptor Table
VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBA			equ	0x80	; Data Base Address
VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBC			equ	0x8C	; Data Byte Count

variable_ahci_semaphore		db	VARIABLE_EMPTY
variable_ahci_base_address	dq	VARIABLE_EMPTY
variable_ahci_port		dq	VARIABLE_EMPTY
variable_ahci_cmd_list		dq	VARIABLE_EMPTY
variable_ahci_cmd_table		dq	VARIABLE_EMPTY
variable_ahci_fis		dq	VARIABLE_EMPTY

text_ahci_found			db	" Serial ATA drive found.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

; 64 Bitowy kod programu
[BITS 64]

cyjon_ahci_initialize:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r11

	xor	rbx,	rbx
	xor	rcx,	rcx
	mov	rdx,	2	; class/subclass

.next:
	call	cyjon_pci_read

	shr	eax,	16
	cmp	ax,	VARIABLE_AHCI_PCI
	je	.setup

	inc	ecx

	cmp	ecx,	256
	jb	.next

	inc	ebx
	xor	ecx,	ecx

	cmp	ebx,	256
	jb	.next

.end:
	; nie znaleziono kontrolera sieci

	; przywróć oryginalne rejestry
	pop	r11
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

.setup:
	; pobierz BAR5, adres przestrzeni konfiguracji AHCI
	mov	dl,	9
	call	cyjon_pci_read

	; zapamiętaj
	mov	dword [variable_ahci_base_address],	eax

	; udostępnij przestrzeń pamięci
	mov	rax,	qword [variable_ahci_base_address]
	; ustaw właściwości rekordów/stron w tablicach stronicowania
	mov	rbx,	3	; flagi: 4 KiB, Administrator, Odczyt/Zapis, Dostępna
	mov	rcx,	1	; 4096 Bajtów
	; załaduj adres fizyczny/logiczny tablicy PML4 jądra
	mov	r11,	cr3
	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_physical_area

	mov	rsi,	rax

	; pobierz specyfikacje portów (dostępnych)
	mov	eax,	dword [rsi + VARIABLE_AHCI_HBA_MEMORY_REGISTER_PI]

	; sprawdź port zero
	bt	eax,	0
	jnc	.end

	; pobierz status urządzenia
	add	rsi,	VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS
	mov	eax,	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_SSTS]
	cmp	eax,	VARIABLE_EMPTY
	je	.end

	; przygouj miejsce dla przestrzeni poleceń
	call	cyjon_page_allocate
	call	cyjon_page_clear
	mov	qword [variable_ahci_cmd_list],	rdi

	; poinformuj urządzenie/dysk o adresie przestrzeni poleceń
	mov	rax,	rdi
	mov	rdi,	rsi
	add	rdi,	VARIABLE_AHCI_PORT_REGISTER_CLBA
	stosq

	; przygouj miejsce dla przestrzeni Frame Information Structure
	call	cyjon_page_allocate
	call	cyjon_page_clear
	mov	qword [variable_ahci_fis],	rdi

	; poinformuj urządzenie/dysk o adresie przestrzeni Frame Information Structure
	mov	rax,	rdi
	mov	rdi,	rsi
	add	rdi,	VARIABLE_AHCI_PORT_REGISTER_FB
	stosq

	; wyczyść rekordy
	xor	rax,	rax
	stosq	; Port x Interrupt Status
	stosq	; Port x Interrupt Enable

	; przygouj miejsce dla przestrzeni tablicy poleceń
	call	cyjon_page_allocate
	call	cyjon_page_clear
	mov	qword [variable_ahci_cmd_table],	rdi

	; wyświetl informacje podłączonym nośniku
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_ahci_found
	call	cyjon_screen_print_string

	; ustaw interfejs dysku na AHCI
	mov	rax,	ahci_read_sectors
	mov	qword [variable_disk_interface_read],	rax
	mov	rax,	ahci_write_sectors
	mov	qword [variable_disk_interface_write],	rax

	mov	byte [variable_ahci_semaphore],	VARIABLE_TRUE

	mov	rax,	0
	mov	rcx,	1
	call	cyjon_page_allocate
	push	rdi

	call	ahci_read_sectors

	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	0x0410
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	pop	rdi
	movzx	rax,	word [rdi + 0x1FE]
	call	cyjon_screen_print_number

	mov	rax,	1
	mov	rcx,	1
	call	cyjon_page_allocate
	push	rdi

	call	ahci_read_sectors

	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	0x0410
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	pop	rdi
	movzx	rax,	word [rdi + 0x1FE]
	call	cyjon_screen_print_number

	jmp	$

	jmp	.end

; rax - numer bezwzględny (LBA) sektora
; rcx - ilość sektorów do odczytu
; rdi - gdzie załadować
ahci_read_sectors:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; zmienne lokalne
	push	rcx
	push	rdi
	push	rax
	push	rax

	mov	rdi,	qword [variable_ahci_cmd_list]

	; DW 0
	mov	eax,	VARIABLE_AHCI_COMMAND_HEADER_PRDTL | VARIABLE_AHCI_COMMAND_HEADER_CFL
	stosd

	; DW 1
	xor	eax,	eax
	stosd

	; DW 2
	mov	rax,	qword [variable_ahci_cmd_table]
	stosd

	; DW 3
	shr	rax,	32
	stosd

	; DW 4, 5, 6, 7
	stosd
	stosd
	stosd
	stosd

	; VARIABLE_AHCI_COMMAND_TABLE_CFIS
	mov	rdi,	qword [variable_ahci_cmd_table]

	; 0x00 Features, 0x25 READ DMA EXT, 0x80 C bit set, 0x27 H2D
	mov	eax,	0x00258027
	stosd

	; przywróć numer bezwzględny pierwszego sektora do odczytania
	pop	rax

	; port 0
	and	eax,	0x00FFFFFF

	; włącz tryb LBA
	bts	rax,	30
	stosd	; LBA 23..0

	; przywróć numer bezwzględny pierwszego sektora do odczytania
	pop	rax

	; przesuń bity 31..24 na początek rejestru
	shr	rax,	24
	stosd	; Feature 15..8, LBA 31..24

	; załaduj ilość sektorów do odczytania
	mov	rax,	rcx
	stosd	; Control 31..24, ICC 23..16, Count 15..0

	; 32 bity zastrzeżone
	xor	eax,	eax
	stosd

	mov	rdi,	qword [variable_ahci_cmd_table]

	; pobierz adres docelowy
	pop	rax

	; bity 31..0
	mov	dword [rdi + VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBA],	eax
	; bity 63..32
	shr	rax,	32
	mov	dword [rdi + VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBA + VARIABLE_DWORD_SIZE],	eax

	; pobierz ilość sektorów do odczytania
	pop	rax
	; zamień na Bajty
	shl	rax,	9
	; licz od zera
	dec	rax
	mov	dword [rdi + VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBC],	eax

	mov	rsi,	qword [variable_ahci_base_address]
	add	rsi,	VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS

	; zresetuj status przerwania
	mov	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_IS],	VARIABLE_EMPTY

	; pobierz informacje o poleceniu i statusie
	mov	eax,	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_CMD]
	bts	eax,	4	; FRE - włącz przesyłanie z dysku do pamięci
	bts	eax,	0	; ST - rozpocznij
	; aktualizuj
	mov	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_CMD],	eax

	; Wykonaj działania na porcie 0
	mov	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_CI],	VARIABLE_TRUE

.pool:
	; czekaj na zakończenie operacji przesyłu danych
	cmp	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_CI], VARIABLE_EMPTY
	jne	.pool

	; pobierz informacje o poleceniu i statusie
	mov	eax,	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_CMD]
	btr	eax,	4	; FRE - wyłącz przesyłanie z dysku do pamięci
	btr	eax,	0	; ST - zatrzymaj
	; aktualizuj
	mov	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_CMD],	eax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

ahci_write_sectors:
	ret
