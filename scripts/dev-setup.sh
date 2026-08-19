#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  clang \
  curl \
  llvm \
  lld \
  iproute2 \
  qemu-system-x86 \
  qemu-utils \
  tor \
  nftables \
  debootstrap \
  xz-utils \
  cpio \
  bc \
  bison \
  flex \
  libelf-dev \
  libssl-dev \
  libdw-dev \
  dwarves \
  cryptsetup-bin \
  e2fsprogs \
  pkg-config

echo "anonPlus OS development environment ready."
echo "Use ./scripts/build-kernel.sh to begin a kernel build."
