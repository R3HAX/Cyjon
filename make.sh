#!/bin/bash

nasm -f bin kernel.asm -o kernel.bin
nasm -f bin bootloader/stage2.asm -o stage2.bin
nasm -f bin bootloader/stage1.asm -o build/disk.raw

rm -f kernel.bin stage2.bin

# poniższe operacje tylko dla oprogramowania VirtualBOX,
# jeżeli wykorzystujesz
rm -f build/disk.vdi
vboxmanage convertfromraw --format vdi build/disk.raw build/disk.vdi
# VirtualBOX jest niezadowolony z zmiennego UUID dysku, więc ustalamy jakiś stały
vboxmanage internalcommands sethduuid build/disk.vdi "1583de73-0b3e-462d-aaaf-c88b793aa6a4"
# udostępnij dla każdego lub jak wolisz
chmod 777 build/disk.vdi
