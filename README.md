# Cyjon OS
Prosty system operacyjny dla procesorów z rodziny amd64/x86-64.

![alt tag](http://wataha.net/shot/shot7.png)

#Wymagania sprzętowe:
- procesor z rodziny amd64/x86-64,
- 1 MiB pamięci RAM pod adresem fizycznym 0x0000000000100000,
- obsługa VBE w trybie 640x480 24bpp.

#Oprogramowanie:
- kompilator Nasm v2.11.08+ (http://www.nasm.us/)
- oprogramowanie Bochs v2.6.8+ (http://sourceforge.net/projects/bochs/files/bochs/) lub Qemu v2.4.1+ (http://wiki.qemu.org/Main_Page) do wirtualizacji,

#Kompilacja (z poziomu konsoli):

    GNU/Linux:
    polecenie "make"

    MS/Windows:
    polecenie "make.bat"

#Uwagi:
Emulatory pod systemem z rodziny MS/Windows nie obsługują prawidłowo klawiszy strzałek/kursorów. Nie mam pojęcia kogo to wina - emulatora czy systemu.

#Uruchomienie:

    qemu-system-x86_64 -hda build/disk.raw




Udało ci się nanieść poprawkę, ulepszenie lub coś zupełnie nowego w źródle systemu?
Dopisz się do grupy programistów Wataha.net!

- Andrzej Adamczyk, akasei

Kod źródlowy systemu operacyjnego jest na licencji Creative Commons BY-NC-ND

![alt tag](http://mirrors.creativecommons.org/presskit/buttons/80x15/png/by-nc-nd.png)
