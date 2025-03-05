#!/bin/bash
set -e
set -x

# yum install 
sudo yum makecache
sudo dnf install -y gcc make ncurses-devel bison flex elfutils-libelf-devel openssl-devel bc git curl cpio xz bzip2 pcre-devel dwarves kmod alsa-lib-devel fuse-devel libmnl-devel qemu-system-riscv
