FROM --platform=linux/amd64 alpine:3.16

RUN apk --update add nasm binutils gcc-aarch64-none-elf
