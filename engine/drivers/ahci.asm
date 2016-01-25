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
	jnc	.no_drive

	; pobierz status urządzenia
	add	rsi,	VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS
	mov	eax,	dword [rsi + VARIABLE_AHCI_PORT_REGISTER_SSTS]
	cmp	eax,	VARIABLE_EMPTY
	je	.no_drive

	; przygouj miejsce dla przestrzeni poleceń
	call	cyjon_page_allocate
	call	cyjon_page_clear
	mov	qword [variable_ahci_cmd_list],	rdi

	; przygouj miejsce dla przestrzeni Frame Information Structure
	call	cyjon_page_allocate
	call	cyjon_page_clear
	mov	qword [variable_ahci_fis],	rdi

	; poinformuj urządzenie/dysk o adresie przestrzeni poleceń
	mov	rdi,	rsi
	add	rdi,	VARIABLE_AHCI_PORT_REGISTER_CLBA
	stosq

	; poinformuj urządzenie/dysk o adresie przestrzeni Frame Information Structure
	mov	rdi,	rsi
	add	rdi,	VARIABLE_AHCI_PORT_REGISTER_FB
	stosq

	; wyczyść rekordy
	xor	rax,	rax
	stosq	; Port x Interrupt Status
	stosq	; Port x Interrupt Enable

	mov	byte [variable_ahci_semaphore],	VARIABLE_TRUE

	; wyświetl informacje podłączonym nośniku
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_ahci_found
	call	cyjon_screen_print_string

.no_drive:
	jmp	$

	jmp	.end
