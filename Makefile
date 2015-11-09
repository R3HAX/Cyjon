# test script

ASM=nasm -f bin
SOFTWARE=software
BOOTLOADER=bootloader
BUILD=build

all:
	$(ASM) $(SOFTWARE)/init.asm -o init.bin
	$(ASM) $(SOFTWARE)/login.asm -o login.bin
	$(ASM) $(SOFTWARE)/shell.asm -o shell.bin
	$(ASM) $(SOFTWARE)/help.asm -o help.bin
	$(ASM) $(SOFTWARE)/uptime.asm -o uptime.bin
	$(ASM) $(SOFTWARE)/moko.asm -o moko.bin
	$(ASM) $(SOFTWARE)/ps.asm -o ps.bin
	$(ASM) $(SOFTWARE)/date.asm -o date.bin
	$(ASM) $(SOFTWARE)/ls.asm -o ls.bin

	$(ASM) kernel.asm -o kernel.bin

	$(ASM) $(BUILD)/kfs.asm -o $(BUILD)/kfs.raw
	$(ASM) $(BOOTLOADER)/stage2.asm -o stage2.bin
	$(ASM) $(BOOTLOADER)/stage1.asm -o $(BUILD)/disk.raw

clean:
	rm -f stage2.bin init.bin shell.bin help.bin login.bin uptime.bin moko.bin kernel.bin ps.bin date.bin ls.bin
