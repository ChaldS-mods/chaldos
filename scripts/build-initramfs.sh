#!/bin/bash
#
# build-initramfs.sh — DEPRECATED
# ================================
# ChaldOS now uses mkinitcpio (Arch's initramfs generator).
# No manual cpio archive creation needed.
#
# The live ISO gets its initramfs from mkinitcpio via archiso.
# The installed system generates initramfs via mkinitcpio on
# kernel updates automatically.
#
# See: ./build.sh iso  (uses archiso / mkarchiso)
#

echo "╔═══════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║   ⚠️  build-initramfs.sh — больше не нужен       ║"
echo "║                                                   ║"
echo "║   ChaldOS теперь использует mkinitcpio.           ║"
echo "║   Initramfs генерируется автоматически.           ║"
echo "║                                                   ║"
echo "║   Для сборки ISO используй:                       ║"
echo "║     ./build.sh iso                                ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

exit 0
