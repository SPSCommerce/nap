.PHONY: build_ci debug_ci build test docker

build_ci:
	nasm -f elf64 nap.asm && ld -m elf_x86_64 --strip-all -o nap nap.o
	aarch64-none-elf-as nap-arm-v8.s -o nap-arm-v8.o
	aarch64-none-elf-ld -m aarch64elf -o nap-arm-v8 nap-arm-v8.o

debug_ci:
	nasm -f elf64 -F dwarf -g nap.asm && ld -m elf_x86_64 -o nap nap.o
	aarch64-none-elf-as nap-arm-v8.s --gdwarf-2 -o nap-arm-v8.o
	aarch64-none-elf-ld -m aarch64elf -o nap-arm-v8 nap-arm-v8.o

build: docker
	docker run --rm -v "$(shell pwd)":/work -w /work nasm ./scripts/build.sh

test: docker
	docker run --rm -v "$(shell pwd)":/work -w /work nasm ./scripts/test.sh

docker:
	docker build -t nasm .

