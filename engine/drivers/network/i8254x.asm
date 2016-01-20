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

VARIABLE_NIC_INTEL_85240EM_VEN_DEV			equ	0x100E8086

VARIABLE_NIC_INTEL_85240EM_EEPROM_READ			equ	0x0014	; EEPROM Read
VARIABLE_NIC_INTEL_85240EM_MAC_ADDRESS			equ	0x5400	; Receive Address Low, +4 High

variable_network_i8254x_base_address			dq	VARIABLE_EMPTY
variable_network_i8254x_irq				db	VARIABLE_EMPTY
variable_network_i8254x_mac_address			dq	VARIABLE_EMPTY

struc	NIC_MAC_ADDRESS
	.0	resb	1
	.1	resb	1
	.2	resb	1
	.3	resb	1
	.4	resb	1
	.5	resb	1
endstruc

text_nic_i8254x						db	" Network controller i82540EM, MAC ", VARIABLE_ASCII_CODE_TERMINATOR

; 64 Bitowy kod programu
[BITS 64]

cyjon_network_i8254x_find_card:
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
	cmp	ax,	0x0200
	je	.check

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

.check:
	xor	edx,	edx	; VENDOR/DEVICE
	call	cyjon_pci_read

	cmp	eax,	VARIABLE_NIC_INTEL_85240EM_VEN_DEV
	jne	.end

	call	cyjon_network_i8254x_init

	jmp	.end

cyjon_network_i8254x_init:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r9
	push	r11

	xor	rax,	rax

	; pobierz adres przestrzeni pamięci do zarządzania kartą sieciową
	mov	dl,	0x04	; BAR0
	call	cyjon_pci_read

	; czy adres jest 64 bitowy?
	bt	eax,	2
	jnc	.no

	; zachowaj młodszą część adresu
	push	rax

	; adres jest 64 bitowy, pobierz starszą część
	mov	dl,	0x05	; BAR1
	call	cyjon_pci_read

	; połącz z młodszą częścią adresu
	mov	dword [rsp + VARIABLE_QWORD_HIGH],	eax

	; pobierz pełny adres 64 bitowy
	pop	rax

.no:
	and	al,	0xF0	; wyrównaj do pełnego słowa
	mov	qword [variable_network_i8254x_base_address],	rax

	; pobierz numer przerwania sprzętowego
	mov	dl,	0x0F	; IRQ
	call	cyjon_pci_read

	mov	byte [variable_network_i8254x_irq],	al

	; włącz PCI Bus Mastering
	; dokumentacja, strona: 91/410, tabelka: 4-3
	; // Enable Mastering. Ethernet controller in PCI-X   //
	; // mode is permitted to initiate a split completion //
	; // transaction regardless of the state of this bit. //
	mov	dl,	0x01	; Command Register
	call	cyjon_pci_read
	bts	eax,	2	; Enable Mastering
	call	cyjon_pci_write

	; udostępnij przestrzeń pamięci
	mov	rax,	qword [variable_network_i8254x_base_address]
	; ustaw właściwości rekordów/stron w tablicach stronicowania
	mov	rbx,	3	; flagi: 4 KiB, Administrator, Odczyt/Zapis, Dostępna
	mov	rcx,	32	; dokumentacja, strona: 88/410, tabelka: 4-2 // The memory register space is 128K bytes. //
	; załaduj adres fizyczny/logiczny tablicy PML4 jądra
	mov	r11,	cr3
	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_physical_area

	; pobierz adres MAC
	mov	rsi,	qword [variable_network_i8254x_base_address]
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_85240EM_MAC_ADDRESS]

	cmp	eax,	VARIABLE_EMPTY
	je	.try_via_eprom

	mov	dword [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.0],	eax
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_85240EM_MAC_ADDRESS]
	mov	dword [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.4],	eax

	jmp	.done

.try_via_eprom:
	; dokumentacja, strona: 248/410, tabelka: 13-7
	mov	dword [rsi + VARIABLE_NIC_INTEL_85240EM_EEPROM_READ],	0x0001
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_85240EM_EEPROM_READ]
	shr	eax,	16
	mov	word [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.0],	ax
	mov	dword [rsi + VARIABLE_NIC_INTEL_85240EM_EEPROM_READ],	0x0101
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_85240EM_EEPROM_READ]
	shr	eax,	16
	mov	word [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.2],	ax
	mov	dword [rsi + VARIABLE_NIC_INTEL_85240EM_EEPROM_READ],	0x0201
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_85240EM_EEPROM_READ]
	shr	eax,	16
	mov	word [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.4],	ax

.done:
	call	cyjon_network_i8254x_reset

	; wyświetl podstawową informację o trybie graficznym
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_nic_i8254x
	call	cyjon_screen_print_string

	mov	rsi,	text_colon
	xor	r8,	r8
	xor	r9,	r9

.loop:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_NUMBER
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	cx,	0x0210	; podstawa 16
	mov	r8b,	byte [variable_network_i8254x_mac_address + r9]
	int	STATIC_KERNEL_SERVICE

	inc	r9

	cmp	r9,	5
	ja	.end

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	int	STATIC_KERNEL_SERVICE

	jmp	.loop

.end:
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rsi,	text_paragraph
	int	STATIC_KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	r11
	pop	r9
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

cyjon_network_i8254x_reset:
	ret
