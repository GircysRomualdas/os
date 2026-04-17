SRC_DIR    = src
BUILD_DIR  = build

IMG        = $(BUILD_DIR)/os.img
BOOT_BIN   = $(BUILD_DIR)/bootloader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin

ASM = nasm
CFLAGS16 = -s -wx -ms -zl -zq
ASM_FLAGS = -f obj

# TEMP workaround (installer segfault). Real path is: CC16 = /usr/bin/watcom/binl/wcc
CC16 = /home/romas/Downloads/ow-snapshot/binl/wcc
# TEMP workaround (installer segfault). Real path is: LD16 = /usr/bin/watcom/binl/wlink
LD16 = /home/romas/Downloads/ow-snapshot/binl/wlink

# Target
all: clean always image bootloader kernel

# OS image
image: $(IMG)

$(IMG): bootloader kernel
	dd if=/dev/zero of=$(IMG) bs=512 count=2880
	mkfs.fat -F 12 -n "OS" $(IMG)
	dd if=$(BOOT_BIN) of=$(IMG) conv=notrunc
	mcopy -i $(IMG) $(KERNEL_BIN) "::kernel.bin"

# Bootloader
bootloader: $(BOOT_BIN)
$(BOOT_BIN): 
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BOOT_BIN)

# Kernel
kernel: $(KERNEL_BIN)
$(KERNEL_BIN):
	$(ASM) $(ASM_FLAGS) -o $(BUILD_DIR)/kernel/asm/main.obj $(SRC_DIR)/kernel/main.asm
	$(ASM) $(ASM_FLAGS) -o $(BUILD_DIR)/kernel/asm/print.obj $(SRC_DIR)/kernel/stdio/print.asm
	$(ASM) $(ASM_FLAGS) -o $(BUILD_DIR)/kernel/asm/disk.obj $(SRC_DIR)/kernel/disk/asmDisk.asm
	$(CC16) $(CFLAGS16) -fo=$(BUILD_DIR)/kernel/c/main.obj $(SRC_DIR)/kernel/main.c
	$(CC16) $(CFLAGS16) -fo=$(BUILD_DIR)/kernel/c/stdio.obj $(SRC_DIR)/kernel/stdio/stdio.c
	$(LD16) NAME $(BUILD_DIR)/kernel.bin FILE \{$(BUILD_DIR)/kernel/asm/main.obj $(BUILD_DIR)/kernel/asm/print.obj $(BUILD_DIR)/kernel/c/main.obj $(BUILD_DIR)/kernel/c/stdio.obj $(BUILD_DIR)/kernel/asm/disk.obj \} OPTION MAP=${BUILD_DIR}/kernel.map @${SRC_DIR}/kernel/linker.lnk

always:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/kernel
	mkdir -p $(BUILD_DIR)/kernel/asm
	mkdir -p $(BUILD_DIR)/kernel/c


clean:
	rm -rf $(BUILD_DIR)