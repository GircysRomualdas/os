ASM        = nasm
SRC_DIR    = src
BUILD_DIR  = build

IMG        = $(BUILD_DIR)/os.img
BOOT_BIN   = $(BUILD_DIR)/bootloader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin

# Target
all: image

# OS image
image: $(IMG)

$(IMG): $(BOOT_BIN) $(KERNEL_BIN) | $(BUILD_DIR)
	dd if=/dev/zero of=$(IMG) bs=512 count=2880
	mkfs.fat -F 12 -n "OS" $(IMG)
	dd if=$(BOOT_BIN) of=$(IMG) conv=notrunc
	mcopy -i $(IMG) $(KERNEL_BIN) "::kernel.bin"

# Bootloader
$(BOOT_BIN): | $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BOOT_BIN)

# Kernel
$(KERNEL_BIN): | $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(KERNEL_BIN)

# Build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)