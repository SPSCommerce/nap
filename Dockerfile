FROM ubuntu:18.04
ARG CROSS_ARCH="aarch64"
RUN apt update -y && \
    apt install -y make qemu-user-static nasm binutils binutils-$CROSS_ARCH-linux-gnu
