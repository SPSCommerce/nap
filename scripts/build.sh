#!/usr/bin/env sh

mkdir -p out

nasm -f elf64 ./nap.asm -o ./out/nap-x86-64.o

ld -m elf_x86_64 \
   -z noseparate-code \
   -z noexecstack \
   --strip-all \
   -o ./out/nap-x86-64 \
   ./out/nap-x86-64.o


aarch64-none-elf-as nap-arm-v8.s -o ./out/nap-arm-v8.o

aarch64-none-elf-ld -m aarch64elf \
   --strip-all \
   -z max-page-size=0x04 \
   -o ./out/nap-arm-v8 \
   ./out/nap-arm-v8.o

ls -lth ./out

