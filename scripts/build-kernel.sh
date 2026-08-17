#!/usr/bin/env bash
set -euo pipefail

KERNEL_VERSION="${KERNEL_VERSION:-6.17}"
BUILD_DIR="${BUILD_DIR:-$PWD/build/kernel}"
SRC_DIR="${SRC_DIR:-$PWD/build/src}"

mkdir -p "$BUILD_DIR" "$SRC_DIR"

cat <<'EOF'
Kernel build bootstrap

This script intentionally stops before downloading a kernel source tree.
Pin the exact upstream kernel version and source tarball in a future release
and verify its signature/hash before extracting it.

For Codespaces, keep source/toolchain versions pinned for reproducibility.
EOF

echo "Build directory: $BUILD_DIR"
echo "Source directory: $SRC_DIR"
