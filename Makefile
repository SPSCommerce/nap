PHONY: all install

all:
	docker build -t nasm .

install:
	rm -fr out && mkdir -p out
	docker run --rm -v $(shell pwd)/out:/work -w /work nasm bash -c "cp -av /output/* ."
