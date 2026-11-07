bits 16
org 0x7e00
    mov [drive], dl
    ; Read the main image one sector at a time, respecting floppy tracks.
    mov ax, 0x0800
    mov es, ax
    mov byte [sector], 3
    mov byte [head], 0
    mov byte [cylinder], 0
    mov byte [remaining], 64
.read:
    xor bx, bx
    mov ah, 2
    mov al, 1
    mov ch, [cylinder]
    mov cl, [sector]
    mov dh, [head]
    mov dl, [drive]
    int 0x13
    jc .error
    mov ax, es
    add ax, 0x20
    mov es, ax
    inc byte [sector]
    cmp byte [sector], 19
    jb .next
    mov byte [sector], 1
    xor byte [head], 1
    jnz .next
    inc byte [cylinder]
.next:
    dec byte [remaining]
    jnz .read
    ; Copy the BIOS 8x8 font before leaving real mode.
    mov ax, 0x1130
    mov bh, 3
    int 0x10
    push ds
    push es
    pop ds
    mov si, bp
    xor ax, ax
    mov es, ax
    mov di, 0x6000
    mov cx, 2048
    cld
    rep movsb
    pop ds
    mov ax, 0x0013
    int 0x10
    cli
    in al, 0x92
    or al, 2
    and al, 0xfe
    out 0x92, al
    lgdt [gdtr]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 8:pm
.error:
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
sector db 0
head db 0
cylinder db 0
remaining db 0
message db 'LOAD ERROR',0
align 8
gdt: dq 0
    dq 0x00cf9a000000ffff
    dq 0x00cf92000000ffff
gdt_end:
gdtr: dw gdt_end-gdt-1
    dd gdt
bits 32
pm:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000
    cld
    jmp 0x8000
times 512-($-$$) db 0
