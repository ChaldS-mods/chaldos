#!/usr/bin/env bash
# vim: set sw=4 et sts=4 tw=80:
# ChaldOS — archiso profile definition

profile_name="chaldos"
profile_description="ChaldOS Gaming Edition v2.0 — Arch Linux based gaming distribution"

install_dir="chaldos"
arch="x86_64"

# Remove/comment out pacman_conf if you want to use the host's
# pacman.conf. Otherwise leave as-is to use our bundled one.
# pacman_conf="pacman.conf"

files=(
    "airootfs.sfs"
)

image_compression=("zstd" "-Xcompression-level" "19")

# Build modes: "bios" and/or "uefi-*.img" or "uefi-x64.eltorito"
# For a hybrid USB/optical-disk image:
buildmodes=("bios" "uefi-ia32.systemd-boot.eltorito" "uefi-x64.systemd-boot.eltorito")

# For pure USB (no optical) use:
# buildmodes=("bios" "uefi-ia32.systemd-boot.gpt" "uefi-x64.systemd-boot.gpt")

mksignature="true"
