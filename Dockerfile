FROM --platform=linux/amd64 ubuntu:18.04 as build_amd64
RUN apt update -y && apt install -y wget make nasm binutils binutils-aarch64-linux-gnu
RUN wget https://github.com/multiarch/qemu-user-static/releases/download/v7.1.0-2/qemu-aarch64-static \
         -O /usr/sbin/qemu-aarch64-static && \
    chmod +x /usr/sbin/qemu-aarch64-static
