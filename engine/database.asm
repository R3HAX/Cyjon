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

text_caution			db	"::", ASCII_CODE_TERMINATOR
text_paragraph			db	ASCII_CODE_ENTER, ASCII_CODE_NEWLINE, ASCII_CODE_TERMINATOR

text_kib			db	" KiB",	ASCII_CODE_TERMINATOR

variable_system_microtime	dq	0x0000000000000000
variable_system_uptime		dq	0x0000000000000000
