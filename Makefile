# it's alive

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
	$(ASM) $(SOFTWARE)/args.asm -o args.bin
	$(ASM) $(SOFTWARE)/touch.asm -o touch.bin
	$(ASM) $(SOFTWARE)/free.asm -o free.bin

	$(ASM) kernel.asm -o kernel.bin

	$(ASM) $(BUILD)/kfs.asm -o $(BUILD)/kfs.raw
	$(ASM) $(BOOTLOADER)/stage2.asm -o stage2.bin
	$(ASM) $(BOOTLOADER)/stage1.asm -o $(BUILD)/disk.raw

clean:
	rm -f init.bin login.bin shell.bin help.bin uptime.bin moko.bin ps.bin date.bin ls.bin stage2.bin args.bin touch.bin free.bin
