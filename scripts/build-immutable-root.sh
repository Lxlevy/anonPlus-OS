#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root (for example: sudo make rootfs)." >&2
  exit 1
fi

for command in debootstrap truncate mkfs.ext4 mount umount veritysetup openssl; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Missing required command: $command. Run make setup first." >&2
    exit 1
  }
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build/immutable-root}"
STAGE_DIR="$BUILD_DIR/stage"
IMAGE="$BUILD_DIR/rootfs.img"
HASH_IMAGE="$BUILD_DIR/rootfs.verity"
METADATA="$BUILD_DIR/rootfs.verity.txt"
SIGNATURE="$BUILD_DIR/rootfs.hash.sig"
SIGNING_KEY="${SIGNING_KEY:-$ROOT_DIR/build/keys/anonplus-root-signing.pem}"
DEBIAN_RELEASE="${DEBIAN_RELEASE:-bookworm}"
DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

if [[ ! -f "$SIGNING_KEY" ]]; then
  echo "Missing SIGNING_KEY: $SIGNING_KEY" >&2
  echo "Use a development key only for local testing; production keys must be external." >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"
rm -rf "$STAGE_DIR"
debootstrap --variant=minbase --include=ca-certificates,iproute2,nftables,tor \
  "$DEBIAN_RELEASE" "$STAGE_DIR" "$DEBIAN_MIRROR"

mkdir -p "$STAGE_DIR/var" "$STAGE_DIR/home"
printf '%s\n' \
  'tmpfs /tmp tmpfs nosuid,nodev,noexec,mode=1777 0 0' \
  '/dev/mapper/anonplus-root / ext4 ro 0 1' \
  '/dev/mapper/anonplus-state /var ext4 nosuid,nodev 0 2' \
  '/dev/mapper/anonplus-home /home ext4 nosuid,nodev 0 2' \
  > "$STAGE_DIR/etc/fstab"

truncate -s "${ANONPLUS_ROOTFS_SIZE:-512M}" "$IMAGE"
mkfs.ext4 -F -L anonplus-root "$IMAGE" >/dev/null
MOUNT_DIR="$BUILD_DIR/mnt"
mkdir -p "$MOUNT_DIR"
mount -o loop "$IMAGE" "$MOUNT_DIR"
cp -a "$STAGE_DIR"/. "$MOUNT_DIR"/
sync
umount "$MOUNT_DIR"

truncate -s "${ANONPLUS_VERITY_SIZE:-64M}" "$HASH_IMAGE"
veritysetup format "$IMAGE" "$HASH_IMAGE" > "$METADATA"
awk -F': ' '/Root hash:/ {print $2}' "$METADATA" > "$BUILD_DIR/root.hash"
openssl dgst -sha256 -sign "$SIGNING_KEY" -out "$SIGNATURE" "$BUILD_DIR/root.hash"

echo "Immutable root image: $IMAGE"
echo "dm-verity hash image: $HASH_IMAGE"
echo "Signed root hash: $SIGNATURE"
