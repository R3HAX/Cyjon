# Cyjon
Prosty system operacyjny dla procesorów z rodziny x86-64.

Wymagania sprzętowe:
- procesor z rodziny x86-64,
- 1 MiB pamięci RAM pod adresem fizycznym 0x0000000000100000,
- obsługa SuperVGA w trybie 800x600 o głębi kolorów 24 lub 32 bity.

Oprogramowanie:
- kompilator Nasm wersja 2.11.08 lub nowsza, http://www.nasm.us/
- system operacyjny posiadający w swoich repozytoriach kompilator Nasm.

Kompilacja (z poziomu konsoli), przykład dla systemów GNU/Linux:
nasm -f bin software/init.asm -o init.bin
nasm -f bin software/shell.asm -o shell.bin
nasm -f bin kernel.asm -o kernel.bin
nasm -f bin bootloader/stage2.asm -o stage2.bin
nasm -f bin bootloader/stage1.asm -o build/disk.raw

![alt tag](http://mirrors.creativecommons.org/presskit/buttons/80x15/png/by-nc-nd.png)

Udało ci się nanieść poprawkę, ulepszenie lub coś zupełnie nowego w źródle systemu?
Dopisz się do grupy programistów Wataha.net!

- Andrzej Adamczyk, akasei
