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

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]	

start:
	; --- ustaw kursor na ostatniej linii ---
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_SIZE
	int	STATIC_KERNEL_SERVICE
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	shr	rbx,	32
	dec	ebx
	shl	rbx,	32
	int	STATIC_KERNEL_SERVICE

	; specyfikacja komunikatu
	mov	rdi,	variable_table

	mov	rax,	0x0000001300000020
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	18
	mov	rax,	qword [text_window_message0_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message0
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	mov	rax,	0x0000000500000005
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	22
	mov	rax,	qword [text_window_message1_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message1
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	mov	rax,	0x0000000F00000040
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	10
	mov	rax,	qword [text_window_message2_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message2
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	mov	rax,	0x0000000100000010
	mov	qword [rdi + WINDOW_MESSAGE_INFO.position],	rax
	mov	qword [rdi + WINDOW_MESSAGE_INFO.width],	50
	mov	rax,	qword [text_window_message3_size]
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_width],	rax
	mov	rax,	text_window_message3
	mov	qword [rdi + WINDOW_MESSAGE_INFO.text_pointer],	rax
	call	library_window_message_info

	; program kończy działanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_KILL
	int	STATIC_KERNEL_SERVICE

%include	"library/window_message_info.asm"

variable_table	times	WINDOW_MESSAGE_INFO.structure_size	db	VARIABLE_EMPTY

text_window_message0_size	dq	31
text_window_message0		db	"This is a simple message box.", VARIABLE_ASCII_CODE_TERMINATOR

text_window_message1_size	dq	75
text_window_message1		db	"Next window, everything in the background has been transformed as a shadow.", VARIABLE_ASCII_CODE_TERMINATOR

text_window_message2_size	dq	44
text_window_message2		db	"The text is adjusted to the width of window.", VARIABLE_ASCII_CODE_TERMINATOR

text_window_message3_size	dq	625
text_window_message3		db	"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec scelerisque in quam vitae viverra. Pellentesque at venenatis mauris. Phasellus imperdiet egestas pretium. Etiam a velit ut enim laoreet ornare sit amet quis eros. Maecenas sed quam euismod, consequat nisl et, maximus quam. Ut est turpis, condimentum maximus erat a, hendrerit dignissim nisl. Curabitur mattis, leo non pellentesque pellentesque, urna nunc mollis dolor, id efficitur ipsum erat ac tortor. Quisque quis nisl fringilla, tempor ante sed, rhoncus felis. Nam consequat, justo et commodo dignissim, est augue cursus sapien, sed cursus nibh magna at dui.", VARIABLE_ASCII_CODE_TERMINATOR
