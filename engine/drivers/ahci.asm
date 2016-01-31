; Copyright (C) 2013-2016 Wataha.net
; All Rights Reserved
;
; LICENSE Creative Commons BY-NC-ND 4.0
; See LICENSE.TXT
;
; Driver based on BareMetal OS https://github.com/ReturnInfinity/BareMetal-OS
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

	xor	rax,	rax
	mov	rcx,	1
	call	cyjon_page_allocate
	push	rdi

	call	ahci_read_sectors

	mov	ebx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	0x0410
	mov	edx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	movzx	rax,	word [rdi + 0x01FE]
	call	cyjon_screen_print_number

	jmp	$

	jmp	.end

; rax - numer bezwzględny (LBA) sektora
; rcx - ilość sektorów do odczytu
; rdi - gdzie załadować
ahci_read_sectors:
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	push	rcx
	push	rdi
	push	rax
	push	rax

	; cały poniższy kod do naprawy

	mov	rsi,	qword [variable_ahci_base_address]
	add	rsi,	VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS

	; ???
	mov	eax,	0x00010005
	mov	rdi,	qword [variable_ahci_cmd_list]
	stosd
	xor	eax,	eax
	stosd
	mov	rax,	qword [variable_ahci_cmd_table]
	stosq
	xor	eax,	eax
	stosd
	stosd
	stosd
	stosd

	; Command FIS setup
	mov rdi, qword [variable_ahci_cmd_table]	; Build a command table for Port 0
	mov eax, 0x00258027		; 25 READ DMA EXT, bit 15 set, fis 27 H2D
	stosd				; feature 7:0, command, c, fis
	pop rax				; Restore the start sector number
	shl rax, 36
	shr rax, 36			; Upper 36 bits cleared
	bts rax, 30			; bit 30 set for LBA
	stosd				; device, lba 23:16, lba 15:8, lba 7:0
	pop rax				; Restore the start sector number
	shr rax, 24
	stosd				; feature 15:8, lba 47:40, lba 39:32, lba 31:24
	mov rax, rcx			; Read the number of sectors given in rcx
	stosd				; control, ICC, count 15:8, count 7:0
	mov rax, 0x00000000
	stosd				; reserved

	; PRDT setup
	mov rdi, qword [variable_ahci_cmd_table]
	add	rdi,	0x80
	pop rax				; Restore the destination memory address
	stosd				; Data Base Address
	shr rax, 32
	stosd				; Data Base Address Upper
	stosd				; Reserved
	pop rax				; Restore the sector count
	shl rax, 9			; multiply by 512 for bytes
	sub rax, 1			; subtract 1 (4.2.3.3, DBC is number of bytes - 1)
	stosd				; Description Information

	add rsi, rdx

	mov rdi, rsi
	add rdi, 0x10			; Port x Interrupt Status
	xor eax, eax
	stosd

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0
	mov eax, [rdi]
	bts eax, 4			; FRE
	bts eax, 0			; ST
	stosd

	mov rdi, rsi
	add rdi, 0x38			; Command Issue
	mov eax, 0x00000001		; Execute Command Slot 0
	stosd

.pool:
	mov eax, [rsi+0x38]
	cmp eax, 0
	jne .pool

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0
	mov eax, [rdi]
	btc eax, 4			; FRE
	btc eax, 0			; ST
	stosd

	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	ret

ahci_write_sectors:
	ret
