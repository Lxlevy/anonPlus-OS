#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  clang \
  llvm \
  lld \
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
  pkg-config

echo "Fortress OS development environment ready."
echo "Use ./scripts/build-kernel.sh to begin a kernel build."
