.PHONY: build_ci debug_ci build test docker

build_ci:
	nasm -f elf64 nap.asm && ld -m elf_x86_64 --strip-all -o nap nap.o

debug_ci:
	nasm -f elf64 -F dwarf -g nap.asm && ld -m elf_x86_64 -o nap nap.o

build: docker
	docker run --rm -v "$(shell pwd)":/work -w /work nasm ./scripts/build.sh

test: docker
	docker run --rm -v "$(shell pwd)":/work -w /work nasm ./scripts/test.sh

docker:
	docker build -t nasm .

