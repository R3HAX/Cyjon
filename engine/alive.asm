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

;===============================================================================
; główna pętla jądra systemu
; IN:
;	brak
; OUT:
;	brak
;
; brak rejestrów zachowanych
alive:
	; sprawdź czy zakończyć jakikolwiek proces
	cmp	qword [variable_process_close],	0x0000000000000000
	jne	cyjon_process_close

	; sprawdź czy uruchomić nowy proces
	cmp	qword [variable_process_new],	0x0000000000000000
	jne	cyjon_process_init.ready	; pomiń poszukiwania za plikiem

	; jądro systemu zakończyło analize zgłoszeń
	hlt

	; powrót na początek pętli
	jmp	alive
