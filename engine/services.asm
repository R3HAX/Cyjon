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
; procedura obsługująca przerwanie programowe procesów
; IN:
;	różne
; OUT:
;	różne
;
; różne rejestry zachowane
irq64:
	; czy zarządzać ekranem?
	cmp	ah,	0x01
	je	irq64_screen

.end:
	; powrót z przerwania programowanego
	iretq

irq64_screen:
	; sprawdź czy wyświetlić ciąg znaków
	cmp	al,	0x01
	je	.print_string

	; brak obsługi
	jmp	irq64.end

.print_string:
	; wyświetl ciąg znaków na ekranie
	call	cyjon_screen_print_string

	; koniec obsługi procedury
	jmp	irq64.end

	; pozostała część w trakcie przepisywania
