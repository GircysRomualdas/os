#! /bin/bash
set -e

# qemu-system-i386 -boot c -m 256 -fda build/os.img
qemu-system-i386 -fda build/os.img