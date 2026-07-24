section .data
    msg db 'Assembly Operations', 0xA
    len equ $ - msg

section .bss
    result resb 4

section .text
    global _start
    global add_numbers
    global subtract_numbers
    global multiply_numbers

add_numbers:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    add eax, [ebp+12]
    pop ebp
    ret

subtract_numbers:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    sub eax, [ebp+12]
    pop ebp
    ret

multiply_numbers:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    imul eax, [ebp+12]
    pop ebp
    ret

divide_numbers:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    xor edx, edx
    div dword [ebp+12]
    pop ebp
    ret

_start:
    mov eax, 1
    xor ebx, ebx
    int 0x80
