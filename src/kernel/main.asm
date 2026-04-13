org 0x7c00
bits 16

main:
  ; Set up registers
  mov ax, 0
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7c00

  mov si, os_boot_msg
  call print

  ; Halt
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

os_boot_msg db "OS has booted!", 0x0d, 0x0a, 0

times 510 - ($ - $$) db 0
dw 0aa55h