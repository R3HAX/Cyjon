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

text_caution				db	"::", VARIABLE_ASCII_CODE_TERMINATOR
text_colon				db	":", VARIABLE_ASCII_CODE_TERMINATOR

text_paragraph				db	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

text_kib				db	" KiB",	VARIABLE_ASCII_CODE_TERMINATOR
text_mib				db	" MiB", VARIABLE_ASCII_CODE_TERMINATOR

variable_system_microtime		dq	VARIABLE_EMPTY
variable_system_uptime			dq	VARIABLE_EMPTY

variable_disk_io_ready			db	VARIABLE_EMPTY
variable_filesystem_io_ready		db	VARIABLE_EMPTY

variable_disk_sector_size_in_bytes	dq	512	; wartość domyślna
variable_disk_interface_read		dq	VARIABLE_EMPTY
variable_disk_interface_write		dq	VARIABLE_EMPTY

variable_partition_interface_file_read	dq	VARIABLE_EMPTY
variable_partition_interface_file_write	dq	VARIABLE_EMPTY
