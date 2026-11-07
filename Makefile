NASM ?= nasm

all: game.img

boot.bin: boot.asm
	$(NASM) -f bin $< -o $@

stage2.bin: stage2.asm
	$(NASM) -f bin $< -o $@

main.bin: main.asm selector.asm vga.asm keyboard.asm timer.asm font.asm tetris.asm snake.asm ttt.asm
	$(NASM) -f bin main.asm -o main.bin

game.img: boot.bin stage2.bin main.bin image.asm
	$(NASM) -f bin image.asm -o game.img

clean:
ifeq ($(OS),Windows_NT)
	-del /Q boot.bin stage2.bin main.bin game.img 2>NUL
else
	rm -f boot.bin stage2.bin main.bin game.img
endif

.PHONY: all clean
