#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-${KERNEL_CONFIG:-build/kernel/.config}}"
REQUIRED_CONFIG=(
  CONFIG_STACKPROTECTOR_STRONG=y
  CONFIG_STRICT_KERNEL_RWX=y
  CONFIG_STRICT_MODULE_RWX=y
  CONFIG_RANDOMIZE_BASE=y
  CONFIG_SECURITY_LOCKDOWN_LSM=y
  CONFIG_SECCOMP_FILTER=y
  CONFIG_MODULE_SIG_FORCE=y
  CONFIG_SLAB_FREELIST_HARDENED=y
)

[[ -f "$CONFIG_PATH" ]] || { echo "Missing kernel config: $CONFIG_PATH" >&2; exit 1; }

for expected in "${REQUIRED_CONFIG[@]}"; do
  grep -qx "$expected" "$CONFIG_PATH" || {
    echo "Missing hardened kernel setting: $expected" >&2
    exit 1
  }
done

echo "Kernel hardening checks passed: $CONFIG_PATH"
