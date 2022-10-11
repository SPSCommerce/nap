ci_build:
	rm -fr out
	mkdir out
	nasm -f elf64 nap.asm && ld -m elf_x86_64 -z noseparate-code -z noexecstack --strip-all -o out/nap nap.o && rm nap.o
	aarch64-linux-gnu-as nap-aarch64.s -o nap-aarch64.o && aarch64-linux-gnu-ld -z noseparate-code -z noexecstack --strip-all -o out/nap-aarch64 nap-aarch64.o && rm nap-aarch64.o
	ls -la out/

docker:
	docker build -t nasm .

install: docker
	rm -fr out && mkdir -p out
	docker run --rm -v $(shell pwd)/out:/work -w /work nasm bash -c "cp -av /output/* ."
