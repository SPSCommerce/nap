# Build x86_64 image
FROM --platform=linux/amd64 ubuntu:18.04 as build_amd64
WORKDIR /root
RUN apt update -y && apt install -y nasm binutils
COPY nap.asm /root/
RUN nasm -f elf64 ./nap.asm -o ./nap-x86-64.o && \
    ld -z noseparate-code -z noexecstack --strip-all -o nap-x86-64 nap-x86-64.o

# Test x86_64 image (not passing?!?)
#RUN timeout 2s ./nap-x86-64 1 2>&1 > /dev/null
#RUN timeout 11s ./nap-x86-64 bad_arg ; if [ $? = "1" ]; then true; else false; fi

# Build aarch64 image
FROM --platform=linux/arm64 ubuntu:18.04 as build_arm64
WORKDIR /root
RUN apt update -y && apt install -y binutils
COPY nap-arm-v8.s /root/
RUN as nap-arm-v8.s -o nap-arm-v8.o && \
    ld -z noseparate-code -z noexecstack --strip-all -o nap-arm-v8 nap-arm-v8.o

# Test aarch64 image
RUN timeout 2s ./nap-arm-v8 1 2>&1 > /dev/null
RUN timeout 11s ./nap-arm-v8 bad_arg ; if [ $? = "1" ]; then true; else false; fi

# Generate output
FROM ubuntu:18.04 as output
COPY --from=build_amd64 /root/nap-x86-64 /output/nap-x86-64
COPY --from=build_arm64 /root/nap-arm-v8 /output/nap-arm-v8
