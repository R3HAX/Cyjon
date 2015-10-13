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

%include	"config.asm"

%define	VARIABLE_PROGRAM_VERSION		""

VARIABLE_CURSOR_POSITION_INIT		equ	0x0000000200000000
VARIABLE_INTERFACE_HEADER_HEIGHT	equ	2
VARIABLE_INTERFACE_MENU_HEIGHT		equ	3
VARIABLE_INTERFACE_HEIGHT		equ	VARIABLE_INTERFACE_HEADER_HEIGHT + VARIABLE_INTERFACE_MENU_HEIGHT

[BITS 64]
[DEFAULT REL]
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; przygotowanie przestrzeni pod dokument i interfejsu
	call	initialization

.debug:
	call	debug

.noKey:
	; pobierz znak z bufora klawiatury
	mov	ax,	0x0200
	int	0x40	; wykonaj

	; nic?
	cmp	ax,	VARIABLE_EMPTY	
	je	.noKey

	; klawisz enter
	cmp	ax,	VARIABLE_ASCII_CODE_ENTER
	je	key_enter

;	; naciśnięcie klawisza backspace?
;	cmp	ax,	VARIABLE_ASCII_CODE_BACKSPACE
;	je	key_backspace
;
;	; naciśnięcie klawisza Home?
;	cmp	ax,	0x8007
;	je	key_home
;
;	; naciśnięcie klawisza End?
;	cmp	ax,	0x8008
;	je	key_end
;
;	; naciśnięcie klawisza Delete?
;	cmp	ax,	0x8009
;	je	key_delete
;
;	; naciśnięcie klawisza PageUp?
;	cmp	ax,	0x800A
;	je	key_pageup
;
;	; naciśnięcie klawisza PageDown?
;	cmp	ax,	0x800B
;	je	key_pagedown
;
;	; naciśnięcie klawisza ArrowLeft
;	cmp	ax,	0x8002
;	je	key_arrow_left
;
;	; naciśnięcie klawisza ArrowRight
;	cmp	ax,	0x8003
;	je	key_arrow_right
;
;	; naciśnięcie klawisza ArrowUp
;	cmp	ax,	0x8004
;	je	key_arrow_up
;
;	; naciśnięcie klawisza ArrowDown
;	cmp	ax,	0x8005
;	je	key_arrow_down
;
;	; klawisz CTRL -------------------------------------------------
;
;	; naciśnięcie lewego klawisza ctrl?
;	cmp	ax,	0x001D
;	je	key_ctrl_push
;
;	; naciśnięcie prawego klawisza ctrl?
;	cmp	ax,	0x8006
;	je	key_ctrl_push
;
;	; puszczenie lewego klawisza ctrl?
;	cmp	ax,	0x009D
;	je	key_ctrl_pull
;
;	; puszczenie prawego klawisza ctrl?
;	cmp	ax,	0xB006
;	je	key_ctrl_pull
;
;	; klawisze funkcyjne -------------------------------------------
;
;	; sprawdź czy wywołano skrót klawiszowy
;	cmp	byte [semaphore_ctrl],	0x00
;	je	.noShortcut
;
;	; sprawdź skrót klawiszowy Ctrl + x
;	cmp	ax,	"x"
;	je	key_function_exit
;
;	; sprawdź skrót klawiszowy Ctrl + r
;	cmp	ax,	"r"
;	je	key_function_read
;
;	; sprawdź skrót klawiszowy Ctrl + o
;	cmp	ax,	"o"
;	je	key_function_save
;
;	; sprawdź skrót klawiszowy Ctrl + k
;	cmp	ax,	"k"
;	je	key_function_cut
;
;.noShortcut:
	;-----------------------------------------------------------------------
	; sprawdź czy znak jest możliwy do wyświetlenia ------------------------

	; test pierwszy
	cmp	ax,	VARIABLE_ASCII_CODE_SPACE	; pierwszy znak z tablicy ASCII
	jb	.noKey	; jeśli mniejsze, pomiń

	; test drugi
	cmp	ax,	0x007E	; ostatni znak z tablicy ASCII
	ja	.noKey	; jeśli większe, pomiń

	; zapisz znak do dokumentu
	call	save_into_document
	jmp	screen_update

%include	"software/moko/init.asm"

;%include	'software/moko/key_home.asm'
;%include	'software/moko/key_end.asm'
;%include	'software/moko/key_delete.asm'
;%include	'software/moko/key_ctrl.asm'
;%include	'software/moko/key_pageup.asm'
;%include	'software/moko/key_pagedown.asm'
;%include	'software/moko/key_backspace.asm'
%include	"software/moko/key_enter.asm"
;%include	'software/moko/key_arrow_left.asm'
;%include	'software/moko/key_arrow_right.asm'
;%include	'software/moko/key_arrow_up.asm'
;%include	'software/moko/key_arrow_down.asm'

;%include	'software/moko/function_key_read_file.asm'
;%include	'software/moko/function_key_save.asm'
;%include	'software/moko/function_key_exit.asm'
;%include	'software/moko/function_key_cut.asm'

%include	"software/moko/procedure_count_chars_in_previous_line.asm"
%include	"software/moko/procedure_count_chars_in_document_line.asm"
;%include	'software/moko/get_address_of_shown_line.asm'
%include	"software/moko/save_into_document.asm"
;%include	'software/moko/allocate_memory_in_document.asm'
;%include	'software/moko/move_part_of_memory_up.asm'

; pokaż zawartość dokumentu na ekranie :)
;%include	'software/moko/the_show_must_go_on.asm'

;%include	'library/find_first_word.asm'
;%include	'library/input.asm'
%include	"library/align_address_up_to_page.asm"

%include	"software/moko/debug.asm"

variable_document_address_start			dq	VARIABLE_EMPTY
variable_document_address_end			dq	VARIABLE_EMPTY
variable_document_chars_count			dq	VARIABLE_EMPTY
variable_document_show_from_line		dq	VARIABLE_EMPTY
variable_line_chars_count			dq	VARIABLE_EMPTY
variable_line_show_from_char			dq	VARIABLE_EMPTY
variable_line_count				dq	1
variable_line_current				dq	VARIABLE_EMPTY
variable_screen_size				dq	VARIABLE_EMPTY
variable_cursor_position			dq	VARIABLE_CURSOR_POSITION_INIT
variable_cursor_indicator			dq	VARIABLE_EMPTY
variable_cursor_in_line				dq	VARIABLE_EMPTY

variable_file_name_chars_count			dq	VARIABLE_EMPTY
variable_file_name_buffor	times	256	db	VARIABLE_EMPTY

text_header_default	db	"New file", VARIABLE_ASCII_CODE_TERMINATOR

text_exit_shortcut	db	'^x', 0x00
text_exit		db	' Exit  ', 0x00

stop:
