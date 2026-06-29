#!/usr/bin/env bash
#
# ChaldOS Build Script
# =====================
# Build a bootable ChaldOS ISO using archiso (mkarchiso).
#
# Usage:
#   ./build.sh                    — Build ISO
#   ./build.sh iso                — Same as above
#   ./build.sh all                — Same as above
#   ./build.sh clean              — Clean build artifacts
#   ./build.sh distclean          — Full clean
#   ./build.sh help               — Show help
#
# Prerequisites:
#   pacman -S archiso
#
# The archiso profile lives in ./archlive/ and includes:
#   - Custom airootfs overlay with installer scripts
#   - ChaldOS branding (MOTD, os-release, banner)
#   - GRUB + systemd-boot boot configs
#   - Gaming-oriented package selection
#

set -euo pipefail

CHALDOS_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$CHALDOS_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${PURPLE}═══ $1 ═══${NC}\n"; }

# Defaults
BUILD_DIR="${BUILD_DIR:-${CHALDOS_ROOT}/output}"
ARCHLIVE_DIR="${CHALDOS_ROOT}/archlive"
ISO_OUTPUT="${BUILD_DIR}/chaldos-$(date +%Y%m%d)-x86_64.iso"

# ─── Source config ───────────────────────────────────
source_config() {
    local conf="${CHALDOS_ROOT}/config/chaldos.conf"
    if [[ -f "$conf" ]]; then
        CHALDOS_VERSION=$(grep -oP '^CHALDOS_VERSION\s*[:]?=\s*\K.*' "$conf" | tr -d ' "')
        CHALDOS_CODENAME=$(grep -oP '^CHALDOS_CODENAME\s*[:]?=\s*\K.*' "$conf" | tr -d '"')
    fi
    : "${CHALDOS_VERSION:=2.0.0}"
    : "${CHALDOS_CODENAME:=Gaming Edition}"
    export CHALDOS_VERSION CHALDOS_CODENAME
}

# ─── Check build environment ────────────────────────
check_environment() {
    header "Checking Build Environment"

    # Required tools
    local required=(
        "mkarchiso:archiso"
        "mksquashfs:squashfs-tools"
        "xorriso:libisoburn"
        "grub-mkrescue:grub"
        "dosfstools:dosfstools"
    )

    local all_ok=true
    for entry in "${required[@]}"; do
        local cmd="${entry%%:*}"
        local pkg="${entry##*:}"
        if command -v "$cmd" &>/dev/null; then
            log "Found: $cmd"
        else
            warn "Missing: $cmd (install: pacman -S $pkg)"
            all_ok=false
        fi
    done

    # Check archiso profile exists
    if [[ ! -d "$ARCHLIVE_DIR" ]]; then
        error "archiso profile not found at $ARCHLIVE_DIR"
    fi

    # Check if profiledef.sh exists
    if [[ ! -f "$ARCHLIVE_DIR/profiledef.sh" ]]; then
        error "profiledef.sh not found in $ARCHLIVE_DIR"
    fi

    if [[ $EUID -eq 0 ]]; then
        warn "Running as root — mkarchiso needs root for some operations"
    fi

    # Architecture
    local host_arch
    host_arch=$(uname -m)
    log "Host architecture: $host_arch"
    if [[ "$host_arch" != "x86_64" ]]; then
        error "ChaldOS ISO build requires x86_64 host"
    fi

    # Memory
    if [[ -f /proc/meminfo ]]; then
        local mem_total
        mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        log "Memory: $(( mem_total / 1024 )) MB"
        if [[ $(( mem_total / 1024 )) -lt 2048 ]]; then
            warn "Less than 2 GB RAM — build may be slow"
        fi
    fi

    if ! $all_ok; then
        error "Missing required tools. Install: pacman -S archiso"
    fi

    log "Build environment OK"
}

# ─── Prepare airootfs ───────────────────────────────
prepare_rootfs() {
    header "Preparing airootfs overlay"

    if [[ -f "$ARCHLIVE_DIR/prepare-airootfs.sh" ]]; then
        log "Running prepare-airootfs.sh..."
        (cd "$ARCHLIVE_DIR" && bash prepare-airootfs.sh)
        log "airootfs prepared"
    else
        warn "prepare-airootfs.sh not found, skipping"
    fi
}

# ─── Build ISO ──────────────────────────────────────
build_iso() {
    header "Building ChaldOS ISO with mkarchiso"

    mkdir -p "$BUILD_DIR"

    # Show what we're building
    echo "  ChaldOS v${CHALDOS_VERSION} ${CHALDOS_CODENAME}"
    echo "  Arch:        x86_64"
    echo "  Output:      ${ISO_OUTPUT}"
    echo "  Profile:     ${ARCHLIVE_DIR}"
    echo ""

    # Run mkarchiso
    # mkarchiso outputs the ISO to the profile directory by default,
    # then we copy it to our output location.
    if mkarchiso -v -w "${BUILD_DIR}/work" -o "${BUILD_DIR}" "${ARCHLIVE_DIR}"; then
        log "mkarchiso completed successfully"
    else
        error "mkarchiso failed"
    fi

    # Find the generated ISO
    local generated_iso
    generated_iso=$(find "${BUILD_DIR}" -maxdepth 1 -name "*.iso" -type f | head -1 2>/dev/null || true)
    if [[ -n "$generated_iso" ]]; then
        log "ISO generated: $generated_iso"
        ISO_OUTPUT="$generated_iso"
    else
        error "No ISO found in ${BUILD_DIR}"
    fi
}

# ─── Verify ISO ─────────────────────────────────────
verify_iso() {
    header "Verifying ISO"

    if [[ ! -f "$ISO_OUTPUT" ]]; then
        error "ISO not found: $ISO_OUTPUT"
    fi

    local iso_size
    iso_size=$(du -h "$ISO_OUTPUT" | cut -f1)
    log "ISO size: ${iso_size}"

    local iso_sha256
    iso_sha256=$(sha256sum "$ISO_OUTPUT" | cut -d' ' -f1)
    log "SHA256: ${iso_sha256}"

    # Check ISO validity
    if command -v xorriso &>/dev/null; then
        echo ""
        echo "  ISO structure:"
        xorriso -indev "$ISO_OUTPUT" -report_el_torito 2>&1 | while IFS= read -r line; do
            echo "    $line"
        done || true
    fi

    echo ""
}

# ─── Print summary ──────────────────────────────────
print_summary() {
    header "Build Complete"

    local iso_size
    iso_size=$(du -h "$ISO_OUTPUT" | cut -f1)

    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║   🎉  ChaldOS ISO готов!                                 ║"
    echo "║                                                           ║"
    printf "║   📀  ISO:  %-45s  ║\n" "$ISO_OUTPUT"
    printf "║   📦  Size: %-45s  ║\n" "$iso_size"
    printf "║   🏷️   Версия: %-43s  ║\n" "v${CHALDOS_VERSION} ${CHALDOS_CODENAME}"
    echo "║                                                           ║"
    echo "║   💿  Запись на USB:                                     ║"
    echo "║        sudo dd if=${ISO_OUTPUT} of=/dev/sdX bs=4M status=progress  ║"
    echo "║        sudo cp ${ISO_OUTPUT} /dev/sdX                              ║"
    echo "║                                                           ║"
    echo "║   🔥  Или запись через Rufus / Ventoy / balenaEtcher      ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
}

# ─── Clean ──────────────────────────────────────────
clean_build() {
    header "Cleaning Build Artifacts"
    rm -rf "${BUILD_DIR}/work"
    rm -f "${BUILD_DIR}"/*.iso
    # Remove airootfs copied files (but keep directory structure)
    rm -rf "${ARCHLIVE_DIR}/airootfs/root/chaldos"
    rm -f "${ARCHLIVE_DIR}/airootfs/usr/local/bin/chaldos-mascot"
    rm -f "${ARCHLIVE_DIR}/airootfs/usr/local/bin/chaldos-install"
    rm -f "${ARCHLIVE_DIR}/airootfs/root/.auto-welcome.sh"
    log "Build artifacts cleaned"
}

distclean_build() {
    clean_build
    header "Full Clean"
    rm -rf "${BUILD_DIR}"
    log "Output directory removed"
}

# ─── Help ───────────────────────────────────────────
show_help() {
    echo "ChaldOS Build Script — v${CHALDOS_VERSION:-2.0.0}"
    echo ""
    echo "Сборка загрузочного ISO ChaldOS на основе archiso."
    echo ""
    echo "Использование: ./build.sh [команда]"
    echo ""
    echo "Команды:"
    echo "  (без аргумента)   Собрать ISO"
    echo "  iso               Собрать ISO"
    echo "  all               Собрать ISO"
    echo "  clean             Очистить временные файлы сборки"
    echo "  distclean         Полная очистка"
    echo "  help              Показать помощь"
    echo ""
    echo "Требования:"
    echo "  pacman -S archiso"
    echo ""
    echo "Структура:"
    echo "  ./archlive/       — archiso профиль"
    echo "  ./installer/      — скрипты установщика"
    echo "  ./config/         — конфигурация"
    echo ""
    echo "Пример:"
    echo "  ./build.sh        # собрать ISO"
    echo "  sudo dd if=output/chaldos-*.iso of=/dev/sdX bs=4M status=progress  # запись на USB"
    echo ""
}

# ─── Main ───────────────────────────────────────────
main() {
    source_config

    case "${1:-all}" in
        all|iso)
            check_environment
            prepare_rootfs
            build_iso
            verify_iso
            print_summary
            ;;
        clean)
            clean_build
            ;;
        distclean)
            distclean_build
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Неизвестная команда: $1 (используй: ./build.sh help)"
            ;;
    esac
}

main "$@"
