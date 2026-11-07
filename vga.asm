; rect: EAX=x, EBX=y, ECX=width, EDX=height, EBP=colour.
rect:
    pushad
    imul edi, ebx, 320
    add edi, eax
    add edi, 0xa0000
.row:
    push ecx
    mov eax, ebp
    rep stosb
    pop ecx
    add edi, 320
    sub edi, ecx
    dec edx
    jnz .row
    popad
    ret
clear_screen:
    pushad
    mov edi, 0xa0000
    mov ecx, 64000
    rep stosb
    popad
    ret
; text: ESI=zero-terminated string, EAX=x, EBX=y, EBP=colour
text:
    pushad
.char:
    push eax
    lodsb
    test al, al
    jz .endchar
    movzx edx, al
    pop eax
    shl edx, 3
    add edx, 0x6000
    push esi
    push ebx
    mov esi, 8
.row:
    mov cl, [edx]
    push eax
    push ebx
    push edx
    mov edx, 8
.bit:
    shl cl, 1
    jnc .skip
    push ecx
    push edx
    mov ecx, 1
    mov edx, 1
    call rect
    pop edx
    pop ecx
.skip: inc eax
    dec edx
    jnz .bit
    pop edx
    pop ebx
    pop eax
    inc ebx
    inc edx
    dec esi
    jnz .row
    pop ebx
    pop esi
    add eax, 8
    jmp .char
.endchar: pop eax
    popad
    ret
