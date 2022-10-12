CROSS_ARCH=$(shell if [ $$(arch) = "x86_64" ]; then echo "aarch64"; else echo "x86-64"; fi)
X86_64_NAP=$(shell if [ $$(arch) = "x86_64" ]; then echo "./nap"; else echo "qemu-x86_64-static ./nap"; fi)
ARM_64_NAP=$(shell if [ $$(arch) = "x86_64" ]; then echo "qemu-aarch64-static ./nap-aarch64"; else echo "./nap-aarch64"; fi)

ci_build:
	rm -fr out
	mkdir out
	nasm -f elf64 nap.asm
	x86_64-linux-gnu-ld -m elf_x86_64 -z noseparate-code -z noexecstack --strip-all -o out/nap nap.o && rm nap.o
	aarch64-linux-gnu-as nap-aarch64.s -o nap-aarch64.o
	aarch64-linux-gnu-ld -z noseparate-code -z noexecstack --strip-all -o out/nap-aarch64 nap-aarch64.o && rm nap-aarch64.o
	ls -la out/

ci_tests: ci_build
	if [ $$(arch) = "x86_64" ]; then \
		echo "[x86_64] Testing 1s nap"; \
		timeout 3s $(X86_64_NAP) 1 2>&1 > /dev/null; \
		echo "[x86_64] Testing 10s default/bad input nap"; \
		timeout 12s $(X86_64_NAP) bad_arg ; if [ $$? = "1" ]; then true; else false; fi; \
	else \
		echo "x86_64 testing not available on aarch64 platform"; \
	fi
	echo "[aarch64] Testing 1s nap"
	timeout 3s $(ARM_64_NAP) 1 2>&1 > /dev/null
	echo "[aarch64] Testing 10s default/bad input nap"
	timeout 12s $(ARM_64_NAP) bad_arg ; if [ $$? = "1" ]; then true; else false; fi

tests: install
	if [ $$(arch) = "x86_64" ]; then \
		echo "[x86_64] Testing 1s nap"; \
		docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 3s $(X86_64_NAP) 1 2>&1 > /dev/null'; \
		echo "[x86_64] Testing 10s default/bad input nap"; \
		docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 12s $(X86_64_NAP) bad_arg ; if [ $$? = "1" ]; then true; else false; fi'; \
	else \
		echo "x86_64 testing not available on aarch64 platform"; \
	fi
	echo "[aarch64] Testing 1s nap"
	docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 3s $(ARM_64_NAP) 1 2>&1 > /dev/null'
	echo "[aarch64] Testing 10s default/bad input nap"
	docker run --rm -v "$(shell pwd)/out:/work" -w /work nap bash -c 'timeout 12s $(ARM_64_NAP) bad_arg ; if [ $$? = "1" ]; then true; else false; fi'

docker:
	docker build --build-arg CROSS_ARCH=$(CROSS_ARCH) -t nap .

install: docker
	docker run --rm -v "$(shell pwd):/src" -w /src nap make ci_build
