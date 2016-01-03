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

; 64 Bitowy kod programu
[BITS 64]

file_readme		dq	10
file_readme_pointer	db	"readme.txt"

;===============================================================================
;===============================================================================

; procedura zostanie usunięta z pamięci po wykonaniu
move_included_files_to_virtual_filesystem:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; pliki załaduj do wirtualnego systemu plików
	mov	r8,	variable_partition_specification_system

	; wskaźnik do tablicy plików
	mov	rsi,	files_table

.loop:
	;~ ; koniec tablicy?
	cmp	qword [rsi],	VARIABLE_EMPTY
	je	.end	; tak

	; zachowaj wskaźnik
	push	rsi

	; pobierz ilość znaków w nazwie pliku
	mov	rcx,	qword [rsi]

	; pobierz rozmiar pliku
	mov	rdx,	qword [rsi + 0x08]

	; ustaw wskaźnik na początek danych pliku
	mov	rdi,	qword [rsi + 0x10]

	; ustaw wskaźnik na nazwę pliku
	add	rsi,	0x20

	; zapisz do wirtualnego systemu plików
	call	cyjon_virtual_file_system_save_file

	; przywróć wskaźnik
	pop	rsi

	; przesuń na następny rekord
	add	rsi,	0x20
	add	rsi,	rcx

	; kontynuuj z pozostałymi plikami
	loop	.loop

.end:
	; wyświetl informacje o inicjalizacji wirtulnego systemu plików
	mov	rbx,	VARIABLE_COLOR_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string

	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_virtial_file_system
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

files_table:
	; plik
	dq	4				; ilość znaków w nazwie pliku
	dq	file_init_end - file_init	; rozmiar pliku w Bajtach
	dq	file_init			; wskaźnik początku pliku
	dq	file_init_end			; wskaźnik końca pliku
	db	'init'				; nazwa pliku

	dq	5
	dq	file_shell_end - file_shell
	dq	file_shell
	dq	file_shell_end
	db	'shell'

	dq	5
	dq	file_login_end - file_login
	dq	file_login
	dq	file_login_end
	db	'login'

	dq	4
	dq	file_help_end - file_help
	dq	file_help
	dq	file_help_end
	db	'help'

	dq	6
	dq	file_uptime_end - file_uptime
	dq	file_uptime
	dq	file_uptime_end
	db	'uptime'

	dq	4
	dq	file_moko_end - file_moko
	dq	file_moko
	dq	file_moko_end
	db	'moko'

	dq	2
	dq	file_ps_end - file_ps
	dq	file_ps
	dq	file_ps_end
	db	'ps'

	dq	4
	dq	file_date_end - file_date
	dq	file_date
	dq	file_date_end
	db	'date'

	dq	2
	dq	file_ls_end - file_ls
	dq	file_ls
	dq	file_ls_end
	db	'ls'

	dq	4
	dq	file_args_end - file_args
	dq	file_args
	dq	file_args_end
	db	'args'

	dq	5
	dq	file_touch_end - file_touch
	dq	file_touch
	dq	file_touch_end
	db	'touch'

	dq	4
	dq	file_free_end - file_free
	dq	file_free
	dq	file_free_end
	db	'free'

	dq	4
	dq	file_conf_end - file_conf
	dq	file_conf
	dq	file_conf_end
	db	'conf'

	dq	5
	dq	file_ascii_end - file_ascii
	dq	file_ascii
	dq	file_ascii_end
	db	'ascii'

	dq	6
	dq	file_colors_end - file_colors
	dq	file_colors
	dq	file_colors_end
	db	'colors'

	; koniec tablicy plików
	dq	VARIABLE_EMPTY

file_init:		incbin	'init.bin'
file_init_end:

file_shell:		incbin	'shell.bin'
file_shell_end:

file_login:		incbin	'login.bin'
file_login_end:

file_help:		incbin	'help.bin'
file_help_end: 

file_uptime:		incbin	'uptime.bin'
file_uptime_end:

file_moko:		incbin	'moko.bin'
file_moko_end:

file_ps:		incbin	'ps.bin'
file_ps_end:

file_date:		incbin	'date.bin'
file_date_end:

file_ls:		incbin	'ls.bin'
file_ls_end:

file_args:		incbin	'args.bin'
file_args_end:

file_touch:		incbin	'touch.bin'
file_touch_end:

file_free:		incbin	'free.bin'
file_free_end:

file_conf:		incbin	'conf.bin'
file_conf_end:

file_ascii:		incbin	'ascii.bin'
file_ascii_end:

file_colors:		incbin	'colors.bin'
file_colors_end:

text_virtial_file_system	db	" Virtual file system initialized.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

;===============================================================================
;===============================================================================

create_readme:
	; utwórz pusty plik
	mov	rax,	0	; w katalogu o Suple nr.0
	mov	rbx,	0x8000	; plik
	mov	rcx,	qword [file_readme]	; ilość znaków w nazwie pliku
	mov	rsi,	file_readme_pointer

	push	rax

	call	cyjon_filesystem_kfs_find_file
	jc	.exists

	pop	rax

	call	cyjon_filesystem_kfs_file_create

	; załaduj do pliku dane
	; rax - numer supła
	; rbx - rozmiar danych w blokach
	; rdx - rozmiar pliku w Bajtach
	; rsi - gdzie są dane
	; r8 - specyfikacja systemu plików
	push	rax
	mov	rax,	text_readme_end - text_readme
	mov	rcx,	qword [r8 + KFS.block_size]
	div	rcx
	cmp	rdx,	VARIABLE_EMPTY
	je	.file_size_ok

	add	eax,	VARIABLE_INCREMENT

.file_size_ok:
	mov	eax,	eax
	mov	rbx,	rax
	pop	rax
	mov	rdx,	text_readme_end - text_readme
	mov	rsi,	text_readme
	call	cyjon_filesystem_kfs_file_update

	ret

.exists:
	pop	rax

	ret

text_readme:
%include	"doc/readme.asm"
text_readme_end:

; etykiete końca kodu jądra wyrównaj do pełnego adresu strony
align	0x1000
