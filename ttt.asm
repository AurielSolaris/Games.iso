run_ttt:
    mov edi, ttt_board
    xor eax, eax
    mov ecx, 9
    rep stosb
    mov dword [ttt_cursor], 0
    mov byte [ttt_result], 0
    call timer_init
    call fps_init
ttt_draw:
    xor eax, eax
    call clear_screen
    mov esi, ttt_title
    mov eax, 80
    mov ebx, 12
    mov ebp, 15
    call text
    xor edi, edi
.cells:
    mov eax, edi
    xor edx, edx
    mov ecx, 3
    div ecx
    imul ebx, eax, 42
    add ebx, 38
    imul eax, edx, 42
    add eax, 98
    mov ecx, 38
    mov edx, 38
    mov ebp, 8
    cmp edi, [ttt_cursor]
    jne .box
    mov ebp, 14
.box:
    call rect
    add eax, 15
    add ebx, 15
    mov esi, ttt_blank
    cmp byte [ttt_board+edi], 1
    jne .o
    mov esi, ttt_x
.o: cmp byte [ttt_board+edi], 2
    jne .label
    mov esi, ttt_o
.label:
    mov ebp, 0
    call text
    inc edi
    cmp edi, 9
    jb .cells
    mov esi, ttt_help
    mov eax, 48
    mov ebx, 180
    mov ebp, 7
    call text
    call fps_frame
    cmp byte [ttt_result], 0
    je .input
    mov esi, ttt_draw_msg
    cmp byte [ttt_result], 1
    jne .check_o
    mov esi, ttt_win_msg
.check_o:
    cmp byte [ttt_result], 2
    jne .result
    mov esi, ttt_lose_msg
.result:
    mov eax, 105
    mov ebx, 168
    mov ebp, 15
    call text
.input:
    call fps_poll
    call poll_key
    cmp al, KEY_ESC
    je selector_screen
    cmp byte [ttt_result], 0
    jne .input
    mov edi, [ttt_cursor]
    cmp al, KEY_LEFT
    je .left
    cmp al, KEY_RIGHT
    je .right
    cmp al, KEY_UP
    je .up
    cmp al, KEY_DOWN
    je .down
    cmp al, KEY_ENTER
    jne .input
    cmp byte [ttt_board+edi], 0
    jne .input
    mov byte [ttt_board+edi], 1
    call ttt_winner
    test eax, eax
    jnz .finish
    call ttt_cpu
    call ttt_winner
.finish:
    mov [ttt_result], al
    jmp ttt_draw
.left:
    mov eax, edi
    xor edx, edx
    mov ecx, 3
    div ecx
    test edx, edx
    jz .input
    dec edi
    jmp .move
.right:
    mov eax, edi
    xor edx, edx
    mov ecx, 3
    div ecx
    cmp edx, 2
    je .input
    inc edi
    jmp .move
.up: cmp edi, 3
    jb .input
    sub edi, 3
    jmp .move
.down: cmp edi, 6
    jae .input
    add edi, 3
.move: mov [ttt_cursor], edi
    jmp ttt_draw

; Return 0 ongoing, 1 X, 2 O, 3 draw. Preserve all other registers.
ttt_winner:
    push ebx
    push ecx
    push edx
    push esi
    mov esi, ttt_lines
    mov ecx, 8
.line:
    movzx eax, byte [esi]
    movzx ebx, byte [esi+1]
    movzx edx, byte [esi+2]
    mov al, [ttt_board+eax]
    test al, al
    jz .next
    cmp al, [ttt_board+ebx]
    jne .next
    cmp al, [ttt_board+edx]
    je .found
.next: add esi, 3
    loop .line
    xor esi, esi
.empty:
    cmp byte [ttt_board+esi], 0
    je .ongoing
    inc esi
    cmp esi, 9
    jb .empty
    mov eax, 3
    jmp .out
.ongoing: xor eax, eax
    jmp .out
.found: movzx eax, al
.out: pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; alpha-beta(player, alpha, beta). Full-depth minimax, scores -1/0/+1.
ttt_ab:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    call ttt_winner
    cmp eax, 1
    je .xwin
    cmp eax, 2
    je .owin
    cmp eax, 3
    je .draw
    mov ebx, -2
    cmp dword [ebp+8], 2
    je .start
    mov ebx, 2
.start:
    xor esi, esi
.loop:
    cmp byte [ttt_board+esi], 0
    jne .next
    mov eax, [ebp+8]
    mov [ttt_board+esi], al
    xor eax, 3
    push dword [ebp+16]
    push dword [ebp+12]
    push eax
    call ttt_ab
    add esp, 12
    mov byte [ttt_board+esi], 0
    cmp dword [ebp+8], 2
    jne .min
    cmp eax, ebx
    jle .max_bound
    mov ebx, eax
.max_bound:
    cmp ebx, [ebp+12]
    jle .prune
    mov [ebp+12], ebx
    jmp .prune
.min:
    cmp eax, ebx
    jge .min_bound
    mov ebx, eax
.min_bound:
    cmp ebx, [ebp+16]
    jge .prune
    mov [ebp+16], ebx
.prune:
    mov eax, [ebp+12]
    cmp eax, [ebp+16]
    jge .finish
.next:
    inc esi
    cmp esi, 9
    jb .loop
.finish: mov eax, ebx
    jmp .out
.xwin: mov eax, -1
    jmp .out
.owin: mov eax, 1
    jmp .out
.draw: xor eax, eax
.out: pop edi
    pop esi
    pop ebx
    pop ebp
    ret
ttt_cpu:
    mov dword [ttt_best], -2
    xor esi, esi
.loop:
    cmp byte [ttt_board+esi], 0
    jne .next
    mov byte [ttt_board+esi], 2
    push dword 2
    push dword -2
    push dword 1
    call ttt_ab
    add esp, 12
    mov byte [ttt_board+esi], 0
    cmp eax, [ttt_best]
    jle .next
    mov [ttt_best], eax
    mov [ttt_best_cell], esi
.next: inc esi
    cmp esi, 9
    jb .loop
    mov esi, [ttt_best_cell]
    mov byte [ttt_board+esi], 2
    ret
ttt_board times 9 db 0
ttt_cursor dd 0
ttt_result db 0
ttt_best dd 0
ttt_best_cell dd 0
ttt_lines db 0,1,2,3,4,5,6,7,8,0,3,6,1,4,7,2,5,8,0,4,8,2,4,6
ttt_title db 'TIC TAC TOE',0
ttt_help db 'ARROWS ENTER  ESC BACK',0
ttt_blank db ' ',0
ttt_x db 'X',0
ttt_o db 'O',0
ttt_draw_msg db 'DRAW',0
ttt_win_msg db 'YOU WIN',0
ttt_lose_msg db 'CPU WINS',0
