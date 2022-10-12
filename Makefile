ci_build:
	rm -fr out
	mkdir out
	nasm -f elf64 nap.asm && ld -m elf_x86_64 -z noseparate-code -z noexecstack --strip-all -o out/nap nap.o && rm nap.o
	aarch64-linux-gnu-as nap-aarch64.s -o nap-aarch64.o && aarch64-linux-gnu-ld -z noseparate-code -z noexecstack --strip-all -o out/nap-aarch64 nap-aarch64.o && rm nap-aarch64.o
	ls -la out/

ci_tests: ci_build
	echo "[x86_64] Testing 1s nap"
	timeout 3s out/nap 1 2>&1 > /dev/null
	echo "[x86_64] Testing 10s default/bad input nap"
	timeout 12s out/nap bad_arg ; if [ $$? = "1" ]; then true; else false; fi
	echo "[aarch64] Testing 1s nap"
	timeout 3s qemu-aarch64-static out/nap-aarch64 1 2>&1 > /dev/null
	echo "[aarch64] Testing 10s default/bad input nap"
	timeout 12s qemu-aarch64-static out/nap-aarch64 bad_arg ; if [ $$? = "1" ]; then true; else false; fi

tests: install
	echo "[x86_64] Testing 1s nap"
	docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 3s ./nap 1 2>&1 > /dev/null'
	echo "[x86_64] Testing 10s default/bad input nap"
	docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 12s ./nap bad_arg ; if [ $$? = "1" ]; then true; else false; fi'
	echo "[aarch64] Testing 1s nap"
	docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 3s qemu-aarch64-static nap-aarch64 1 2>&1 > /dev/null'
	echo "[aarch64] Testing 10s default/bad input nap"
	docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 12s qemu-aarch64-static nap-aarch64 bad_arg ; if [ $$? = "1" ]; then true; else false; fi'

docker:
	docker build -t nap .

install: docker
	docker run --rm -v "$(shell pwd):/src" -w /src nap make ci_build
