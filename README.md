# Cyjon OS
Prosty system operacyjny dla procesorów z rodziny x86-64.

![alt tag](http://wataha.net/show/show.png)

#Wymagania sprzętowe:
- procesor z rodziny x86-64,
- 1 MiB pamięci RAM pod adresem fizycznym 0x0000000000100000,
- obsługa SuperVGA w trybie 800x600 o głębi kolorów 24 lub 32 bity.

#Oprogramowanie:
- kompilator Nasm wersja 2.11.08 lub nowsza, http://www.nasm.us/
- oprogramowanie Qemu do wirtualizacji, wersja 2.4.0 lub nowsze, http://wiki.qemu.org/Main_Page
- system operacyjny dowolny, posiadający wymagane oprogramowanie w swoich repozytoriach.

#Kompilacja (z poziomu konsoli):

    GNU/Linux:
    polecenie "make"

    MS/Windows:
    polecenie "make.bat"

#Uwagi:
Emulatory pod systemem z rodziny MS/Windows nie obsługują prawidłowo klawiszy strzałek/kursorów. Nie mam pojęcia kogo to wina - emulatora czy systemu.

#Uruchomienie:
2 MiB pamięci RAM z czego pierwszy jest przeznaczony dla BIOSu.

    qemu-system-x86_64 -hda build/disk.raw -m 2




Udało ci się nanieść poprawkę, ulepszenie lub coś zupełnie nowego w źródle systemu?
Dopisz się do grupy programistów Wataha.net!

- Andrzej Adamczyk, akasei

Kod źródlowy systemu operacyjnego jest na licencji Creative Commons BY-NC-ND

![alt tag](http://mirrors.creativecommons.org/presskit/buttons/80x15/png/by-nc-nd.png)
