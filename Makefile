# ChaldOS Build System
# ======================
# Targets:
#   all        - Build full ChaldOS ISO (using mkarchiso)
#   iso        - Same as all
#   install    - Run the interactive installer
#   clean      - Clean build artifacts
#   distclean  - Full clean
#   help       - Show this help

.PHONY: all iso install clean distclean help

TOPDIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

# Default target
all: iso

# Build ChaldOS ISO using mkarchiso
iso:
	@echo "==> Building ChaldOS ISO (archiso)..."
	@$(TOPDIR)/build.sh iso

# Run the interactive installer (from Arch Live CD)
install:
	@echo "==> Running ChaldOS Installer..."
	@$(TOPDIR)/installer/install-chaldos.sh

# Clean build artifacts
clean:
	@echo "==> Cleaning build artifacts..."
	@$(TOPDIR)/build.sh clean
	@echo "    Done."

# Full clean
distclean:
	@echo "==> Full clean..."
	@$(TOPDIR)/build.sh distclean
	@echo "    Done."

help:
	@echo "ChaldOS Build System — Gaming Edition v2.0"
	@echo "=========================================="
	@echo "  make all        - Build full ChaldOS ISO (archiso)"
	@echo "  make iso        - Same as all"
	@echo "  make install    - Run interactive installer"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make distclean  - Full clean"
	@echo "  make help       - Show this help"
	@echo ""
	@echo "ChaldOS базируется на Arch Linux."
	@echo "ISO строится через mkarchiso (archiso пакет)."
	@echo ""
	@echo "Запись на USB:"
	@echo "  sudo dd if=output/chaldos-YYYYMMDD-x86_64.iso of=/dev/sdX bs=4M status=progress"
	@echo ""
	@echo "Установка с Live CD:"
	@echo "  sudo ./installer/install-chaldos.sh"
