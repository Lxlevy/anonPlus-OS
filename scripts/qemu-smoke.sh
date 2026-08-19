#!/usr/bin/env bash
set -euo pipefail

KERNEL_IMAGE="${KERNEL_IMAGE:-build/kernel/arch/x86/boot/bzImage}"
ROOTFS_IMAGE="${ROOTFS_IMAGE:-build/immutable-root/rootfs.img}"
QEMU_LOG="${QEMU_LOG:-build/qemu-smoke.log}"

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
  echo "Missing qemu-system-x86_64. Run make setup first." >&2
  exit 1
}
[[ -f "$KERNEL_IMAGE" ]] || { echo "Missing kernel image: $KERNEL_IMAGE" >&2; exit 1; }
[[ -f "$ROOTFS_IMAGE" ]] || { echo "Missing root image: $ROOTFS_IMAGE" >&2; exit 1; }

mkdir -p "$(dirname "$QEMU_LOG")"
if ! timeout "${QEMU_TIMEOUT:-30}" qemu-system-x86_64 \
  -machine q35,accel=tcg \
  -m 512M \
  -nographic \
  -no-reboot \
  -serial mon:stdio \
  -kernel "$KERNEL_IMAGE" \
  -drive "file=$ROOTFS_IMAGE,format=raw,if=virtio,readonly=on" \
  -append 'console=ttyS0 panic=-1 ro' >"$QEMU_LOG" 2>&1; then
  echo "QEMU smoke test failed or timed out. See $QEMU_LOG." >&2
  exit 1
fi

grep -q 'anonplus-boot-ok' "$QEMU_LOG" || {
  echo "QEMU boot completed without the anonPlus health marker." >&2
  exit 1
}

echo "QEMU smoke test passed: $QEMU_LOG"
