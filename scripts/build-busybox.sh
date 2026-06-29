#!/bin/bash
#
# build-busybox.sh — DEPRECATED
# ==============================
# ChaldOS now uses Arch Linux's coreutils and BusyBox package.
# No manual BusyBox compilation needed.
#
# The live ISO uses Arch's base system which includes BusyBox
# via the busybox package if desired.
#
# See: ./build.sh iso  (uses archiso / mkarchiso)
#

echo "╔═══════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║   ⚠️  build-busybox.sh — больше не нужен         ║"
echo "║                                                   ║"
echo "║   ChaldOS теперь базируется на Arch Linux.        ║"
echo "║   Утилиты GNU/coreutils ставятся через pacman.    ║"
echo "║                                                   ║"
echo "║   Для сборки ISO используй:                       ║"
echo "║     ./build.sh iso                                ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

exit 0
