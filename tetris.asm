run_tetris:
    mov edi, t_board
    mov ecx, 200
    xor eax, eax
    rep stosb
    mov dword [t_lines], 0
    mov byte [t_ticks], 0
    mov byte [t_dead], 0
    call t_spawn
    call timer_init
    call fps_init
    call frame_init
t_draw:
    call frame_wait
    xor eax, eax
    call clear_screen
    mov esi, t_title
    mov eax, 8
    mov ebx, 20
    mov ebp, 15
    call text
    mov esi, t_lines_label
    mov eax, 224
    mov ebx, 28
    call text
    mov eax, [t_lines]
    call t_number
    mov esi, t_help
    mov eax, 8
    mov ebx, 184
    mov ebp, 7
    call text
    mov eax, 108
    mov ebx, 8
    mov ecx, 104
    mov edx, 164
    mov ebp, 8
    call rect
    xor edi, edi
.board:
    movzx ebp, byte [t_board+edi]
    test ebp, ebp
    jz .next
    mov eax, edi
    xor edx, edx
    mov ecx, 10
    div ecx
    mov ebx, eax
    mov eax, edx
    call t_cell
.next: inc edi
    cmp edi, 200
    jb .board
    mov byte [t_action], 2
    call t_piece_cells
    call fps_frame
    cmp byte [t_dead], 0
    je .input
    mov esi, t_over
    mov eax, 112
    mov ebx, 90
    mov ebp, 15
    call text
.input:
    call fps_poll
    call frame_poll
    test eax, eax
    jnz t_draw
    cmp byte [t_dead], 0
    jne .read_key
    call timer_poll
    test eax, eax
    jz .read_key
    inc byte [t_ticks]
    cmp byte [t_ticks], 5
    jb .read_key
    mov byte [t_ticks], 0
    call t_step
    jmp t_draw
.read_key:
    call poll_key
    cmp al, KEY_ESC
    je selector_screen
    cmp al, KEY_R
    je run_tetris
    cmp byte [t_dead], 0
    jne .input
    cmp al, KEY_LEFT
    jne .right
    dec dword [t_x]
    call t_valid
    test eax, eax
    jnz t_draw
    inc dword [t_x]
    jmp .input
.right: cmp al, KEY_RIGHT
    jne .rotate
    inc dword [t_x]
    call t_valid
    test eax, eax
    jnz t_draw
    dec dword [t_x]
    jmp .input
.rotate: cmp al, KEY_UP
    je .rot
    cmp al, KEY_Q
    je .rot
    cmp al, KEY_X
    je .rot
    cmp al, KEY_Z
    jne .flip
.rot: inc dword [t_rot]
    and dword [t_rot], 3
    call t_valid
    test eax, eax
    jnz t_draw
    add dword [t_rot], 3
    and dword [t_rot], 3
    jmp .input
.flip:
    cmp al, KEY_F
    jne .down
    xor byte [t_flipped], 1
    call t_valid
    test eax, eax
    jnz t_draw
    xor byte [t_flipped], 1
    jmp .input
.down: cmp al, KEY_DOWN
    jne .drop
    call t_step
    jmp t_draw
.drop: cmp al, KEY_SPACE
    jne .clock
.drop_loop:
    inc dword [t_y]
    call t_valid
    test eax, eax
    jnz .drop_loop
    dec dword [t_y]
    call t_step
    jmp t_draw
.clock:
    jmp .input
t_cell:
    pushad
    imul eax, 10
    add eax, 110
    imul ebx, 8
    add ebx, 10
    mov ecx, 9
    mov edx, 7
    call rect
    popad
    ret
; Display the line count as decimal.
t_number:
    pushad
    mov edi, t_digits+10
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
    mov esi, edi
    mov eax, 224
    mov ebx, 40
    mov ebp, 15
    call text
    popad
    ret
t_spawn:
    call random
    xor edx, edx
    mov ecx, 7
    div ecx
    mov [t_type], edx
    mov dword [t_rot], 0
    mov byte [t_flipped], 0
    mov dword [t_x], 3
    mov dword [t_y], 0
    call t_valid
    test eax, eax
    jnz .done
    mov byte [t_dead], 1
.done: ret
t_step:
    inc dword [t_y]
    call t_valid
    test eax, eax
    jnz .done
    dec dword [t_y]
    mov byte [t_action], 1
    call t_piece_cells
    call t_clear_lines
    call t_spawn
.done: ret
t_valid:
    mov byte [t_action], 0
    call t_piece_cells
    ret
; Iterate the 4x4 mask. Action: validate, lock, or render.
t_piece_cells:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov eax, [t_type]
    shl eax, 4
    mov ecx, [t_rot]
    shl ecx, 2
    add eax, ecx
    lea esi, [t_shapes+eax]
    xor edi, edi
.row:
    xor ecx, ecx
.col:
    movzx edx, byte [esi+edi]
    mov eax, ecx
    cmp byte [t_flipped], 0
    je .test_bit
    xor eax, 3
.test_bit:
    bt edx, eax
    jnc .next
    mov eax, [t_x]
    add eax, ecx
    mov ebx, [t_y]
    add ebx, edi
    cmp eax, 10
    jae .invalid
    cmp ebx, 20
    jae .invalid
    imul edx, ebx, 10
    add edx, eax
    cmp byte [t_action], 0
    jne .write
    cmp byte [t_board+edx], 0
    jne .invalid
    jmp .next
.write:
    mov ebp, [t_type]
    add ebp, 9
    cmp byte [t_action], 1
    jne .render
    push eax
    mov eax, ebp
    mov [t_board+edx], al
    pop eax
    jmp .next
.render:
    call t_cell
.next:
    inc ecx
    cmp ecx, 4
    jb .col
    inc edi
    cmp edi, 4
    jb .row
    mov eax, 1
    jmp .out
.invalid: xor eax, eax
.out: pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
t_clear_lines:
    mov ebx, 19
.row:
    imul esi, ebx, 10
    xor ecx, ecx
.check:
    cmp byte [t_board+esi+ecx], 0
    je .next
    inc ecx
    cmp ecx, 10
    jb .check
    inc dword [t_lines]
    imul ecx, ebx, 10
    test ecx, ecx
    jz .zero
    lea esi, [t_board+ecx-1]
    lea edi, [esi+10]
    std
    rep movsb
    cld
.zero:
    mov edi, t_board
    xor eax, eax
    mov ecx, 10
    rep stosb
    jmp .row
.next:
    dec ebx
    jns .row
    ret
t_board times 200 db 0
t_type dd 0
t_rot dd 0
t_x dd 0
t_y dd 0
t_lines dd 0
t_ticks db 0
t_dead db 0
t_action db 0
t_flipped db 0
t_digits times 11 db 0
; Each byte is a row, least significant bit is the leftmost cell.
t_shapes:
 db 0,15,0,0, 2,2,2,2, 0,15,0,0, 2,2,2,2
 db 6,6,0,0, 6,6,0,0, 6,6,0,0, 6,6,0,0
 db 2,7,0,0, 2,6,2,0, 0,7,2,0, 2,3,2,0
 db 6,3,0,0, 1,3,2,0, 6,3,0,0, 1,3,2,0
 db 3,6,0,0, 2,3,1,0, 3,6,0,0, 2,3,1,0
 db 1,7,0,0, 6,2,2,0, 0,7,4,0, 2,2,3,0
 db 4,7,0,0, 2,2,6,0, 0,7,1,0, 3,2,2,0
t_title db 'TETRIS',0
t_help db 'Q ROTATE F FLIP SPACE DROP R RESTART',0
t_lines_label db 'LINES',0
t_over db 'GAME OVER',0
