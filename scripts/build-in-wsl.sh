#!/bin/bash
# ChaldOS — Built inside WSL Ubuntu via Arch Linux chroot
# Run this inside WSL Ubuntu as root: sudo ./build-in-wsl.sh
set -e

ARCH_ROOT=/opt/archlinux
CHALDOS_SRC=$(dirname "$0")/..
CHALDOS_SRC=$(cd "$CHALDOS_SRC" && pwd)

echo "=== ChaldOS ISO Builder for WSL ==="
echo "Source: $CHALDOS_SRC"
echo "Chroot: $ARCH_ROOT"

# Install deps on Ubuntu
DEPS="squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin dosfstools mtools zstd wget curl"
echo "Installing dependencies: $DEPS"
apt-get update -qq
apt-get install -y -qq $DEPS 2>&1 | tail -2
echo "Dependencies installed."

# Download Arch bootstrap
BOOTSTRAP_FILE=/tmp/archlinux-bootstrap.tar.zst
if [ ! -f "$BOOTSTRAP_FILE" ]; then
    echo "Downloading Arch Linux bootstrap (this may take a while)..."
    curl -sLo "$BOOTSTRAP_FILE" "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst"
    echo "Downloaded: $(ls -lh $BOOTSTRAP_FILE | awk '{print $5}')"
fi

# Extract
mkdir -p "$ARCH_ROOT"
if [ ! -d "$ARCH_ROOT/root.x86_64/etc" ]; then
    echo "Extracting bootstrap..."
    tar --zstd -xf "$BOOTSTRAP_FILE" -C "$ARCH_ROOT"
    echo "Extracted."
fi

ROOTFS="$ARCH_ROOT/root.x86_64"

# Setup chroot environment
echo "Setting up chroot..."
mkdir -p "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev" "$ROOTFS/run"
mount --bind /proc "$ROOTFS/proc" 2>/dev/null || true
mount --bind /sys "$ROOTFS/sys" 2>/dev/null || true
mount --bind /dev "$ROOTFS/dev" 2>/dev/null || true
mount --bind /dev/pts "$ROOTFS/dev/pts" 2>/dev/null || true
mount --bind /run "$ROOTFS/run" 2>/dev/null || true

# Check resolv.conf for DNS
if [ ! -f "$ROOTFS/etc/resolv.conf" ]; then
    cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf" 2>/dev/null || echo "nameserver 8.8.8.8" > "$ROOTFS/etc/resolv.conf"
fi

# Reset pacman keyring if needed
if [ ! -f "$ROOTFS/usr/bin/pacman" ]; then
    echo "Setting up pacman..."
    # The bootstrap has a special setup script
    if [ -f "$ROOTFS/usr/bin/pacman-key" ]; then
        # Initialize pacman keyring
        chroot "$ROOTFS" /usr/bin/bash -c "pacman-key --init 2>/dev/null; pacman-key --populate archlinux 2>/dev/null" || true
    fi
fi

echo "Installing archiso in chroot..."
chroot "$ROOTFS" /usr/bin/bash -c "pacman -Syu --noconfirm archiso" 2>&1 | tail -5

echo "=== Copying ChaldOS project ==="
mkdir -p "$ROOTFS/build"
cp -a "$CHALDOS_SRC" "$ROOTFS/build/chaldos"

echo "=== Building ChaldOS ISO ==="
chroot "$ROOTFS" /usr/bin/bash -c "cd /build/chaldos && bash build.sh"

echo "=== Copying ISO out ==="
ISO_FILE=$(ls -t "$ROOTFS/build/chaldos/output/"*.iso 2>/dev/null | head -1)
if [ -n "$ISO_FILE" ]; then
    cp "$ISO_FILE" "$CHALDOS_SRC/output/"
    echo "ISO copied to: $CHALDOS_SRC/output/$(basename "$ISO_FILE")"
    ls -lh "$CHALDOS_SRC/output/"
else
    echo "Checking alternative locations..."
    find "$ROOTFS/build" -name "*.iso" 2>/dev/null
fi

echo "=== Build Complete ==="
