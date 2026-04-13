asm = nasm

src_dir = src
build_dir = build

$(build_dir):
	mkdir -p $(build_dir)

$(build_dir)/main.img: $(build_dir)/main.bin
	cp $(build_dir)/main.bin $(build_dir)/main.img
	truncate -s 1440k $(build_dir)/main.img

$(build_dir)/main.bin: $(src_dir)/main.asm
	$(asm) $(src_dir)/main.asm -f bin -o $(build_dir)/main.bin