#! /bin/bash
set -e

make

qemu-system-i386 -fda build/main.img