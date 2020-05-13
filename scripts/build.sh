#!/usr/bin/env sh

mkdir -p out

nasm -f elf64 ./nap.asm -o ./out/nap-x86-64.o

ld -arch elf64-x86-64 \
   -z noseparate-code \
   -z noexecstack \
   --strip-all \
   -o ./out/nap-x86-64 \
   ./out/nap-x86-64.o

ls -lth ./out

