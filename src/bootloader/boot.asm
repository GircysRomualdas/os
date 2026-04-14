org 0x7c00
bits 16

jmp short main
nop

; FAT header
bdb_oem:                 DB 'MSWIN4.1'
bdb_bytes_per_sector:    DW 512
bdb_sectors_per_cluster: DB 1
bdb_reserved_sectors:    DW 1
bdb_fat_count:           DB 2
bdb_dir_entries_count:   DW 0e0h
bdb_total_sectors:       DW 2880
bdb_media_descriptor_type: DB 0f0h
bdb_sectors_per_fat:     DW 9
bdb_sectors_per_track:   DW 18
bdb_heads:               DW 2
bdb_hidden_sectors:      DD 0
bdb_large_sector_count:  DD 0
ebr_drive_number: DB 0
                  DB 0
ebr_signature:    DB 29h
ebr_volume_id:    DB 12h,34h,56h,78h
ebr_volume_label: DB 'OS         '
ebr_system_id:    DB 'FAT12    '

main:
  ; Set up registers
  mov ax, 0
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7c00

  ; Read from disk
  mov [ebr_drive_number], dl
  mov ax, 1
  mov cl, 1
  mov bx, 0x7e00
  call disk_read

  ; Print boot message
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

; fix later maby ?
lba_to_chs:
  push ax
  push dx

  xor dx, dx
  div word [bdb_sectors_per_track]
  inc dx
  mov cx, dx ; sector

  xor dx, dx
  div word [bdb_heads]
  mov dh, dl ; head
  mov ch, al
  shl ah, 6 
  or cl, ah ; cylinder

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
  mov di, 3 ; counter

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


os_boot_msg: db "OS has booted!", 0x0d, 0x0a, 0
read_fail_msg: db "Failed to read disk!", 0x0d, 0x0a, 0

times 510 - ($ - $$) db 0
dw 0aa55h