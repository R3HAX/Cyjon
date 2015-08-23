Podstawowe przerwanie systemowe dla oprogramowania. Dlaczego liczba 0x40? W przeliczeniu na system dziesiętny > 64, sentyment z czasów C64, a poza tym jest to połowa wartości przerwania z systemów GNU/Linux.

Rejestr AH to zbiór procedur o zbliżonej działalności.
Rejestr AL to wybrana procedura z zbioru.


#AH 0x00 - procedury obsługi procesów

	AL 0x00	- proces wywołujący procedure zostanie zamknięty

	AL 0x01	- uruchomienie nowego procesu:
		Wejście:
			rcx	- ilość znaków w nazwie pliku
			rsi	- wskaźnik do nazwy pliku
		Wyjście:
			rcx	- identyfikator uruchomionego procesu (PID) lub ZERO jeśli programu nie znaleziono na nośniku

			pozostałe rejestry zachowane

	AL 0x02	- sprawdź czy proces o podanym identyfikatorze (PID) jest uruchomiony
		Wejście:
			rcx	- numer PID procesu
		Wyjście:
			rcx	- ZERO jeśli proces nie istnieje, w innym przypadku wartość zachowana

			pozostałe rejestry zachowane

#AH 0x01 - procedury obsługi ekranu

	AL 0x00	- czyszczenie ekranu konsoli, ustawienie kursora w pozycji X:0, Y:0

	AL 0x01	- wypisanie na ekranie ciągu znaków o sprecyzowanej ilości od miejsca kursora
		Wejście:
			rbx	- kolor znaków
			rcx	- ilość znaków do wypisania z ciągu, jeśli wartość -1, wypisane zostaną wszystkie znaki do pierwszego znaku TERMINATORA (0x00)
			rdx	- kolor tła znaku
			rsi	- wskaźnik do ciągu znaków
		Wyjście:
			brak

			wszystkie rejestry zachowane

	AL 0x02	- wyświetla znak na ekranie
		Wejście:
			rbx	- kolor znaku
			rcx	- ilość kopii znaku do wyświetlenia
			rdx	- kolor tła znaku
			r8	- kod ASCII znaku do wyświetlenia
		Wyjście:
			brak

			wszystkie rejestry zachowane

	AL 0x03	- wyświetl liczbę
		Wejście:
			rbx	- kolor liczby/cyfry
			rcx	- syatem liczbowy, wartość od 2 (binarna) do 36 (wartości poza heksadecymalnymi [A..F] zostaną uzupełnione kolejnymi literami z alfabetu łacińskiego)
			rdx	- kolor tła znaku
			r8	- liczba/cyfra do wyświetlenia
		Wyjście:
			brak

			wszystkie rejestry zachowane

	AL 0x04	- pobierz pozycje kursora na ekranie
		Wyjście:
			rbx	- młodsza część (ebx) wartość X, starsza część (bity 63..32) wartość Y

			pozostałe rejestry zachowane

	AL 0x05 - ustaw pozycje kursora na ekranie
		Wejście:
			rbx	- młodsza część (ebx) wartość X, starsza część (bity 63..32) wartość Y

			wszystkie rejestry zachowane

	AL 0x06 - pobierz rozmiar ekranu w znakach
		Wyjście:
			rbx	- młodsza część (ebx) wartość X, starsza część (bity 63..32) wartość Y

#AH 0x02 - procedury obsługi klawiatury

	AL 0x00 - pobierz znak z bufora klawiatury
		Wyjście:
			rax	- kod ASCII klawisza przechowywanego w buforze klawiatury, jeśli wartość ZERO > bufor pusty
