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

VARIABLE_CONF_WINDOW_MESSAGE_INFO_WIDTH_DEFAULT	equ	18

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]	

start:
	; THIS IS A TEST FILE

	; --- ustaw kursor na ostatniej linii ---

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SIZE
	int	STATIC_KERNEL_SERVICE

	mov	qword [variable_screen_size],	rbx
	mov	qword [variable_screen_cursor],	rbx

	dec	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH]
	mov	rbx,	qword [variable_screen_cursor]

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	int	STATIC_KERNEL_SERVICE

	; wyświetl komunikat na środku ekranu
	shr	dword [variable_screen_cursor],	1
	sub	dword [variable_screen_cursor],	VARIABLE_CONF_WINDOW_MESSAGE_INFO_WIDTH_DEFAULT / 2
	shr	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH],	1
	; podnieś wyświetlane okno o rozmiar obydwu marginesów
	sub	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH],	VARIABLE_WINDOW_MESSAGE_INFO_MARGIN

	mov	rbx,	qword [variable_screen_cursor]

	mov	rdi,	variable_table
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rbx
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	VARIABLE_CONF_WINDOW_MESSAGE_INFO_WIDTH_DEFAULT
	mov	rax,	qword [text_window_message0_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message0
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	; wyświetl drugi komunikat w lewym górnym rogu
	mov	rax,	0x0000000500000005
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	22
	mov	rax,	qword [text_window_message1_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message1
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	; wyświetl trzeci komunikat
	mov	eax,	dword [variable_screen_size]
	shr	rax,	1
	sub	dword [variable_screen_size],	eax
	mov	dword [variable_screen_size + VARIABLE_QWORD_HIGH],	0x08
	mov	rax,	qword [variable_screen_size]
	add	rax,	10

	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	10
	mov	rax,	qword [text_window_message2_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message2
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	; wyświetl czwarty komunikat
	mov	rax,	qword [variable_screen_size]
	mov	qword [variable_screen_cursor],	rax
	mov	eax,	dword [variable_screen_cursor]
	shr	rax,	1
	sub	dword [variable_screen_cursor],	eax
	mov	dword [variable_screen_cursor + VARIABLE_QWORD_HIGH],	0x08
	mov	rax,	qword [variable_screen_cursor]
	sub	rax,	5

	mov	rax,	0x0000001E00000019
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	50
	mov	rax,	qword [text_window_message3_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message3
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	; program kończy działanie
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE

.error:

variable_screen_size		dq	VARIABLE_EMPTY
variable_screen_cursor		dq	VARIABLE_EMPTY

variable_table	times	8	dq	VARIABLE_EMPTY

text_window_message0_size	dq	31
text_window_message0		db	"This is a simple message box.", VARIABLE_ASCII_CODE_TERMINATOR

text_window_message1_size	dq	75
text_window_message1		db	"Next window, everything in the background has been transformed as a shadow.", VARIABLE_ASCII_CODE_TERMINATOR

text_window_message2_size	dq	44
text_window_message2		db	"The text is adjusted to the width of window.", VARIABLE_ASCII_CODE_TERMINATOR

text_window_message3_size	dq	625
text_window_message3		db	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec scelerisque in quam vitae viverra. Pellentesque at venenatis mauris. Phasellus imperdiet egestas pretium. Etiam a velit ut enim laoreet ornare sit amet quis eros. Maecenas sed quam euismod, consequat nisl et, maximus quam. Ut est turpis, condimentum maximus erat a, hendrerit dignissim nisl. Curabitur mattis, leo non pellentesque pellentesque, urna nunc mollis dolor, id efficitur ipsum erat ac tortor. Quisque quis nisl fringilla, tempor ante sed, rhoncus felis. Nam consequat, justo et commodo dignissim, est augue cursus sapien, sed cursus nibh magna at dui.", VARIABLE_ASCII_CODE_TERMINATOR

%include	"library/window_message_info.asm"
