#! /bin/bash
set -e

qemu-system-i386 -boot c -m 256 -hda build/os.img