#!/bin/bash
# ChaldOS — Prepare airootfs overlay for archiso build
# Copies installer scripts and system files into the airootfs directory.
#
# Usage: ./prepare-airootfs.sh
#   Run BEFORE mkarchiso. Copies:
#     - installer/*.sh → airootfs/root/chaldos/
#     - rootfs/usr/bin/* → airootfs/usr/local/bin/
#     - config/chaldos.conf → airootfs/etc/chaldos/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHLIVE_DIR="$SCRIPT_DIR"
AIROOTFS="$ARCHLIVE_DIR/airootfs"

CHALDOS_VERSION="2.0.0"

echo "╔═══════════════════════════════════════════╗"
echo "║  ChaldOS — Preparing airootfs overlay    ║"
echo "╚═══════════════════════════════════════════╝"

# ─── 1. Installer scripts ───────────────────────
echo "  [1/5] Copying installer scripts..."
mkdir -p "$AIROOTFS/root/chaldos"
for script in install-chaldos.sh post-install.sh davinci-resolve.sh mascot.sh; do
    if [[ -f "$PROJECT_DIR/installer/$script" ]]; then
        cp -v "$PROJECT_DIR/installer/$script" "$AIROOTFS/root/chaldos/$script"
        chmod 755 "$AIROOTFS/root/chaldos/$script"
    else
        echo "  ⚠️  Warning: installer/$script not found, skipping"
    fi
done
# Install libs file if it exists
for script in install-libs.sh; do
    if [[ -f "$PROJECT_DIR/installer/$script" ]]; then
        cp -v "$PROJECT_DIR/installer/$script" "$AIROOTFS/root/chaldos/$script"
        chmod 755 "$AIROOTFS/root/chaldos/$script"
    fi
done

# Create convenient symlink for easy invocation
ln -sf /root/chaldos/install-chaldos.sh "$AIROOTFS/usr/local/bin/chaldos-install" 2>/dev/null || true

# ─── 2. System mascot & branding ────────────────
echo "  [2/5] Copying branding and system tools..."
mkdir -p "$AIROOTFS/usr/local/bin"
mkdir -p "$AIROOTFS/usr/share/chaldos"

# Copy mascot command
if [[ -f "$PROJECT_DIR/rootfs/usr/bin/chaldos-mascot" ]]; then
    cp -v "$PROJECT_DIR/rootfs/usr/bin/chaldos-mascot" "$AIROOTFS/usr/local/bin/chaldos-mascot"
    chmod 755 "$AIROOTFS/usr/local/bin/chaldos-mascot"
fi

# Create banner
cat > "$AIROOTFS/usr/share/chaldos/banner.txt" << 'BANNER'
    ╔═══════════════════════════════════════╗
    ║                                       ║
    ║     ╱◉‿◉╲    C H A L D O S           ║
    ║     │  ❤  │   Gaming Edition v2.0    ║
    ║     │ ╱─╲ │   Arch Linux Powered     ║
    ║     ╰─────╯   Pixel Perfect           ║
    ║                                       ║
    ╚═══════════════════════════════════════╝
BANNER

# ─── 3. Configuration ───────────────────────────
echo "  [3/5] Copying configuration..."
mkdir -p "$AIROOTFS/etc/chaldos"
if [[ -f "$PROJECT_DIR/config/chaldos.conf" ]]; then
    cp -v "$PROJECT_DIR/config/chaldos.conf" "$AIROOTFS/etc/chaldos/chaldos.conf"
fi

# Create a welcome script that auto-runs on login
cat > "$AIROOTFS/root/.auto-welcome.sh" << 'WELCOME'
#!/bin/bash
# ChaldOS — auto-welcome message on live session
echo ""
echo "    ╔═══════════════════════════════════════╗"
echo "    ║                                       ║"
echo "    ║   ╱◉‿◉╲  ДОБРО ПОЖАЛОВАТЬ!          ║"
echo "    ║   │  ❤  │                             ║"
echo "    ║   │ ╱─╲ │  ChaldOS LIVE              ║"
echo "    ║   ╰─────╯                             ║"
echo "    ║                                       ║"
echo "    ║  Введи: chaldos-install              ║"
echo "    ║         или ./chaldos/install-chaldos.sh ║"
echo "    ║         для установки на диск!       ║"
echo "    ╚═══════════════════════════════════════╝"
echo ""
WELCOME
chmod 755 "$AIROOTFS/root/.auto-welcome.sh"

# ─── 4. GRUB theme placeholder ──────────────────
echo "  [4/5] Preparing GRUB theme..."
# The theme directory already exists; we could add a PNG logo here

# ─── 5. Verify ──────────────────────────────────
echo "  [5/5] Verifying airootfs..."
echo ""
echo "  Contents of /root/chaldos/:"
ls -la "$AIROOTFS/root/chaldos/" 2>/dev/null || echo "  (empty)"
echo ""
echo "✓ airootfs prepared successfully!"
echo ""
