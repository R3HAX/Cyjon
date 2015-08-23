# Cyjon OS
Prosty system operacyjny dla procesorów z rodziny x86-64.

![alt tag](http://wiki.osdev.org/images/a/a7/Wataha.png)

Wymagania sprzętowe:
- procesor z rodziny x86-64,
- 1 MiB pamięci RAM pod adresem fizycznym 0x0000000000100000,
- obsługa SuperVGA w trybie 800x600 o głębi kolorów 24 lub 32 bity.

Oprogramowanie:
- kompilator Nasm wersja 2.11.08 lub nowsza, http://www.nasm.us/
- oprogramowanie Qemu do wirtualizacji, wersja 2.4.0 lub nowsze, http://wiki.qemu.org/Main_Page
- system operacyjny dowolny, posiadający wymagane oprogramowanie w swoich repozytoriach.

Kompilacja (z poziomu konsoli), przykład dla systemów GNU/Linux:

    nasm -f bin software/init.asm -o init.bin
    nasm -f bin software/login.asm -o login.bin
    nasm -f bin software/shell.asm -o shell.bin
    nasm -f bin software/help.asm -o help.bin
    nasm -f bin software/uptime.asm -o uptime.bin
    nasm -f bin kernel.asm -o kernel.bin
    nasm -f bin bootloader/stage2.asm -o stage2.bin
    nasm -f bin bootloader/stage1.asm -o build/disk.raw

Uruchomienie:

    qemu-system-x86_64 -hda build/disk.raw

Udało ci się nanieść poprawkę, ulepszenie lub coś zupełnie nowego w źródle systemu?
Dopisz się do grupy programistów Wataha.net!

- Andrzej Adamczyk, akasei

Kod źródlowy systemu operacyjnego jest na licencji Creative Commons BY-NC-ND

![alt tag](http://mirrors.creativecommons.org/presskit/buttons/80x15/png/by-nc-nd.png)
