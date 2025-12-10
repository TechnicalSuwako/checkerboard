all: build run

build:
	nasm -f elf64 main.s -o main.o
	ld main.o -o gen

run:
	./gen

.PHONY: all build run
