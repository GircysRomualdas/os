org 0x0
bits 16

main:
  mov si, os_boot_msg
  call print

  hlt
  halt:
    jmp halt
  
print:
  push si
  push ax
  push bx

  print_loop:
    lodsb
    or al, al
    jz print_done

    mov ah, 0x0e
    mov bh, 0
    int 0x10

    jmp print_loop
  
  print_done:
    pop bx
    pop ax
    pop si
    ret

os_boot_msg: db "OS has booted!", 0x0d, 0x0a, 0