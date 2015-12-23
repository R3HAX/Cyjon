nasm -f bin software\init.asm -o init.bin
nasm -f bin software\login.asm -o login.bin
nasm -f bin software\shell.asm -o shell.bin
nasm -f bin software\help.asm -o help.bin
nasm -f bin software\uptime.asm -o uptime.bin
nasm -f bin software\moko.asm -o moko.bin
nasm -f bin software\ps.asm -o ps.bin
nasm -f bin software\date.asm -o date.bin
nasm -f bin software\ls.asm -o ls.bin
nasm -f bin software\args.asm -o args.bin
nasm -f bin software\touch.asm -o touch.bin
nasm -f bin software\free.asm -o free.bin

nasm -f bin kernel.asm -o kernel.bin

nasm -f bin bootloader\stage2.asm -o stage2.bin
nasm -f bin bootloader\stage1.asm -o build\disk.raw

del /F /Q init.bin login.bin shell.bin help.bin uptime.bin moko.bin ps.bin date.bin ls.bin stage2.bin args.bin touch.bin free.bin

pause
