#!/bin/bash
#
# build-kernel.sh — DEPRECATED
# =============================
# ChaldOS now uses the Arch Linux kernel (linux package) via mkarchiso.
# No manual kernel compilation needed.
#
# The installed system gets the linux kernel via pacstrap.
# Custom kernels can be installed via pacman post-install.
#
# See: ./build.sh iso  (uses archiso / mkarchiso)
#

echo "╔═══════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║   ⚠️  build-kernel.sh — больше не нужен          ║"
echo "║                                                   ║"
echo "║   ChaldOS теперь базируется на Arch Linux.        ║"
echo "║   Ядро Linux ставится через pacman (linux пакет). ║"
echo "║                                                   ║"
echo "║   Для сборки ISO используй:                       ║"
echo "║     ./build.sh iso                                ║"
echo "║                                                   ║"
echo "║   Для кастомного ядра:                            ║"
║   pacman -S linux-zen linux-lts                    ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

exit 0
