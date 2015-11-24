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

variable_idt_structure:
variable_interrupt_descriptor_table_limit	dw	VARIABLE_MEMORY_PAGE_SIZE	; rozmiar tablicy / do 512 rekordów
variable_interrupt_descriptor_table_address	dq	VARIABLE_EMPTY

;===============================================================================
; procedura tworzy tablicę IDT do obsługi przerwań i wyjątków
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
interrupt_descriptor_table:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; przygotuj miejsce na Tablicę Deskryptorów Przerwań
	call	cyjon_page_allocate	; plik: engine/paging.asm
	; wyczyść wszystkie rekordy
	call	cyjon_page_clear	; plik: engine/paging.asm

	; zapisz adres Tablicy Deskryptorów Przerwań
	mov	qword [variable_interrupt_descriptor_table_address],	rdi

	; utworzymy obsługę 32 wyjątków (zombi, w przyszłości utworzy się odpowiednie procedury obsługi) procesora
	mov	rax,	itd_cpu_exception
	mov	bx,	0x8E00	; typ - wyjątek procesora
	mov	rcx,	32	; wszystkie wyjątki procesora
	call	recreate_record	; utwórz

	; utworzymy obsługę 16 przerwań (zombi) sprzętowych
	; gdyby jakimś cudem wystąpiły
	; co niektóre dostaną prawidłową procedurę obsługi
	mov	rax,	itd_hardware_interrupt
	mov	bx,	0x8F00	; typ - przerwanie sprzętowe
	mov	rcx,	16	; wszystkie przerwania sprzętowe
	call	recreate_record	; utwórz

	; utworzymy obsługę pozostałych 208 przerwań (zombi) programowych
	; tylko jedno z nich (przerwanie 64, 0x40) dostanie prawidłową procedurę obsługi
	mov	rax,	itd_software_interrupt
	mov	bx,	0xEF00	; typ - przerwanie programowe
	mov	rcx,	208	; pozostałe rekordy w tablicy
	call	recreate_record	; utwórz

	; podłączamy poszczególne procedury obsługi przerwań/wyjątków

	;---------------------------------------------------------------

	; procedura obsługi przerwania sprzętowego zegara
	mov	rax,	irq32	; plik: engine/multitasking.asm
	mov	bx,	0x8F00	; typ - przerwanie sprzętowe
	mov	rcx,	1	; modyfikuj jeden rekord
	; ustaw adres rekordu
	mov	rdi,	qword [variable_interrupt_descriptor_table_address]
	add	rdi,	0x10 * 32	; podrekord 0x00
	call	recreate_record	; wykonaj

	; procedura obsługi przerwania sprzętowego klawiatury
	mov	rax,	irq33	; plik: engine/keyboard.asm
	call	recreate_record	; wykonaj

	;---------------------------------------------------------------

	; procedura obsługi przerwania programowego użytkownika
	mov	rax,	irq64	; plik: engine/multitasking.asm
	mov	bx,	0xEF00	; typ - przerwanie sprzętowe
	mov	rcx,	1	; modyfikuj jeden rekord
	; ustaw adres rekordu
	mov	rdi,	qword [variable_interrupt_descriptor_table_address]
	add	rdi,	0x10 * 64	; 40-ty wpis
	call	recreate_record	; wykonaj

	;---------------------------------------------------------------

	; załaduj Tablicę Deskryptorów Przerwań
	lidt	[variable_idt_structure]

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z przerwania
	ret

;===============================================================================
; procedura podstawowej obsługi wyjątku/przerwania procesora
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
itd_cpu_exception:
	push	r15
	push	r11
	push	r14
	push	r10
	push	r13
	push	r9
	push	r12
	push	r8
	push	rdx
	push	rbp
	push	rcx
	push	rdi
	push	rbx
	push	rsi
	push	rax

	call	cyjon_screen_cursor_lock

	mov	rbx,	VARIABLE_COLOR_RED
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_cpu_exception
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_rax
	call	cyjon_screen_print_string

	pop	rax
	mov	rcx,	16
	mov	ch,	1
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_rsi
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_rbx
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_rdi
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_rcx
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_rbp
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_rdx
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_rsp
	call	cyjon_screen_print_string

	cmp	qword [rsp + 0x40],	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	ja	.no_code_error

	; pomiń kod błędu
	mov	rax,	qword [rsp + 0x60]

	jmp	.error_code

.no_code_error:
	mov	rax,	qword [rsp + 0x58]

.error_code:
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_rip
	call	cyjon_screen_print_string


	cmp	qword [rsp + 0x40],	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	ja	.no_code_error2

	; pomiń kod błędu
	mov	rax,	qword [rsp + 9 * 0x08]

	jmp	.error_code2

.no_code_error2:
	mov	rax,	qword [rsp + 8 * 0x08]

.error_code2:
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_eflags
	call	cyjon_screen_print_string

	cmp	qword [rsp + 0x40],	VARIABLE_KERNEL_PHYSICAL_ADDRESS
	ja	.no_code_error1

	; pomiń kod błędu
	mov	rax,	qword [rsp + 11 * 0x08]

	jmp	.error_code1

.no_code_error1:
	mov	rax,	qword [rsp + 10 * 0x08]

.error_code1:
	mov	rcx,	15
	mov	r8,	4

	bt	ax,	cx
	jnc	.noID

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_id
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noID:
	dec	rcx

	bt	ax,	cx
	jnc	.noVIP

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_vip
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noVIP:
	dec	rcx

	bt	ax,	cx
	jnc	.noVIF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_vif
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noVIF:
	dec	rcx

	bt	ax,	cx
	jnc	.noAC

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_ac
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noAC:
	dec	rcx

	bt	ax,	cx
	jnc	.noVM

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_vm
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noVM:
	dec	rcx

	bt	ax,	cx
	jnc	.noRF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_rf
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noRF:
	dec	rcx

	bt	ax,	cx
	jnc	.noNT

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_nt
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noNT:
	dec	rcx

	bt	ax,	cx
	jnc	.noOF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_of
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noOF:
	dec	rcx

	bt	ax,	cx
	jnc	.noDF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_df
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noDF:
	dec	rcx

	bt	ax,	cx
	jnc	.noIF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_if
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noIF:
	dec	rcx

	bt	ax,	cx
	jnc	.noTF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_tf
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noTF:
	dec	rcx

	bt	ax,	cx
	jnc	.noSF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_sf
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noSF:
	dec	rcx

	bt	ax,	cx
	jnc	.noZF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_zf
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noZF:
	dec	rcx

	bt	ax,	cx
	jnc	.noAF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_af
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noAF:
	dec	rcx

	bt	ax,	cx
	jnc	.noPF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_pf
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noPF:
	dec	rcx

	bt	ax,	cx
	jnc	.noCF

	xchg	rcx,	r8
	mov	rsi,	text_cpu_exception_flag_cf
	call	cyjon_screen_print_string
	xchg	rcx,	r8

.noCF:
	mov	rcx,	16
	mov	ch,	1
	mov	rsi,	text_cpu_exception_r8
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_r12
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_r9
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_r13
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_r10
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_r14
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	rsi,	text_cpu_exception_r11
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	dword [variable_screen_cursor_xy],	23
	mov	rbx,	qword [variable_screen_cursor_xy]
	call	screen_cursor_set_xy

	mov	rbx,	VARIABLE_COLOR_LIGHT_RED

	mov	rsi,	text_cpu_exception_r15
	call	cyjon_screen_print_string

	pop	rax
	call	cyjon_screen_print_number

	mov	rsi,	text_paragraph
	call	cyjon_screen_print_string
	call	cyjon_screen_print_string

	call	cyjon_screen_cursor_unlock

	sti

	jmp	irq64_process.process_kill

text_cpu_exception	db	VARIABLE_ASCII_CODE_ENTER, ":: An unexpected error occurred, the program has been closed.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rax		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, " RAX 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rbx		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, " RBX 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rcx		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, " RCX 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rdx		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, " RDX 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rsi		db	"  RSI 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rdi		db	"  RDI 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rbp		db	"  RBP 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rsp		db	"  RSP 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_eflags	db	"  EFLAGS:", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_id	db	" ID", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_vip	db	" VIP", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_vif	db	" VIF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_ac	db	" AC", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_vm	db	" VM", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_rf	db	" RF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_nt	db	" NT", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_of	db	" OF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_df	db	" DF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_if	db	" IF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_tf	db	" TF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_sf	db	" SF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_zf	db	" ZF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_af	db	" AF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_pf	db	" PF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_flag_cf	db	" CF", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r8		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, " R8  0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r12		db	"  R12 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r9		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, " R9  0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r13		db	"  R13 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r10		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, " R10 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r14		db	"  R14 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r11		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, " R11 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_r15		db	"  R15 0x", VARIABLE_ASCII_CODE_TERMINATOR
text_cpu_exception_rip		db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_NEWLINE, " RIP 0x", VARIABLE_ASCII_CODE_TERMINATOR

;===============================================================================
; procedura podstawowej obsługi przerwania sprzętowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
itd_hardware_interrupt:
	; wyświetl informację
	mov	rbx,	VARIABLE_COLOR_RED
	mov	rcx,	-1	; wyświetl całą informację
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_hardware_interrupt
	call	cyjon_screen_print_string	; plik: engine/screen.asm

	; wstrzymaj przełączanie procesów
	inc	qword [variable_multitasking_serpentine_blocked]

	; zatrzymaj dalsze wykonywanie kodu jądra
	jmp	$

text_hardware_interrupt	db	"Unhandled hardware interrupt!", VARIABLE_ASCII_CODE_TERMINATOR

;===============================================================================
; procedura podstawowej obsługi przerwania programowego
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
itd_software_interrupt:
	; standardowo zastosuję zabicie procesu, który zrobił coś czego być był nie powinien

	; wyświetl informację
	mov	rbx,	VARIABLE_COLOR_RED
	mov	rcx,	-1	; wyświetl całą informację
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_software_interrupt
	call	cyjon_screen_print_string	; plik: engine/screen.asm

	; wstrzymaj przełączanie procesów
	inc	qword [variable_multitasking_serpentine_blocked]

	; zatrzymaj dalsze wykonywanie kodu jądra
	jmp	$

text_software_interrupt	db	"Unhandled software interrupt!", VARIABLE_ASCII_CODE_TERMINATOR

;===============================================================================
; procedura tworzy/modyfikuje rekord w Tablicy Deskryptorów Przerwań
; IN:
;	rax	- adres logiczny procesury obsługi wyjątku/przerwania
;	bx	- typ: wyjątek/przerwanie(sprzętowe/programowe)
;	rcx	- ilość kolejnych rekordów o tej samej procedurze obsługi
;	rdi	- adres logiczny rekordu w Tablicy Deskryptorów Przerawń do modyfikacji
; OUT:
;	rdi	- adres kolejnego rekordu w Tablicy Deskryptorów Przerwań
;
; pozostałe rejestry zachowane
recreate_record:
	; zachowaj oryginalny rejestr
	push	rcx

.next:
	; zachowaj adres procedury obsługi
	push	rax

	; załaduj do tablicy adres obsługi wyjątku (bity 15...0)
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; selektor deskryptora kodu (GDT)
	mov	ax,	0x0008
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; typ: wyjątek/przerwanie(sprzętowe/programowe)
	mov	ax,	bx
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; przywróć wartość zmiennej
	mov	rax,	qword [rsp]

	; przemieszczamy do ax bity 31...16 z rax
	shr	rax,	16
	stosw	; zapisz zawartość rejestru AX pod adres w rejestrze RDI, zwiększ rejestr RDI o 2 Bajty

	; przemieszczamy do eax bity 63...32 z rax
	shr	rax,	16
	stosd	; zapisz zawartość rejestru EAX pod adres w rejestrze RDI, zwiększ rejestr RDI o 4 Bajty

	; pola zastrzeżone
	xor	eax,	eax
	stosd	; zapisz zawartość rejestru EAX pod adres w rejestrze RDI, zwiększ rejestr RDI o 4 Bajty

	; przywróć adres procedury obsługi
	pop	rax

	; utwórz pozostałe rekordy
	loop	.next

	; przywróć oryginalny rejestr
	pop	rcx

	; powrót z procedury
	ret
