org 0x7c00
bits 16

jmp short main
nop

; FAT header
bdb_oem:                    db 'MSWIN4.1'           
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 
bdb_media_descriptor_type:  db 0F0h                 
bdb_sectors_per_fat:        dw 9                    
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

ebr_drive_number:           db 0                    
                            db 0                    
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   
ebr_volume_label:           db '  JAZZ OS  '        
ebr_system_id:              db 'FAT12   '  

main:  
  mov ax, 0
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7c00


  mov si, os_boot_msg
  call print

  mov ax, [bdb_sectors_per_fat]
  mov bl, [bdb_fat_count]
  xor bh, bh
  mul bx
  add ax, [bdb_reserved_sectors]
  push ax

  mov ax, [bdb_dir_entries_count]
  shl ax, 5
  xor dx, dx
  div word [bdb_bytes_per_sector]

  test dx, dx
  jz root_dir_after
  inc ax

  root_dir_after:
    mov cl, al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    xor bx, bx
    mov di, buffer
  
  search_kernel:
    mov si, file_kernel_bin
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je found_kernel

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl search_kernel

    jmp kernel_not_found
  
  kernel_not_found:
    mov si, msg_kernel_not_found
    call print

    hlt
    jmp halt
  
  found_kernel:
    mov ax, [di + 26]
    mov [kernel_cluster], ax
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    mov bx, kernel_load_segment
    mov es, bx
    mov bx, kernel_load_offset
  
    load_kernel_loop:
      mov ax, [kernel_cluster]
      add ax, 31
      mov cl, 1
      mov dl, [ebr_drive_number]
      call disk_read

      add bx, [bdb_bytes_per_sector]
      mov ax, [kernel_cluster]
      mov cx, 3
      mul cx
      mov cx, 2
      div cx

      mov si, buffer
      add si, ax
      mov ax, [ds:si]

      or dx, dx
      jz even

      odd:
        shr ax, 4
        jmp next_cluster_after
      even:
        and ax, 0x0fff
      
      next_cluster_after:
        cmp ax, 0x0ff8
        jae read_finish

        mov [kernel_cluster], ax
        jmp load_kernel_loop
      
      read_finish:
        mov dl, [ebr_drive_number]
        mov ax, kernel_load_segment
        mov ds, ax
        mov es, ax
        jmp kernel_load_segment:kernel_load_offset
        hlt

  halt:
    jmp halt



lba_to_chs:
  push ax
  push dx

  xor dx, dx
  div word [bdb_sectors_per_track]
  inc dx
  mov cx, dx 

  xor dx, dx
  div word [bdb_heads]
  mov dh, dl 
  mov ch, al
  shl ah, 6 
  or cl, ah 

  pop ax
  mov dl, al
  pop ax
  ret


disk_read:
  push ax
  push bx
  push cx
  push dx
  push di

  call lba_to_chs

  mov ah, 02h
  mov di, 3 

  disk_read_retry:
    stc 
    int 13h
    jnc disk_read_done

    call disk_reset
    dec di
    TEST di, di
    jnz disk_read_retry
    jmp fail_disk_read

  disk_read_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_reset:
  pusha
  mov ah, 0
  stc
  int 13h
  jc fail_disk_read
  popa
  ret

fail_disk_read:
  mov si, read_fail_msg
  call print
  hlt
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

os_boot_msg: db "Loading...", 0x0d, 0x0a, 0
read_fail_msg: db "Failed to read disk!", 0x0d, 0x0a, 0
file_kernel_bin: db "KERNEL  BIN"
msg_kernel_not_found: db "KERNEL.BIN not found!"
kernel_cluster: dw 0
kernel_load_segment: equ 0x2000
kernel_load_offset: equ 0

times 510 - ($ - $$) db 0
dw 0aa55h

buffer: 