bits 16
org 0x7c00
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti
    mov [drive], dl
    mov bx, 0x7e00
    mov ax, 0x0201
    mov cx, 2
    xor dh, dh
    int 0x13
    jc fail
    mov dl, [drive]
    jmp 0:0x7e00
fail:
    mov si, message
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0e
    int 0x10
    jmp .print
.halt: cli
    hlt
    jmp .halt
drive db 0
message db 'DISK ERROR',0
times 510-($-$$) db 0
dw 0xaa55
