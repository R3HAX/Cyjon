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

; kolory, stałe
%include	'config.asm'

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG REAL_HIGH_MEMORY_ADDRESS]

start:
	; przygotowanie przestrzeni pod dokument i interfejsu
	call	initialization

.loop:
	; call	debug

	; sprawdź czy dokument jest zmodyfikowany
	cmp	byte [semaphore_modified],	0x00
	je	.noKey	; nie

	; tak, wyświetl informacje
	call	modified

.noKey:
	; pobierz znak z bufora klawiatury
	mov	ax,	0x0200
	int	0x40	; wykonaj

	; nic?
	cmp	ax,	0x0000
	je	.noKey

	; naciśnięcie klawisza enter?
	cmp	ax,	0x000D
	je	key_enter

	; naciśnięcie klawisza backspace?
	cmp	ax,	0x0008
	je	key_backspace

	; naciśnięcie klawisza Home?
	cmp	ax,	0x8007
	je	key_home

	; naciśnięcie klawisza End?
	cmp	ax,	0x8008
	je	key_end

	; naciśnięcie klawisza Delete?
	cmp	ax,	0x8009
	je	key_delete

	; naciśnięcie klawisza PageUp?
	cmp	ax,	0x800A
	je	key_pageup

	; naciśnięcie klawisza PageDown?
	cmp	ax,	0x800B
	je	key_pagedown

	; naciśnięcie klawisza ArrowLeft
	cmp	ax,	0x8002
	je	key_arrow_left

	; naciśnięcie klawisza ArrowRight
	cmp	ax,	0x8003
	je	key_arrow_right

	; naciśnięcie klawisza ArrowUp
	cmp	ax,	0x8004
	je	key_arrow_up

	; naciśnięcie klawisza ArrowDown
	cmp	ax,	0x8005
	je	key_arrow_down

	; klawisz CTRL -------------------------------------------------

	; naciśnięcie lewego klawisza ctrl?
	cmp	ax,	0x001D
	je	key_ctrl_push

	; naciśnięcie prawego klawisza ctrl?
	cmp	ax,	0x8006
	je	key_ctrl_push

	; puszczenie lewego klawisza ctrl?
	cmp	ax,	0x009D
	je	key_ctrl_pull

	; puszczenie prawego klawisza ctrl?
	cmp	ax,	0xB006
	je	key_ctrl_pull

	; klawisze funkcyjne -------------------------------------------

	; sprawdź czy wywołano skrót klawiszowy
	cmp	byte [semaphore_ctrl],	0x00
	je	.noShortcut

	; sprawdź skrót klawiszowy Ctrl + x
	cmp	ax,	"x"
	je	key_function_exit

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

.noShortcut:
	; sprawdź czy znak do wyświetlenia jest drukowalny -------------

	; test pierwszy
	cmp	ax,	0x0020	; spacja
	jb	.loop	; jeśli mniejsze, pomiń

	; test drugi
	cmp	ax,	0x007E	; ostatni drukowalny znak z tablicy ASCII
	ja	.loop	; jeśli większe, pomiń

	; zapisz znak do dokumentu
	jmp	save_into_document

%include	'software/moko/init.asm'

%include	'software/moko/key_home.asm'
%include	'software/moko/key_end.asm'
%include	'software/moko/key_delete.asm'
%include	'software/moko/key_ctrl.asm'
%include	'software/moko/key_pageup.asm'
%include	'software/moko/key_pagedown.asm'
%include	'software/moko/key_backspace.asm'
%include	'software/moko/key_enter.asm'
%include	'software/moko/key_arrow_left.asm'
%include	'software/moko/key_arrow_right.asm'
%include	'software/moko/key_arrow_up.asm'
%include	'software/moko/key_arrow_down.asm'

%include	'software/moko/function_key_read_file.asm'
%include	'software/moko/function_key_save.asm'
%include	'software/moko/function_key_exit.asm'
%include	'software/moko/function_key_cut.asm'

%include	'software/moko/count_chars_in_document_line.asm'
%include	'software/moko/get_address_of_shown_line.asm'
%include	'software/moko/save_char_into_document.asm'
%include	'software/moko/allocate_memory_in_document.asm'
%include	'software/moko/move_part_of_memory_up.asm'
%include	'software/moko/count_chars_in_previous_line.asm'
%include	'software/moko/set_cursor_position.asm'

; pokaż zawartość dokumentu na ekranie :)
%include	'software/moko/the_show_must_go_on.asm'

%include	'library/find_first_word.asm'
%include	'library/input.asm'
%include	'library/align_address_up_to_page.asm'

document_chars_count	dq	0x0000000000000000
document_lines_count	dq	0x0000000000000000
line_chars_count	dq	0x0000000000000000
cursor_position		dq	0x0000000000000000
show_line		dq	0x0000000000000000
cursor_yx		dq	0x0000000000000000

text_new_line		db	ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR
text_clear_line		db	' '

stop:
