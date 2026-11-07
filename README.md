# Game.iso

Three games in a BIOS-bootable x86 cartridge, written in NASM assembly. The output is a **raw floppy image** named `game.img`; despite the project name, it is not a CD-ROM ISO. No operating system, GRUB, C runtime, or BIOS calls in protected mode are used.

The project was sparked by a challenge about writing assembly with an LLM: “aight bet.”

![The post that inspired Game.iso](assets/origin.png)

## Screenshots

The selector and games, captured from QEMU:

![Game selector](assets/selector.png)

![Tetris](assets/tetris.png)

![Snake](assets/snake.png)

![Tic-Tac-Toe](assets/tic-tac-toe.png)

## Build

Install NASM 2.15 or newer and GNU Make. QEMU is needed to run the image in an emulator. On Debian or Ubuntu:

```sh
sudo apt install nasm make qemu-system-x86
```

From the project directory, build with:

```sh
make
```

On Windows, put NASM and GNU Make on PATH; GNU Make may be named `gmake` or `mingw32-make`:

```powershell
gmake
```

The build uses only NASM and Make: `image.asm` combines the binaries and pads the image to 1.44 MB. To rebuild from scratch, run `make clean` followed by `make` (or use the same Make executable name you used to build). The build checks the boot and loader sizes and rejects a main binary larger than the loader can read.

## Run

```sh
qemu-system-i386 -drive format=raw,file=game.img,if=floppy -boot a
```

For the Windows installation used during development:

```powershell
& 'C:\Program Files\qemu\qemu-system-i386.exe' -drive format=raw,file=game.img,if=floppy -boot a
```

Use the keyboard to control everything; no mouse is needed. If QEMU captures input, its default release shortcut is Ctrl+Alt+G.

## Controls

| Screen | Controls |
| --- | --- |
| Selector | Up/down to choose, Enter to start |
| Tetris | Left/right to move, up/X/Z to rotate, down to move down, Space to drop |
| Snake | Arrow keys to steer |
| Tic-Tac-Toe | Arrows to move the cursor, Enter to place X |

Escape returns from any game to the selector, including after game over. Tic-Tac-Toe's O uses full-depth minimax with alpha-beta pruning. Tetris displays cleared lines. Snake ends when it hits a wall or itself. Each game's FPS counter reports complete screen redraws per second; idle turn-based screens can therefore show zero.

## Boot and hardware

The BIOS loads a 512-byte boot sector at `0x7c00`. It loads the 512-byte second stage at `0x7e00`; that stage reads up to 64 sectors of game code into `0x8000`, one sector at a time across floppy tracks. It copies the BIOS 8×8 font, sets VGA mode 13h, enables A20, loads a flat GDT, and enters 32-bit protected mode. The games use the linear VGA framebuffer, poll the PS/2 controller and PIT, and run with interrupts disabled. The stack starts at `0x90000`.

The image targets a legacy BIOS with a VGA adapter, PS/2 keyboard interface, and standard 1.44 MB floppy geometry. It has been smoke-tested in QEMU; real hardware and UEFI-only machines have not been verified. Raw USB boot behavior depends on the BIOS and its disk geometry, so a floppy image should not be assumed to boot as a USB hard disk.

## License

The project is released under the [Unlicense](LICENSE).
