nasm -f bin software\init.asm -o init.bin
nasm -f bin software\login.asm -o login.bin
nasm -f bin software\shell.asm -o shell.bin
nasm -f bin software\help.asm -o help.bin
nasm -f bin software\uptime.asm -o uptime.bin
nasm -f bin software\moko.asm -o moko.bin

nasm -f bin kernel.asm -o kernel.bin

nasm -f bin bootloader\stage2.asm -o stage2.bin
nasm -f bin bootloader\stage1.asm -o build\disk.raw

pause
