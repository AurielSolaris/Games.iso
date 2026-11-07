; Poll the PIT channel 0 counter. Accumulate elapsed PIT clocks across wraps.
timer_init:
    mov al, 0x34
    out 0x43, al
    xor al, al
    out 0x40, al
    out 0x40, al
    call timer_read
    mov [timer_last], ax
    mov dword [timer_acc], 0
    ret
timer_read:
    xor al, al
    out 0x43, al
    in al, 0x40
    mov ah, al
    in al, 0x40
    xchg al, ah
    ret
; EAX = 1 once approximately 1/10 second has passed.
timer_poll:
    call timer_read
    mov dx, [timer_last]
    mov [timer_last], ax
    sub dx, ax
    movzx edx, dx
    add [timer_acc], edx
    xor eax, eax
    cmp dword [timer_acc], 119318
    jb .done
    sub dword [timer_acc], 119318
    inc eax
.done: ret
timer_last dw 0
timer_acc dd 0
random_seed dd 0x19572
random:
    imul eax, [random_seed], 1664525
    add eax, 1013904223
    mov [random_seed], eax
    ret

; Target 30 redraws/second, independently of gameplay tick frequency.
; Poll the PIT frequently enough to observe its 16-bit counter wrap.
frame_init:
    call timer_read
    mov [frame_last], ax
    mov dword [frame_elapsed], 39773 ; first frame is immediate
    ret
frame_poll:
    push edx
    call timer_read
    mov dx, [frame_last]
    mov [frame_last], ax
    sub dx, ax
    movzx edx, dx
    add [frame_elapsed], edx
    xor eax, eax
    cmp dword [frame_elapsed], 39773 ; 1193182 / 30 PIT clocks
    jb .out
    inc eax
.out:
    pop edx
    ret
frame_wait:
    call frame_poll
    test eax, eax
    jz frame_wait
    ; Do not accumulate backlog: slow frames cannot cause a burst of redraws.
    mov dword [frame_elapsed], 0
    ret
frame_last dw 0
frame_elapsed dd 0

; Count completed screen redraws per second.
fps_init:
    call timer_read
    mov [fps_last], ax
    mov dword [fps_elapsed], 0
    mov dword [fps_frames], 0
    mov dword [fps_value], 0
    ret
fps_frame:
    inc dword [fps_frames]
    jmp fps_draw
fps_poll:
    pushad
    call timer_read
    mov dx, [fps_last]
    mov [fps_last], ax
    sub dx, ax
    movzx edx, dx
    add [fps_elapsed], edx
    cmp dword [fps_elapsed], 1193182
    jb .out
    sub dword [fps_elapsed], 1193182
    mov eax, [fps_frames]
    mov [fps_value], eax
    mov dword [fps_frames], 0
    call fps_draw
.out:
    popad
    ret
fps_draw:
    pushad
    mov eax, 0
    mov ebx, 0
    mov ecx, 80
    mov edx, 10
    mov ebp, 0
    call rect
    mov eax, [fps_value]
    mov edi, fps_digits+10
    mov byte [edi], 0
    mov ecx, 10
.digit:
    xor edx, edx
    div ecx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .digit
    mov esi, fps_label
    mov eax, 0
    mov ebx, 1
    mov ebp, 15
    call text
    mov esi, edi
    mov eax, 32
    call text
    popad
    ret
fps_last dw 0
fps_elapsed dd 0
fps_frames dd 0
fps_value dd 0
fps_label db 'FPS',0
fps_digits times 11 db 0
