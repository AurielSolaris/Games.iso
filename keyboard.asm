%define KEY_UP 0x48
%define KEY_DOWN 0x50
%define KEY_LEFT 0x4b
%define KEY_RIGHT 0x4d
%define KEY_ENTER 0x1c
%define KEY_ESC 1
%define KEY_SPACE 0x39
%define KEY_Z 0x2c
%define KEY_X 0x2d
%define KEY_F 0x21
%define KEY_Q 0x10
%define KEY_R 0x13
%define KEY_S 0x1f
poll_key:
    push ebx
    push edx
    in al, 0x64
    test al, 1
    jz .none
    mov dl, al
    in al, 0x60
    ; Do not interpret mouse bytes or controller parity/timeout errors as keys.
    test dl, 0xe0
    jnz .bad_byte
    cmp byte [key_pause_left], 0
    je .prefix
    dec byte [key_pause_left]
    jmp .none
.prefix:
    cmp al, 0xe0
    je .extended
    cmp al, 0xe1
    je .pause
    movzx ebx, al
    and ebx, 0x7f
    cmp byte [key_extended], 0
    je .index_ready
    add ebx, 128
.index_ready:
    mov byte [key_extended], 0
    test al, 0x80
    jnz .release
    cmp byte [key_down+ebx], 0
    je .press
    ; Arrow keys may repeat for navigation and continuous Tetris movement.
    and ebx, 0x7f
    cmp bl, KEY_UP
    je .repeat
    cmp bl, KEY_DOWN
    je .repeat
    cmp bl, KEY_LEFT
    je .repeat
    cmp bl, KEY_RIGHT
    jne .none
.repeat:
    mov eax, ebx
    jmp .out
.press:
    mov byte [key_down+ebx], 1
    and eax, 0x7f
    jmp .out
.release:
    mov byte [key_down+ebx], 0
    jmp .none
.extended:
    mov byte [key_extended], 1
    jmp .none
.pause:
    mov byte [key_extended], 0
    mov byte [key_pause_left], 5
    jmp .none
.bad_byte:
    ; An auxiliary byte can occur between keyboard prefix bytes.
    test dl, 0xc0
    jz .none
    mov byte [key_extended], 0
    mov byte [key_pause_left], 0
.none: xor eax, eax
.out:
    pop edx
    pop ebx
    ret
key_extended db 0
key_pause_left db 0
key_down times 256 db 0
