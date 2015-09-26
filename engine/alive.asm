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
	; sprawdź czy skorygować czas o jedną sekunde
	cmp	qword [variable_system_microtime],	VARIABLE_PIT_CLOCK_HZ
	jb	.uptime_no_change	; nie

	; cofnij czas o 1 sek
	sub	qword [variable_system_microtime],	VARIABLE_PIT_CLOCK_HZ
	; zwiększ ilość upłyniętych sekund
	inc	qword [variable_system_uptime]

.uptime_no_change:
	; pobierz aktualny czas z systemu (trzeba to zmienić, za często będzie pobierany, lepiej zamienić czas na początku na EPOCH i dodawać do niego UPTIME)
	call	cyjon_cmos_date_get

	; jądro systemu zakończyło analize zgłoszeń
	hlt

	; powrót na początek pętli
	jmp	alive
