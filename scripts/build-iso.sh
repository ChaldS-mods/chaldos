#!/bin/bash
#
# build-iso.sh — DEPRECATED
# ==========================
# ChaldOS now uses mkarchiso (archiso package) to build ISOs.
# This script is kept for backward compatibility.
#
# See: ./build.sh iso  (uses archiso / mkarchiso)
#

echo "╔═══════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║   ⚠️  build-iso.sh — переписано                  ║"
echo "║                                                   ║"
echo "║   ChaldOS теперь использует mkarchiso.            ║"
echo "║                                                   ║"
echo "║   Для сборки ISO:                                 ║"
echo "║     ./build.sh iso                                ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# Delegate to new build.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
exec "$PROJECT_DIR/build.sh" iso
