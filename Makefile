program: main.o lib.o dict.o
	ld -o $@ $^

main.o: main.asm colon.inc words.inc lib.inc

dict.o: dict.asm

%.o: %.asm
	nasm -f elf64 -o $@ $<
