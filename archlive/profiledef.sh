#!/usr/bin/env bash
# vim: set sw=4 et sts=4 tw=80:
# ChaldOS — archiso profile definition

profile_name="chaldos"
profile_description="ChaldOS Gaming Edition v2.0 — Arch Linux based gaming distribution"

install_dir="chaldos"
arch="x86_64"

# Use bundled pacman.conf with multilib enabled
pacman_conf="pacman.conf"

files=(
    "airootfs.sfs"
)

image_compression=("zstd" "-Xcompression-level" "19")

# Build modes: BIOS + UEFI x64 (hybrid ISO for USB + optical)
buildmodes=("bios" "uefi-x64.systemd-boot.eltorito")

# The GPT variant is for USB-only. We use eltorito for hybrid support.
# buildmodes=("bios" "uefi-x64.systemd-boot.gpt")

mksignature="false"
