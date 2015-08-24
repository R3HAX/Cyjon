# test script

ASM=nasm -f bin
SOFTWARE=software

all:
$(ASM) $(SOFTWARE)/init.asm -o init.bin
