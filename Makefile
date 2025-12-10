all: mp4

gif: build run convert-gif clean

mp4: build run convert-mp4 clean

build:
	nasm -f elf64 main.s -o main.o
	ld main.o -o gen

run:
	./gen

convert-gif:
	convert -delay 8 -loop 0 output-*.ppm output.gif

convert-mp4:
	ffmpeg -i output-%02d.ppm -r 60 output.mp4

clean:
	rm -rf output-*.ppm

.PHONY: all gif mp4 build run convert-gif convert-mp4 clean
