#!/usr/bin/env sh

mkdir -p out

nasm -f elf64 ./nap.asm -o ./out/nap-x86-64.o
ld -m elf_x86_64 \
   -z noseparate-code \
   -z noexecstack \
   --strip-all \
   -o ./out/nap-x86-64 \
   ./out/nap-x86-64.o

aarch64-linux-gnu-as nap-aarch64.s -o ./out/nap-aarch64.o
aarch64-linux-gnu-ld \
   --strip-all \
   -z max-page-size=0x04 \
   -o ./out/nap-aarch64 \
   ./out/nap-aarch64.o

ls -lth ./out
