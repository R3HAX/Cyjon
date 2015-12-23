# Cyjon OS
Prosty system operacyjny dla procesorów z rodziny amd64/x86-64.

![alt tag](http://wataha.net/shot/shot8.png)

![alt tag](http://wataha.net/shot/shot9.png)

#Wymagania sprzętowe:
- procesor z rodziny amd64/x86-64,
- 1 MiB pamięci RAM pod adresem fizycznym 0x0000000000100000,
- obsługa VBE w trybie 640x400 8 bpp.

#Oprogramowanie:
- kompilator Nasm v2.11.08+ (http://www.nasm.us/)
- oprogramowanie Bochs v2.6.8+ (http://sourceforge.net/projects/bochs/files/bochs/),

#Kompilacja (z poziomu konsoli):

    GNU/Linux:
    polecenie "make"

    MS/Windows:
    polecenie "make.bat"

#Uruchomienie:

    W konfiguracji oprogramowania Bochs ustawiamy dysk wirtualny build/disk.raw jako IDE0 Master.

#Uwagi:
Emulatory pod systemem z rodziny MS/Windows nie obsługują prawidłowo klawiszy strzałek/kursorów. Nie mam pojęcia kogo to wina - emulatora czy systemu.


Udało ci się nanieść poprawkę, ulepszenie lub coś zupełnie nowego w źródle systemu?
Dopisz się do grupy programistów Wataha.net!

- Andrzej Adamczyk, akasei

Kod źródlowy systemu operacyjnego jest na licencji Creative Commons BY-NC-ND 4.0

![alt tag](http://mirrors.creativecommons.org/presskit/buttons/80x15/png/by-nc-nd.png)
