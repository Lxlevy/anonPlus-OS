#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root (for example: sudo ./scripts/network-down.sh)." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkill -KILL -f "$ROOT_DIR/config/tor/torrc" 2>/dev/null || true

if [[ -f /run/anonplus-tor.pid ]]; then
  kill -KILL "$(cat /run/anonplus-tor.pid)" 2>/dev/null || true
fi

for namespace in anonplus-app anonplus-tor; do
  for pid in $(ip netns pids "$namespace" 2>/dev/null || true); do
    kill -KILL "$pid" 2>/dev/null || true
  done
  ip netns del "$namespace" 2>/dev/null || true
done

ip link del ap-host 2>/dev/null || true
ip link del ap-app-veth 2>/dev/null || true
rm -f /run/anonplus-tor.pid
rm -rf /etc/netns/anonplus-app
nft delete table inet anonplus_host 2>/dev/null || true
nft delete table ip anonplus_nat 2>/dev/null || true

echo "anonPlus network is down"
