run_snake:
    mov word [snake_body], 0x0a0a
    mov word [snake_body+2], 0x090a
    mov word [snake_body+4], 0x080a
    mov dword [snake_len], 3
    mov dword [snake_dir], 1
    mov dword [snake_pending], 1
    mov byte [snake_turn_queued], 0
    mov byte [snake_dead], 0
    call snake_food
    call timer_init
    call fps_init
    call frame_init
snake_draw:
    call frame_wait
    xor eax, eax
    call clear_screen
    mov esi, snake_title
    mov eax, 8
    mov ebx, 20
    mov ebp, 15
    call text
    mov esi, snake_help
    mov eax, 8
    mov ebx, 184
    mov ebp, 7
    call text
    mov eax, 68
    mov ebx, 10
    mov ecx, 184
    mov edx, 164
    mov ebp, 8
    call rect
    mov eax, 70
    mov ebx, 12
    mov ecx, 180
    mov edx, 160
    mov ebp, 0
    call rect
    movzx eax, word [snake_food_pos]
    mov ebp, 12
    call snake_cell
    xor edi, edi
.body:
    movzx eax, word [snake_body+edi*2]
    mov ebp, 10
    call snake_cell
    inc edi
    cmp edi, [snake_len]
    jb .body
    call fps_frame
    cmp byte [snake_dead], 0
    je .input
    mov esi, snake_over
    mov eax, 112
    mov ebx, 90
    mov ebp, 15
    call text
.input:
    call fps_poll
    call frame_poll
    test eax, eax
    jnz snake_draw
    call poll_key
    cmp al, KEY_ESC
    je selector_screen
    cmp byte [snake_dead], 0
    jne .input
    mov edx, -1
    cmp al, KEY_UP
    jne .right
    mov edx, 0
.right: cmp al, KEY_RIGHT
    jne .down
    mov edx, 1
.down: cmp al, KEY_DOWN
    jne .left
    mov edx, 2
.left: cmp al, KEY_LEFT
    jne .direction
    mov edx, 3
.direction:
    cmp edx, -1
    je .clock
    cmp byte [snake_turn_queued], 0
    jne .clock
    cmp edx, [snake_dir]
    je .clock
    mov eax, [snake_dir]
    xor eax, 2
    cmp eax, edx
    je .clock
    mov [snake_pending], edx
    mov byte [snake_turn_queued], 1
.clock:
    call timer_poll
    test eax, eax
    jz .input
    call snake_step
    jmp snake_draw
; packed AH=x, AL=y
snake_cell:
    pushad
    movzx ebx, al
    imul ebx, 8
    add ebx, 12
    movzx eax, ah
    imul eax, 9
    add eax, 70
    mov ecx, 8
    mov edx, 7
    call rect
    popad
    ret
snake_step:
    mov byte [snake_turn_queued], 0
    mov eax, [snake_pending]
    mov [snake_dir], eax
    mov dx, [snake_body]
    cmp eax, 0
    jne .r
    dec dl
    jmp .check
.r: cmp eax, 1
    jne .d
    inc dh
    jmp .check
.d: cmp eax, 2
    jne .l
    inc dl
    jmp .check
.l: dec dh
.check:
    cmp dh, 20
    jae .dead
    cmp dl, 20
    jae .dead
    xor ecx, ecx
    mov ebx, [snake_len]
    cmp dx, [snake_food_pos]
    je .scan
    dec ebx ; moving into the departing tail is legal
.scan:
    cmp ecx, ebx
    jae .advance
    cmp dx, [snake_body+ecx*2]
    je .dead
    inc ecx
    jmp .scan
.advance:
    cmp dx, [snake_food_pos]
    jne .shift
    inc dword [snake_len]
.shift:
    mov ecx, [snake_len]
    dec ecx
.shift_loop:
    mov ax, [snake_body+ecx*2-2]
    mov [snake_body+ecx*2], ax
    dec ecx
    jnz .shift_loop
    mov [snake_body], dx
    cmp dx, [snake_food_pos]
    jne .done
    cmp dword [snake_len], 400
    je .dead
    call snake_food
.done: ret
.dead: mov byte [snake_dead], 1
    ret
snake_food:
.retry:
    call random
    xor edx, edx
    mov ecx, 400
    div ecx
    mov eax, edx
    xor edx, edx
    mov ecx, 20
    div ecx
    shl eax, 8
    or eax, edx
    xor ecx, ecx
.scan:
    cmp ax, [snake_body+ecx*2]
    je .retry
    inc ecx
    cmp ecx, [snake_len]
    jb .scan
    mov [snake_food_pos], ax
    ret
snake_body times 400 dw 0
snake_len dd 0
snake_dir dd 0
snake_pending dd 0
snake_food_pos dw 0
snake_dead db 0
snake_turn_queued db 0
snake_title db 'SNAKE',0
snake_help db 'ARROWS MOVE    ESC BACK',0
snake_over db 'GAME OVER',0
