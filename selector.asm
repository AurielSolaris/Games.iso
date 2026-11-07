selector_screen:
    mov esp, 0x90000
    xor eax, eax
    call clear_screen
    mov esi, title
    mov eax, 72
    mov ebx, 24
    mov ebp, 15
    call text
    mov esi, instructions
    mov eax, 24
    mov ebx, 174
    mov ebp, 7
    call text
    mov esi, shutdown_help
    mov eax, 72
    mov ebx, 186
    call text
    xor edi, edi
.draw:
    mov esi, [options+edi*4]
    mov eax, 112
    imul ebx, edi, 25
    add ebx, 65
    mov ebp, 7
    ; compare the full cursor index without relying on 64-bit registers
    cmp edi, [selection]
    jne .normal
    mov ebp, 14
.normal:
    call text
    inc edi
    cmp edi, 3
    jb .draw
.input:
    call poll_key
    cmp al, KEY_S
    je .shutdown
    cmp al, KEY_UP
    je .up
    cmp al, KEY_DOWN
    je .down
    cmp al, KEY_ENTER
    jne .input
    call timer_read
    movzx eax, ax
    xor [random_seed], eax
    cmp dword [selection], 0
    je run_tetris
    cmp dword [selection], 1
    je run_snake
    jmp run_ttt
.up:
    cmp dword [selection], 0
    je .input
    dec dword [selection]
    jmp selector_screen
.down:
    cmp dword [selection], 2
    je .input
    inc dword [selection]
    jmp selector_screen
.shutdown:
    ; QEMU's PIIX4 ACPI PM1 control port. On unsupported hardware, halt.
    xor eax, eax
    call clear_screen
    mov esi, shutdown_message
    mov eax, 24
    mov ebx, 90
    mov ebp, 15
    call text
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    cli
.halt:
    hlt
    jmp .halt
selection dd 0
title db 'GAME CARTRIDGE',0
instructions db 'ARROWS + ENTER  /  ESC BACK',0
shutdown_help db 'S SHUTDOWN (QEMU)',0
shutdown_message db 'SHUTDOWN REQUESTED - SAFE TO POWER OFF',0
options dd opt1,opt2,opt3
opt1 db 'TETRIS',0
opt2 db 'SNAKE',0
opt3 db 'TIC TAC TOE',0
