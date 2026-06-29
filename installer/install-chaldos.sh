#!/bin/bash
# ChaldOS Installer v2.0 — Arch Linux Gaming Edition
# =====================================================
# Установщик на основе Arch Linux с выбором:
#   - Рабочих столов (KDE, GNOME, XFCE, Hyprland, Sway и др.)
#   - Видео-драйверов (NVIDIA, AMD, Intel) с таблицей выбора
#   - Геймерского софта (Steam, OBS, Lutris и др.)
#   - DaVinci Resolve Studio
#
# Запуск:
#   Загрузитесь с Arch ISO и выполните:
#   # curl -L chaldos.dev/install | bash
#   Или:
#   # ./install-chaldos.sh
#
# Внимание: установщик предназначен для Arch Live CD!
# =====================================================

set -euo pipefail

VERSION="2.0.0"
CHALDOS_CODENAME="Gaming Edition"

# ─── Цвета ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}"; }
title()  { echo -e "\n${BOLD}${MAGENTA}  ► $1${NC}\n"; }
prompt() { echo -ne "${CYAN}  →${NC} ${BOLD}$1${NC} "; }

# ─── Маскот ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "${SCRIPT_DIR}/mascot.sh" ]]; then
    source "${SCRIPT_DIR}/mascot.sh"
else
    # Встроенные минимальные функции маскота, если файл не найден
    chaldo_say()    { echo -e "${MAGENTA}🤖 Чалдо:${NC} $1"; }
    chaldo_think()  { echo -e "${MAGENTA}🤔 Чалдо:${NC} $1"; }
    chaldo_warn()   { echo -e "${MAGENTA}⚠️  Чалдо:${NC} $1"; }
    chaldo_work()   { echo -e "${MAGENTA}🔧 Чалдо:${NC} $1"; }
    chaldo_dance()  { echo -e "${MAGENTA}🎉 Чалдо:${NC} $1"; }
    chaldo_welcome(){ echo -e "${MAGENTA}╔════════════════════════════════╗${NC}"; }
    chaldo_goodbye(){ echo -e "${MAGENTA}╚════════════════════════════════╝${NC}"; }
fi

# ─── Конфигурация установки ───────────────────────────────
INSTALL_CONF="/tmp/chaldos-install.conf"

# Дефолтные значения
TARGET_DISK=""
INSTALL_TYPE=""            # entire, alongside, manual
BOOT_MODE=""               # uefi / bios
ROOT_PART=""
BOOT_PART=""
SWAP_PART=""
HOME_PART=""
LUKS_PASSWORD=""
HOSTNAME="chaldos"
USERNAME="chaldos"
USER_PASSWORD="chaldos"
ROOT_PASSWORD="chaldos"
KEYMAP="us"
LOCALE="en_US.UTF-8"
TIMEZONE="UTC"
SELECTED_DE=""             # Кодовое имя DE
SELECTED_GPU=""            # Выбранный GPU драйвер
SELECTED_GAMING=()         # Массив игровых пакетов
INSTALL_DAVINCI=false
AUR_HELPER="paru"

# ═══════════════════════════════════════════════════════════
# 1. ПРОВЕРКИ
# ═══════════════════════════════════════════════════════════

check_environment() {
    title "Проверка окружения"

    # Проверка root
    if [[ $EUID -ne 0 ]]; then
        chaldo_warn "Запусти меня с sudo или от root!"
        error "Этот установщик требует root-прав"
    fi
    log "Root доступ есть"

    # Проверка загрузки — Arch Live или нет?
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" != "arch" ]] || [[ -z "${ARCHISO_LIVE:-}" ]]; then
            warn "Похоже, это не Arch Live CD!"
            warn "Рекомендую загрузиться с официального Arch ISO."
            echo ""
            prompt "Продолжить всё равно? (y/N): "; read confirm
            [[ "$confirm" =~ ^[Yy] ]] || error "Установка отменена"
        else
            log "Arch Linux Live CD обнаружен — ${VERSION_ID:-rolling}"
        fi
    else
        warn "Не могу определить ОС, надеюсь это Arch Live CD..."
    fi

    # Интернет
    if ping -c 1 archlinux.org &>/dev/null 2>&1; then
        log "Интернет доступен"
    else
        chaldo_warn "Нет интернета! Нужен интернет для установки."
        error "Проверь подключение (iwctl для WiFi)"
    fi

    # Необходимые команды
    local required=(pacstrap genfstab arch-chroot parted mkfs.ext4 mkfs.fat)
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Команда '$cmd' не найдена. Ты точно в Arch Live CD?"
        fi
    done
    log "Все необходимые команды доступны"

    # Определение режима загрузки
    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="uefi"
        log "Режим загрузки: UEFI"
    else
        BOOT_MODE="bios"
        log "Режим загрузки: BIOS (legacy)"
    fi

    chaldo_say "Окружение в порядке! Едем дальше 🚀" "happy"
}

# ═══════════════════════════════════════════════════════════
# 2. ВЫБОР КЛАВИАТУРЫ И ЛОКАЛИ
# ═══════════════════════════════════════════════════════════

select_keyboard() {
    title "Раскладка клавиатуры и локаль"

    echo "  Доступные раскладки:"
    echo "   1) us    — English (US)        [по умолчанию]"
    echo "   2) ru    — Русская             🇷🇺"
    echo "   3) de    — Deutsch (German)"
    echo "   4) fr    — Français (French)"
    echo "   5) uk    — English (UK)"
    echo "   6) br    — Português (Brazil)"
    echo "   7) es    — Español (Spanish)"
    echo "   8) it    — Italiano (Italian)"
    echo "   9) Своя — ввести вручную"
    echo ""
    prompt "Выбери раскладку (1-9) [1]: "; read kbd_choice

    case "${kbd_choice:-1}" in
        1) KEYMAP="us"     LOCALE="en_US.UTF-8" ;;
        2) KEYMAP="ru"     LOCALE="ru_RU.UTF-8" ;;
        3) KEYMAP="de"     LOCALE="de_DE.UTF-8" ;;
        4) KEYMAP="fr"     LOCALE="fr_FR.UTF-8" ;;
        5) KEYMAP="uk"     LOCALE="en_GB.UTF-8" ;;
        6) KEYMAP="br"     LOCALE="pt_BR.UTF-8" ;;
        7) KEYMAP="es"     LOCALE="es_ES.UTF-8" ;;
        8) KEYMAP="it"     LOCALE="it_IT.UTF-8" ;;
        9)
            prompt "Введи название раскладки (см. /usr/share/kbd/keymaps/): "; read KEYMAP
            prompt "Введи локаль (например, en_US.UTF-8): "; read LOCALE
            ;;
        *) KEYMAP="us"     LOCALE="en_US.UTF-8" ;;
    esac

    # Применяем раскладку
    loadkeys "$KEYMAP" 2>/dev/null || warn "Не удалось применить раскладку '$KEYMAP'"
    log "Раскладка: $KEYMAP, локаль: $LOCALE"

    # Часовой пояс
    echo ""
    prompt "Часовой пояс (например, Europe/Moscow, America/New_York) [UTC]: "; read tz_input
    TIMEZONE="${tz_input:-UTC}"

    if [[ -f "/usr/share/zoneinfo/${TIMEZONE}" ]]; then
        log "Часовой пояс: $TIMEZONE"
    else
        warn "Часовой пояс '$TIMEZONE' не найден, ставлю UTC"
        TIMEZONE="UTC"
    fi
}

# ═══════════════════════════════════════════════════════════
# 3. ВЫБОР ДИСКА И РАЗМЕТКА
# ═══════════════════════════════════════════════════════════

select_disk() {
    title "Выбор диска для установки"

    echo "  Доступные диски:"
    echo "  ─────────────────────────────────────────────"
    lsblk -o NAME,SIZE,TYPE,MODEL,MOUNTPOINT 2>/dev/null | grep -E 'disk|NAME' || \
        fdisk -l 2>/dev/null | grep '^Disk /'

    echo ""
    prompt "Введи диск (например, /dev/sda, /dev/nvme0n1): "; read TARGET_DISK

    if [[ ! -b "$TARGET_DISK" ]]; then
        error "Диск $TARGET_DISK не найден!"
    fi

    # Проверка, не смонтирован ли диск
    if mount | grep -q "$TARGET_DISK"; then
        warn "Диск $TARGET_DISK смонтирован! Размонтируй его: umount -R /mnt"
        prompt "Размонтировать сейчас? (Y/n): "; read umnt_confirm
        if [[ ! "${umnt_confirm:-y}" =~ ^[Nn] ]]; then
            umount -R "$TARGET_DISK"?* 2>/dev/null || true
            umount "$TARGET_DISK" 2>/dev/null || true
            log "Диск размонтирован"
        else
            error "Размонтируй диск вручную и запусти снова"
        fi
    fi

    log "Выбран диск: $TARGET_DISK ($(lsblk -nd -o SIZE "$TARGET_DISK" 2>/dev/null))"

    # Предупреждение о стирании
    echo ""
    warn "ВНИМАНИЕ: Все данные на ${TARGET_DISK} будут удалены!"
    prompt "Ты уверен, что хочешь продолжить? (yes/no): "; read confirm
    [[ "$confirm" = "yes" ]] || error "Установка отменена пользователем"
}

# Тип установки
select_install_type() {
    title "Тип установки"

    echo "   1) Использовать весь диск     — автоматическая разметка"
    echo "   2) Рядом с другой ОС          — уменьшить раздел и установить рядом"
    echo "   3) Ручная разметка            — для опытных пользователей"
    echo ""
    prompt "Выбери тип (1-3) [1]: "; read type_choice

    case "${type_choice:-1}" in
        1) INSTALL_TYPE="entire" ;;
        2) INSTALL_TYPE="alongside" ;;
        3) INSTALL_TYPE="manual" ;;
        *) INSTALL_TYPE="entire" ;;
    esac
    log "Тип установки: $INSTALL_TYPE"
}

# Разметка диска
partition_disk() {
    title "Разметка диска"

    case "$INSTALL_TYPE" in
        entire)    partition_entire ;;
        alongside) partition_alongside ;;
        manual)    partition_manual ;;
    esac
}

partition_entire() {
    chaldo_work "Размечаю диск $TARGET_DISK..."

    # Затираем таблицу разделов
    dd if=/dev/zero of="$TARGET_DISK" bs=1M count=10 status=none 2>/dev/null || true
    wipefs -af "$TARGET_DISK" &>/dev/null || true

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        log "UEFI разметка (GPT)"
        parted -s "$TARGET_DISK" mklabel gpt
        parted -s "$TARGET_DISK" mkpart "EFI" fat32 1MiB 1GiB
        parted -s "$TARGET_DISK" set 1 esp on
        parted -s "$TARGET_DISK" mkpart "SWAP" linux-swap 1GiB 9GiB
        parted -s "$TARGET_DISK" mkpart "ROOT" ext4 9GiB 100%

        BOOT_PART="${TARGET_DISK}1"
        SWAP_PART="${TARGET_DISK}2"
        ROOT_PART="${TARGET_DISK}3"

        # Для NVMe дисков
        if [[ "$TARGET_DISK" == /dev/nvme* ]]; then
            BOOT_PART="${TARGET_DISK}p1"
            SWAP_PART="${TARGET_DISK}p2"
            ROOT_PART="${TARGET_DISK}p3"
        fi

        log "Форматирую разделы..."
        mkfs.fat -F32 -n "CHALDOS_EFI" "$BOOT_PART" &>/dev/null
        mkswap -L "CHALDOS_SWAP" "$SWAP_PART" &>/dev/null
        mkfs.ext4 -F -L "CHALDOS_ROOT" "$ROOT_PART" &>/dev/null

        log "Таблица разделов (UEFI):"
        lsblk -o NAME,SIZE,FSTYPE,LABEL "$TARGET_DISK"
    else
        log "BIOS разметка (MBR)"
        parted -s "$TARGET_DISK" mklabel msdos
        parted -s "$TARGET_DISK" mkpart primary linux-swap 1MiB 9GiB
        parted -s "$TARGET_DISK" mkpart primary ext4 9GiB 100%
        parted -s "$TARGET_DISK" set 2 boot on

        SWAP_PART="${TARGET_DISK}1"
        ROOT_PART="${TARGET_DISK}2"
        BOOT_PART=""

        mkswap -L "CHALDOS_SWAP" "$SWAP_PART" &>/dev/null
        mkfs.ext4 -F -L "CHALDOS_ROOT" "$ROOT_PART" &>/dev/null

        log "Таблица разделов (BIOS):"
        lsblk -o NAME,SIZE,FSTYPE,LABEL "$TARGET_DISK"
    fi

    chaldo_say "Диск размечен! Поехали дальше 💪" "happy"
}

partition_alongside() {
    warn "Установка рядом с другой ОС — нужно свободное место."
    warn "Сначала уменьши существующий раздел (например, через GParted или Windows Disk Management)."
    echo ""
    prompt "У тебя есть свободное неразмеченное место? (yes/no): "; read free_confirm
    if [[ "$free_confirm" != "yes" ]]; then
        warn "Освободи место и запусти снова."
        error "Установка прервана"
    fi

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        # На UEFI обычно есть ESP, используем её
        echo "Доступные разделы ESP (EFI):"
        lsblk -o NAME,SIZE,FSTYPE,LABEL | grep -E 'vfat|fat'
        prompt "Введи ESP раздел (или Enter для поиска): "; read esp_input
        if [[ -z "$esp_input" ]]; then
            # Ищем ESP
            for part in /dev/sd*[1-9] /dev/nvme*p*[1-9]; do
                if [[ -b "$part" ]] && blkid "$part" | grep -qi 'vfat'; then
                    BOOT_PART="$part"
                    log "Найден ESP: $BOOT_PART"
                    break
                fi
            done
        else
            BOOT_PART="$esp_input"
        fi
    fi

    prompt "Введи раздел для ChaldOS (например, ${TARGET_DISK}3): "; read ROOT_PART
    prompt "Создать swap раздел? (y/N): "; read swap_q
    if [[ "$swap_q" =~ ^[Yy] ]]; then
        prompt "Введи swap раздел: "; read SWAP_PART
    fi

    if [[ -n "$BOOT_PART" ]]; then
        log "Форматировать ESP ($BOOT_PART)?"
        prompt "Это удалит другие загрузчики! (y/N): "; read fmt_esp
        if [[ "$fmt_esp" =~ ^[Yy] ]]; then
            mkfs.fat -F32 -n "CHALDOS_EFI" "$BOOT_PART" &>/dev/null
        fi
    fi

    mkfs.ext4 -F -L "CHALDOS_ROOT" "$ROOT_PART" &>/dev/null
    if [[ -n "$SWAP_PART" ]]; then
        mkswap -L "CHALDOS_SWAP" "$SWAP_PART" &>/dev/null
    fi

    log "Разделы готовы"
}

partition_manual() {
    echo "Ручная разметка:"
    echo "  1) Открыть cfdisk (удобный TUI)"
    echo "  2) Открыть fdisk  (классический)"
    echo "  3) Использовать существующие разделы"
    echo ""
    prompt "Выбери (1-3) [1]: "; read manual_tool

    case "${manual_tool:-1}" in
        1)
            cfdisk "$TARGET_DISK" || fdisk "$TARGET_DISK"
            ;;
        2)
            fdisk "$TARGET_DISK"
            ;;
        3)
            log "Использую существующие разделы"
            ;;
    esac

    echo ""
    echo "Теперь укажи разделы:"
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$TARGET_DISK"
    echo ""

    prompt "Корневой раздел (/): "; read ROOT_PART
    if [[ -n "$ROOT_PART" ]]; then
        prompt "Форматировать $ROOT_PART? (y/N): "; read fmt_root
        [[ "$fmt_root" =~ ^[Yy] ]] && mkfs.ext4 -F -L "CHALDOS_ROOT" "$ROOT_PART" &>/dev/null
    fi

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        prompt "EFI раздел (/boot): "; read BOOT_PART
    fi

    prompt "Swap раздел (Enter если не нужен): "; read SWAP_PART
    if [[ -n "$SWAP_PART" ]]; then
        prompt "Форматировать swap? (y/N): "; read fmt_swap
        [[ "$fmt_swap" =~ ^[Yy] ]] && mkswap -L "CHALDOS_SWAP" "$SWAP_PART" &>/dev/null
    fi

    log "Ручная разметка завершена"
}

# ═══════════════════════════════════════════════════════════
# 4. ВЫБОР РАБОЧЕГО СТОЛА
# ═══════════════════════════════════════════════════════════

declare -A DE_INFO

select_desktop() {
    title "Выбор рабочего стола"

    # Определение DE
    DE_INFO=(
        ["kde"]="KDE Plasma 6      | Современный, красивый, для игр  | plasma"
        ["gnome"]="GNOME 46         | Интуитивный, минималистичный  | gnome"
        ["xfce"]="XFCE 4.18        | Лёгкий, быстрый               | xfce4"
        ["hyprland"]="Hyprland       | Стильный Wayland композитор  | hyprland"
        ["sway"]="Sway             | i3-подобный Wayland           | sway"
        ["budgie"]="Budgie 10       | Элегантный, простой          | budgie"
        ["cinnamon"]="Cinnamon        | Классический Windows-like    | cinnamon"
        ["mate"]="MATE 1.28        | Лёгкий, традиционный         | mate"
        ["i3"]="i3 WM            | Минималистичный тайловый      | i3"
        ["none"]="Без DE          | Только консоль               | none"
    )

    echo "  Доступные окружения:"
    echo "  ┌──────┬──────────────────────────────┬─────────────────────────────────┐"
    printf "  │ %-4s │ %-28s │ %-31s │\n" "Код" "Рабочий стол" "Описание"
    echo "  ├──────┼──────────────────────────────┼─────────────────────────────────┤"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "kde"  "KDE Plasma 6"    "🎮 Современный, красивый, для игр"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "gnome" "GNOME 46"      "🖥️ Интуитивный, минималистичный"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "xfce"  "XFCE 4.18"     "⚡ Лёгкий, быстрый"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "hyprland" "Hyprland"  "✨ Стильный Wayland композитор"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "sway"  "Sway"          "🪟 i3-подобный Wayland"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "budgie" "Budgie 10"   "🌿 Элегантный, простой"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "cinnamon" "Cinnamon"  "🍭 Классический Windows-like"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "mate"  "MATE 1.28"     "🍃 Лёгкий, традиционный"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "i3"    "i3 WM"         "🔲 Минималистичный тайловый"
    printf "  │ ${GREEN}%-4s${NC} │ %-28s │ %-31s │\n" "none"  "Без DE"        "💻 Только консоль"
    echo "  └──────┴──────────────────────────────┴─────────────────────────────────┘"
    echo ""

    chaldo_say "Какой рабочий стол хочешь? Для игр отлично подходит KDE Plasma! 🎮" "think"

    prompt "Введи код: "; read SELECTED_DE
    SELECTED_DE="${SELECTED_DE:-kde}"

    if [[ ! "${DE_INFO[$SELECTED_DE]:-}" ]]; then
        warn "Неизвестный код '$SELECTED_DE', ставлю KDE"
        SELECTED_DE="kde"
    fi

    # Получаем читаемое имя
    local de_name="${DE_INFO[$SELECTED_DE]%%|*}"
    log "Выбран: ${de_name}"

    # Если выбрали DE — спросить про DM
    if [[ "$SELECTED_DE" != "none" ]]; then
        select_display_manager
    fi
}

# Выбор менеджера входа (Display Manager)
select_display_manager() {
    echo ""
    echo "  Менеджер входа (Display Manager):"
    echo "   1) sddm    — для KDE Plasma [по умолчанию]"
    echo "   2) gdm     — для GNOME"
    echo "   3) lightdm — лёгкий, для XFCE/Budgie/Cinnamon/MATE"
    echo "   4) ly      — минималистичный TUI"
    echo "   5) Без DM  — вход через консоль + startx/hyprctl"
    echo ""
    prompt "Выбери DM (1-5): "; read dm_choice

    case "${dm_choice:-1}" in
        1) SELECTED_DM="sddm" ;;
        2) SELECTED_DM="gdm" ;;
        3) SELECTED_DM="lightdm" ;;
        4) SELECTED_DM="ly" ;;
        5) SELECTED_DM="none" ;;
        *) SELECTED_DM="sddm" ;;
    esac
    log "DM: $SELECTED_DM"
}

# ═══════════════════════════════════════════════════════════
# 5. ВЫБОР ВИДЕО-ДРАЙВЕРОВ (ТАБЛИЦА)
# ═══════════════════════════════════════════════════════════

select_gpu() {
    title "Выбор видео-драйверов"

    chaldo_think "Какя у тебя видеокарта? Я помогу выбрать правильный драйвер!"

    echo ""
    echo "  ┌──────┬──────────────────────────────────────┬──────────────────────────────────────────────┐"
    echo "  │  #   │ Видеокарта / Драйвер                 │ Описание                                    │"
    echo "  ├──────┼──────────────────────────────────────┼──────────────────────────────────────────────┤"
    echo -e "  │  ${GREEN}1${NC})  │ ${BOLD}NVIDIA${NC} — nvidia              │ ⭐ Проприетарный драйвер (последняя версия)  │"
    echo -e "  │  ${GREEN}2${NC})  │ ${BOLD}NVIDIA${NC} — nvidia-open        │ 🔓 Открытый модуль ядра (для RTX 2xxx+)    │"
    echo -e "  │  ${GREEN}3${NC})  │ ${BOLD}NVIDIA${NC} — nvidia-dkms        │ 🔧 DKMS версия (собирается под ядро)       │"
    echo -e "  │  ${GREEN}4${NC})  │ ${BOLD}NVIDIA${NC} — nvidia-lts         │ 🛡️ LTS версия (для linux-lts)              │"
    echo -e "  │  ${GREEN}5${NC})  │ ${BOLD}NVIDIA${NC} — nouveau            │ 🐧 Свободный драйвер (базовая поддержка)   │"
    echo "  ├──────┼──────────────────────────────────────┼──────────────────────────────────────────────┤"
    echo -e "  │  ${GREEN}6${NC})  │ ${BOLD}AMD${NC}    — amdgpu/mesa        │ ⭐ Открытый драйвер (отличная поддержка!)   │"
    echo -e "  │  ${GREEN}7${NC})  │ ${BOLD}AMD${NC}    — amd-pro (AUR)     │ 💼 Проприетарный драйвер (для рабочих станций)│"
    echo "  ├──────┼──────────────────────────────────────┼──────────────────────────────────────────────┤"
    echo -e "  │  ${GREEN}8${NC})  │ ${BOLD}Intel${NC}  — i915/mesa          │ ⭐ Открытый драйвер (встроенная графика)    │"
    echo -e "  │  ${GREEN}9${NC})  │ ${BOLD}Intel${NC}  — intel-compute      │ 🔬 Вычислительный стек Intel                │"
    echo "  ├──────┼──────────────────────────────────────┼──────────────────────────────────────────────┤"
    echo -e "  │  ${GREEN}10${NC}) │ ${BOLD}VM/Virt${NC} — virtio/vmware     │ 🖥️ Виртуальная машина                       │"
    echo "  └──────┴──────────────────────────────────────┴──────────────────────────────────────────────┘"
    echo ""
    echo "  💡 Подсказка:"
    echo "     • NVIDIA RTX 2xxx+ → выбирай nvidia-open (2)"
    echo "     • NVIDIA GTX 7xx+  → выбирай nvidia (1)"
    echo "     • AMD Radeon       → выбирай amdgpu/mesa (6)"
    echo "     • Intel            → выбирай i915/mesa (8)"
    echo ""

    prompt "Выбери номер (1-10): "; read gpu_choice

    case "${gpu_choice:-6}" in
        1) SELECTED_GPU="nvidia" ;;
        2) SELECTED_GPU="nvidia-open" ;;
        3) SELECTED_GPU="nvidia-dkms" ;;
        4) SELECTED_GPU="nvidia-lts" ;;
        5) SELECTED_GPU="nouveau" ;;
        6) SELECTED_GPU="amdgpu" ;;
        7) SELECTED_GPU="amd-pro" ;;
        8) SELECTED_GPU="intel" ;;
        9) SELECTED_GPU="intel-compute" ;;
        10) SELECTED_GPU="virtio" ;;
        *) SELECTED_GPU="amdgpu" ;;
    esac

    # Показать что выбрали
    local gpu_names=(
        [nvidia]="NVIDIA — nvidia (проприетарный)"
        [nvidia-open]="NVIDIA — nvidia-open (открытый модуль)"
        [nvidia-dkms]="NVIDIA — nvidia-dkms (DKMS)"
        [nvidia-lts]="NVIDIA — nvidia-lts (LTS)"
        [nouveau]="NVIDIA — nouveau (свободный)"
        [amdgpu]="AMD — amdgpu/mesa (открытый)"
        [amd-pro]="AMD — AMDGPU-PRO (проприетарный)"
        [intel]="Intel — i915/mesa (открытый)"
        [intel-compute]="Intel — вычислительный стек"
        [virtio]="VM/Virt — virtio/vmware"
    )

    log "Выбран драйвер: ${gpu_names[$SELECTED_GPU]}"
    chaldo_say "Отличный выбор! Драйверы установятся автоматически 🎯" "happy"
}

# ═══════════════════════════════════════════════════════════
# 6. ВЫБОР ИГРОВОГО СОФТА
# ═══════════════════════════════════════════════════════════

select_gaming() {
    title "Геймерский софт 🎮"

    chaldo_say "Давай накатим софта для игр! Выбирай, что нужно:" "cool"

    echo ""
    echo "  ┌──────┬──────────────────────────┬────────────────────────────────────────────┐"
    echo "  │  #   │ Пакет                    │ Описание                                  │"
    echo "  ├──────┼──────────────────────────┼────────────────────────────────────────────┤"
    echo -e "  │  ${GREEN}1${NC})  │ Steam                     │ 🎮 Главный игровой магазин               │"
    echo -e "  │  ${GREEN}2${NC})  │ Lutris                    │ 🐧 Открытая игровая платформа            │"
    echo -e "  │  ${GREEN}3${NC})  │ Heroic Games Launcher     │ 🎯 Epic Games + GOG лаунчер              │"
    echo -e "  │  ${GREEN}4${NC})  │ OBS Studio                │ 📺 Запись и стриминг                     │"
    echo -e "  │  ${GREEN}5${NC})  │ MangoHud + GOverlay       │ 📊 FPS мониторинг и настройка            │"
    echo -e "  │  ${GREEN}6${NC})  │ Wine + Wine-Staging       │ 🍷 Запуск Windows игр                    │"
    echo -e "  │  ${GREEN}7${NC})  │ Proton GE                 │ 🔧 Кастомный Proton (через AUR)          │"
    echo -e "  │  ${GREEN}8${NC})  │ Gamescope                 │ 🖥️ Микро-композитор для игр              │"
    echo -e "  │  ${GREEN}9${NC})  │ GameMode                  │ ⚡ Оптимизация системы для игр            │"
    echo -e "  │  ${GREEN}10${NC}) │ Discord                    │ 💬 Голосовой чат для геймеров             │"
    echo -e "  │  ${GREEN}11${NC}) │ Prism Launcher            │ 🧊 Майнкрафт лаунчер                      │"
    echo -e "  │  ${GREEN}12${NC}) │ Vulkan Tools              │ 🖌️ Современная графика                   │"
    echo -e "  │  ${GREEN}13${NC}) │ Все пакеты                │ 📦 Установить всё!                        │"
    echo -e "  │  ${GREEN}14${NC}) │ Пропустить                │ ❌ Не устанавливать                       │"
    echo "  └──────┴──────────────────────────┴────────────────────────────────────────────┘"
    echo ""
    prompt "Введи номера через пробел (например: 1 4 10): "; read gaming_choices

    if [[ -z "$gaming_choices" ]]; then
        SELECTED_GAMING=()
        log "Игровой софт пропущен"
        return
    fi

    # Проверка на "всё" или "пропустить"
    for choice in $gaming_choices; do
        case "$choice" in
            13)
                SELECTED_GAMING=("ALL")
                log "Устанавливаем ВСЁ игровое!"
                chaldo_say "Ого, по полной! Люблю такой подход! 🎮🔥" "love"
                return
                ;;
            14)
                SELECTED_GAMING=()
                log "Игровой софт пропущен"
                return
                ;;
        esac
    done

    SELECTED_GAMING=()
    for choice in $gaming_choices; do
        case "$choice" in
            1)  SELECTED_GAMING+=("steam") ;;
            2)  SELECTED_GAMING+=("lutris") ;;
            3)  SELECTED_GAMING+=("heroic") ;;
            4)  SELECTED_GAMING+=("obs") ;;
            5)  SELECTED_GAMING+=("mangohud") ;;
            6)  SELECTED_GAMING+=("wine") ;;
            7)  SELECTED_GAMING+=("proton-ge") ;;
            8)  SELECTED_GAMING+=("gamescope") ;;
            9)  SELECTED_GAMING+=("gamemode") ;;
            10) SELECTED_GAMING+=("discord") ;;
            11) SELECTED_GAMING+=("prism") ;;
            12) SELECTED_GAMING+=("vulkan") ;;
        esac
    done

    if [[ ${#SELECTED_GAMING[@]} -gt 0 ]]; then
        log "Выбрано пакетов: ${#SELECTED_GAMING[@]}"
        for pkg in "${SELECTED_GAMING[@]}"; do
            echo "    • $pkg"
        done
    fi
}

# ═══════════════════════════════════════════════════════════
# 7. DaVinci Resolve Studio
# ═══════════════════════════════════════════════════════════

select_davinci() {
    title "DaVinci Resolve Studio 🎬"

    chaldo_say "Хочешь монтировать видео профессионально? DaVinci Resolve — топ!" "think"

    echo ""
    echo "  DaVinci Resolve Studio — профессиональный видеоредактор"
    echo "  от Blackmagic Design. Я могу установить его автоматически!"
    echo ""
    echo "  Варианты:"
    echo "   1) DaVinci Resolve Studio — из AUR (через paru)"
    echo "   2) DaVinci Resolve (Free) — бесплатная версия"
    echo "   3) Скачать и установить вручную (сам загрузишь архив)"
    echo "   4) Пропустить"
    echo ""

    prompt "Выбери вариант (1-4) [4]: "; read dv_choice
    case "${dv_choice:-4}" in
        1) INSTALL_DAVINCI="studio" ;;
        2) INSTALL_DAVINCI="free" ;;
        3) INSTALL_DAVINCI="manual" ;;
        *) INSTALL_DAVINCI=false ;;
    esac

    if [[ "$INSTALL_DAVINCI" != "false" ]]; then
        log "DaVinci Resolve будет установлен"
        # Для DaVinci нужен AUR-хелпер
        if [[ "$INSTALL_DAVINCI" == "studio" || "$INSTALL_DAVINCI" == "free" ]]; then
            SELECTED_AUR=true
        fi
    fi
}

# ═══════════════════════════════════════════════════════════
# 8. ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ
# ═══════════════════════════════════════════════════════════

select_extra() {
    title "Дополнительные настройки"

    # Имя хоста
    prompt "Имя компьютера (hostname) [chaldos]: "; read host_input
    HOSTNAME="${host_input:-chaldos}"

    # Имя пользователя
    prompt "Имя пользователя [chaldos]: "; read user_input
    USERNAME="${user_input:-chaldos}"

    # Пароль пользователя
    prompt "Пароль пользователя [chaldos]: "; read -s pass_input
    echo ""
    USER_PASSWORD="${pass_input:-chaldos}"

    # Пароль root
    prompt "Пароль root [chaldos]: "; read -s root_pass_input
    echo ""
    ROOT_PASSWORD="${root_pass_input:-chaldos}"

    # Дополнительные пакеты
    echo ""
    prompt "Доп. пакеты через пробел (например: firefox vlc gimp) или Enter: "; read extra_pkgs
    EXTRA_PACKAGES="${extra_pkgs:-}"

    # ZSH или Bash?
    echo ""
    echo "  Выбор shell (оболочки):"
    echo "   1) Bash — классика [по умолчанию]"
    echo "   2) ZSH + Oh My Zsh — красиво и удобно"
    echo "   3) Fish — удобно из коробки"
    echo ""
    prompt "Выбери (1-3) [1]: "; read shell_choice
    case "${shell_choice:-1}" in
        2) SELECTED_SHELL="zsh" ;;
        3) SELECTED_SHELL="fish" ;;
        *) SELECTED_SHELL="bash" ;;
    esac

    log "Доп. настройки сохранены"
}

# ═══════════════════════════════════════════════════════════
# 9. ИТОГОВАЯ ТАБЛИЦА И ПОДТВЕРЖДЕНИЕ
# ═══════════════════════════════════════════════════════════

show_summary() {
    title "Сводка установки"

    # Имена для отображения
    local de_name="${DE_INFO[$SELECTED_DE]%%|*}"
    [[ -z "$de_name" ]] && de_name="$SELECTED_DE"

    local gpu_names=(
        [nvidia]="NVIDIA — nvidia (проприетарный)"
        [nvidia-open]="NVIDIA — nvidia-open (открытый модуль)"
        [nvidia-dkms]="NVIDIA — nvidia-dkms (DKMS)"
        [nvidia-lts]="NVIDIA — nvidia-lts (LTS)"
        [nouveau]="NVIDIA — nouveau (свободный)"
        [amdgpu]="AMD — amdgpu/mesa (открытый)"
        [amd-pro]="AMD — AMDGPU-PRO (проприетарный)"
        [intel]="Intel — i915/mesa (открытый)"
        [intel-compute]="Intel — вычислительный стек"
        [virtio]="VM/Virt — virtio/vmware"
    )

    echo ""
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║           ИТОГОВАЯ СВОДКА УСТАНОВКИ                 ║"
    echo "  ╠═══════════════════════════════════════════════════════╣"
    printf "  ║  %-20s │ %-30s ║\n" "Параметр" "Значение"
    echo "  ║────────────────────┼─────────────────────────────────║"
    printf "  ║  %-20s │ %-30s ║\n" "Диск" "$TARGET_DISK"
    printf "  ║  %-20s │ %-30s ║\n" "Режим" "$BOOT_MODE"
    printf "  ║  %-20s │ %-30s ║\n" "Корень (/) " "${ROOT_PART:-auto}"
    printf "  ║  %-20s │ %-30s ║\n" "EFI (/boot)" "${BOOT_PART:-—}"
    printf "  ║  %-20s │ %-30s ║\n" "Swap" "${SWAP_PART:-—}"
    printf "  ║  %-20s │ %-30s ║\n" "Рабочий стол" "$de_name"
    printf "  ║  %-20s │ %-30s ║\n" "DM" "${SELECTED_DM:-sddm}"
    printf "  ║  %-20s │ %-30s ║\n" "Драйвер GPU" "${gpu_names[$SELECTED_GPU]:-$SELECTED_GPU}"
    printf "  ║  %-20s │ %-30s ║\n" "Хост" "$HOSTNAME"
    printf "  ║  %-20s │ %-30s ║\n" "Пользователь" "$USERNAME"
    printf "  ║  %-20s │ %-30s ║\n" "Шелл" "$SELECTED_SHELL"
    if [[ ${#SELECTED_GAMING[@]} -gt 0 ]]; then
        printf "  ║  %-20s │ %-30s ║\n" "Геймерский софт" "${#SELECTED_GAMING[@]} пакетов"
    fi
    if [[ "$INSTALL_DAVINCI" != "false" ]]; then
        printf "  ║  %-20s │ %-30s ║\n" "DaVinci Resolve" "$INSTALL_DAVINCI"
    fi
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo ""

    chaldo_say "Проверь всё внимательно! После подтверждения пойдёт установка." "think"

    prompt "Начать установку? (yes/no): "; read final_confirm
    if [[ "$final_confirm" != "yes" ]]; then
        echo ""
        prompt "Вернуться к выбору диска? (Y/n): "; read restart_choice
        if [[ ! "${restart_choice:-y}" =~ ^[Nn] ]]; then
            main_installer
        else
            error "Установка отменена пользователем"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════
# 10. УСТАНОВКА БАЗОВОЙ СИСТЕМЫ
# ═══════════════════════════════════════════════════════════

install_base() {
    title "Установка базовой системы Arch Linux"

    chaldo_work "Монтирую разделы..."

    local mount_point="/mnt"

    # Монтируем root
    mkdir -p "$mount_point"
    mount "$ROOT_PART" "$mount_point"

    # Монтируем EFI
    if [[ -n "$BOOT_PART" ]]; then
        mkdir -p "${mount_point}/boot"
        mount "$BOOT_PART" "${mount_point}/boot"
    fi

    # Включаем swap
    if [[ -n "$SWAP_PART" ]]; then
        swapon "$SWAP_PART" 2>/dev/null || true
    fi

    # Базовые пакеты
    local base_pkgs="base base-devel linux linux-firmware linux-headers"
    base_pkgs+=" amd-ucode"  # Для AMD процессоров
    base_pkgs+=" sudo nano vim man-db man-pages"
    base_pkgs+=" networkmanager dhcpcd"
    base_pkgs+=" bash-completion"

    chaldo_work "Загружаю базовую систему (около 500 МБ)..."
    log "Это займёт несколько минут, наберись терпения!"

    if ! pacstrap "$mount_point" $base_pkgs; then
        error "Ошибка установки базовой системы. Проверь интернет и репозитории."
    fi

    log "Базовая система установлена!"
}

# ═══════════════════════════════════════════════════════════
# 11. НАСТРОЙКА СИСТЕМЫ
# ═══════════════════════════════════════════════════════════

configure_system() {
    title "Настройка системы"

    local mount_point="/mnt"

    chaldo_work "Настраиваю конфиги..."

    # FSTAB
    genfstab -U "$mount_point" > "${mount_point}/etc/fstab" 2>/dev/null
    log "FSTAB создан"

    # HOSTNAME
    echo "$HOSTNAME" > "${mount_point}/etc/hostname"
    cat > "${mount_point}/etc/hosts" << HOSTSEOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
HOSTSEOF

    # LOCALE
    sed -i "s/^#${LOCALE}/${LOCALE}/" "${mount_point}/etc/locale.gen"
    arch-chroot "$mount_point" locale-gen &>/dev/null || true
    echo "LANG=${LOCALE}" > "${mount_point}/etc/locale.conf"
    log "Локаль: $LOCALE"

    # KEYMAP
    echo "KEYMAP=${KEYMAP}" > "${mount_point}/etc/vconsole.conf"
    log "Раскладка: $KEYMAP"

    # TIMEZONE
    arch-chroot "$mount_point" ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    arch-chroot "$mount_point" hwclock --systohc &>/dev/null || true
    log "Часовой пояс: $TIMEZONE"

    # Настройка PACMAN (разноцветный + параллельная загрузка)
    sed -i 's/#Color/Color/' "${mount_point}/etc/pacman.conf"
    sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' "${mount_point}/etc/pacman.conf"
    sed -i 's/#VerbosePkgLists/VerbosePkgLists/' "${mount_point}/etc/pacman.conf"

    # Включаем multilib (нужен для Steam и Wine)
    if ! grep -q '^\[multilib\]' "${mount_point}/etc/pacman.conf" 2>/dev/null; then
        echo "" >> "${mount_point}/etc/pacman.conf"
        echo "[multilib]" >> "${mount_point}/etc/pacman.conf"
        echo "Include = /etc/pacman.d/mirrorlist" >> "${mount_point}/etc/pacman.conf"
        log "Репозиторий multilib включён"
    fi

    # Обновляем пакеты в chroot
    arch-chroot "$mount_point" pacman -Sy --noconfirm &>/dev/null || true

    # ROOT пароль
    echo "root:${ROOT_PASSWORD}" | arch-chroot "$mount_point" chpasswd
    log "Пароль root установлен"

    # СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ
    arch-chroot "$mount_point" useradd -m -G wheel,audio,video,optical,storage,input,games -s "/bin/${SELECTED_SHELL}" "$USERNAME" 2>/dev/null || true
    echo "${USERNAME}:${USER_PASSWORD}" | arch-chroot "$mount_point" chpasswd
    log "Пользователь '$USERNAME' создан"

    # SUDO
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "${mount_point}/etc/sudoers" 2>/dev/null || true
    log "sudo настроен"

    # NetworkManager
    arch-chroot "$mount_point" systemctl enable NetworkManager &>/dev/null || true
    log "NetworkManager включён"

    # ChaldOS branding
    mkdir -p "${mount_point}/etc/chaldos"
    cat > "${mount_point}/etc/chaldos/chaldos.conf" << CHALDOSCONF
# ChaldOS System Configuration
# ==============================
CHALDOS_VERSION="${VERSION}"
CHALDOS_CODENAME="${CHALDOS_CODENAME}"
CHALDOS_BASE="Arch Linux"
INSTALL_DATE="$(date '+%Y-%m-%d %H:%M')"
HOSTNAME="${HOSTNAME}"
DESKTOP="${SELECTED_DE}"
GPU_DRIVER="${SELECTED_GPU}"
CHALDOSCONF

    # OS-release
    cat > "${mount_point}/etc/os-release" << OSRELEOF
NAME="ChaldOS"
ID=chaldos
PRETTY_NAME="ChaldOS ${VERSION} — ${CHALDOS_CODENAME}"
VERSION_ID="${VERSION}"
HOME_URL="https://chaldos.dev"
SUPPORT_URL="https://github.com/ChaldS-mods"
BUG_REPORT_URL="https://github.com/ChaldS-mods"
ARCHITECTURE="x86_64"
VERSION_CODENAME="${CHALDOS_CODENAME}"
LOGO="chaldos"
OSRELEOF

    # MOTD с маскотом
    cat > "${mount_point}/etc/motd" << MOTDEOF
╔═══════════════════════════════════════════════╗
║            ДОБРО ПОЖАЛОВАТЬ В ChaldOS!        ║
║                                               ║
║       ╱◉‿◉╲                                   ║
║       │  ❤  │     🎮 Gaming Edition v${VERSION}     ║
║       │ ╱─╲ │                                  ║
║       ╰─────╯                                  ║
║                                               ║
║   Введи 'chaldos-mascot' для приветствия!     ║
╚═══════════════════════════════════════════════╝
MOTDEOF

    log "Система настроена!"
    chaldo_say "База готова! Теперь накатываем драйверы и софт 🚀" "happy"
}

# ═══════════════════════════════════════════════════════════
# 12. УСТАНОВКА GPU ДРАЙВЕРОВ
# ═══════════════════════════════════════════════════════════

install_gpu_drivers() {
    title "Установка GPU драйверов"

    local mount_point="/mnt"

    chaldo_work "Устанавливаю драйвер для: $SELECTED_GPU"

    # Общие пакеты для всех
    local vulkan_pkgs="vulkan-icd-loader vulkan-tools lib32-vulkan-icd-loader"
    local mesa_pkgs="mesa lib32-mesa mesa-utils"

    case "$SELECTED_GPU" in
        nvidia)
            log "Установка NVIDIA (проприетарный)..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                nvidia nvidia-utils nvidia-settings \
                lib32-nvidia-utils \
                $vulkan_pkgs \
                --needed &>/dev/null || warn "Ошибка установки NVIDIA"

            # Включение DRM
            local nvidia_conf="${mount_point}/etc/modprobe.d/nvidia.conf"
            cat > "$nvidia_conf" << 'NVEOF'
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
NVEOF
            log "NVIDIA DRM modeset включён"
            ;;

        nvidia-open)
            log "Установка NVIDIA Open..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                nvidia-open nvidia-utils nvidia-settings \
                lib32-nvidia-utils \
                $vulkan_pkgs \
                --needed &>/dev/null || warn "Ошибка установки NVIDIA Open"

            local nvidia_conf="${mount_point}/etc/modprobe.d/nvidia.conf"
            cat > "$nvidia_conf" << 'NVEOF'
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
NVEOF
            log "NVIDIA Open DRM modeset включён"
            ;;

        nvidia-dkms)
            log "Установка NVIDIA DKMS..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                nvidia-dkms nvidia-utils nvidia-settings \
                lib32-nvidia-utils \
                $vulkan_pkgs \
                --needed &>/dev/null || warn "Ошибка установки NVIDIA DKMS"
            ;;

        nvidia-lts)
            log "Установка NVIDIA LTS..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                nvidia-lts nvidia-utils nvidia-settings \
                lib32-nvidia-utils \
                $vulkan_pkgs \
                --needed &>/dev/null || warn "Ошибка установки NVIDIA LTS"
            ;;

        nouveau)
            log "Установка nouveau..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                xf86-video-nouveau \
                $mesa_pkgs \
                $vulkan_pkgs \
                --needed &>/dev/null || warn "Ошибка установки nouveau"
            ;;

        amdgpu)
            log "Установка AMD драйверов..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                xf86-video-amdgpu \
                $mesa_pkgs \
                vulkan-radeon lib32-vulkan-radeon \
                $vulkan_pkgs \
                --needed &>/dev/null || warn "Ошибка установки AMD драйверов"
            ;;

        amd-pro)
            log "Установка AMDGPU-PRO из AUR..."
            # Требует установки paru/yay
            warn "AMDGPU-PRO в AUR, устанавливается после paru"
            # Помечаем для установки позже
            EXTRA_AUR_PKGS="${EXTRA_AUR_PKGS:-} amdpro"
            ;;

        intel)
            log "Установка Intel драйверов..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                xf86-video-intel \
                $mesa_pkgs \
                vulkan-intel lib32-vulkan-intel \
                $vulkan_pkgs \
                intel-media-driver \
                --needed &>/dev/null || warn "Ошибка установки Intel драйверов"
            ;;

        intel-compute)
            log "Установка Intel compute stack..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                xf86-video-intel \
                $mesa_pkgs \
                vulkan-intel lib32-vulkan-intel \
                intel-media-driver intel-compute-runtime \
                intel-opencl-clang \
                --needed &>/dev/null || warn "Ошибка установки Intel compute"
            ;;

        virtio)
            log "Установка драйверов для виртуализации..."
            arch-chroot "$mount_point" pacman -S --noconfirm \
                xf86-video-vmware \
                $mesa_pkgs \
                $vulkan_pkgs \
                --needed &>/dev/null || warn "Ошибка установки VM драйверов"
            ;;
    esac

    log "GPU драйвер установлен: $SELECTED_GPU"
}

# ═══════════════════════════════════════════════════════════
# 13. УСТАНОВКА РАБОЧЕГО СТОЛА
# ═══════════════════════════════════════════════════════════

install_desktop() {
    title "Установка рабочего стола"

    if [[ "$SELECTED_DE" == "none" ]]; then
        log "Пропускаем установку рабочего стола (консольный режим)"
        return
    fi

    local mount_point="/mnt"
    local de_pkgs=""
    local dm_service=""

    # Аудио — всегда ставим PipeWire
    local audio_pkgs="pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils"

    # Шрифты
    local font_pkgs="ttf-font-awesome ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji"

    # Xorg — нужен для некоторых DE
    local xorg_pkgs="xorg-server xorg-xinit xorg-xrandr xdg-utils"

    # Wayland — базовые утилиты
    local wayland_pkgs="wayland wayland-utils"

    chaldo_work "Устанавливаю $SELECTED_DE... это может занять время!"

    case "$SELECTED_DE" in
        kde)
            de_pkgs="plasma-meta kde-applications-meta sddm konsole dolphin kate gwenview"
            dm_service="sddm"
            ;;

        gnome)
            de_pkgs="gnome gnome-extra gdm gnome-tweaks"
            dm_service="gdm"
            ;;

        xfce)
            de_pkgs="xfce4 xfce4-goodies lightdm lightdm-gtk-greeter mousepad ristretto"
            dm_service="lightdm"
            ;;

        hyprland)
            de_pkgs="hyprland waybar rofi dunst kitty swaylock-effects swayidle hyprpaper hyprpicker wl-clipboard"
            de_pkgs+=" xdg-desktop-portal-hyprland polkit-kde-agent"
            dm_service="sddm"
            ;;

        sway)
            de_pkgs="sway waybar rofi swaylock swayidle foot mako wl-clipboard xdg-desktop-portal-wlr"
            dm_service="sddm"
            ;;

        budgie)
            de_pkgs="budgie-desktop lightdm lightdm-gtk-greeter gnome-terminal nautilus"
            dm_service="lightdm"
            ;;

        cinnamon)
            de_pkgs="cinnamon lightdm lightdm-gtk-greeter gnome-terminal nemo"
            dm_service="lightdm"
            ;;

        mate)
            de_pkgs="mate mate-extra lightdm lightdm-gtk-greeter pluma"
            dm_service="lightdm"
            ;;

        i3)
            de_pkgs="i3-wm i3status i3lock dmenu rofi xterm picom feh dunst"
            dm_service="lightdm"
            ;;
    esac

    # Пользовательский DM, если выбран
    if [[ -n "${SELECTED_DM:-}" ]] && [[ "$SELECTED_DM" != "none" ]]; then
        dm_service="${SELECTED_DM}"
    fi

    # Собираем полный список пакетов
    local all_pkgs="$de_pkgs"
    # Xorg только для X11-based DE
    case "$SELECTED_DE" in
        kde|xfce|budgie|cinnamon|mate|i3)
            all_pkgs="$all_pkgs $xorg_pkgs $font_pkgs"
            ;;
        gnome)
            all_pkgs="$all_pkgs $font_pkgs"  # GNOME использует Wayland по умолчанию
            ;;
        hyprland|sway)
            all_pkgs="$all_pkgs $wayland_pkgs $font_pkgs"
            ;;
    esac

    # Добавляем PipeWire
    all_pkgs="$all_pkgs $audio_pkgs"

    # Установка
    arch-chroot "$mount_point" pacman -S --noconfirm $all_pkgs --needed &>/dev/null || {
        warn "Некоторые пакеты не установились. Попробую ещё раз..."
        arch-chroot "$mount_point" pacman -S --noconfirm $de_pkgs $xorg_pkgs $audio_pkgs $font_pkgs --needed &>/dev/null || \
            warn "Ошибка установки DE (возможно проблемы с зеркалами)"
    }

    # Включаем DM
    if [[ -n "$dm_service" ]]; then
        arch-chroot "$mount_point" systemctl enable "$dm_service" &>/dev/null || true
        log "DM '$dm_service' добавлен в автозагрузку"
    fi

    log "Рабочий стол $SELECTED_DE установлен!"
}

# ═══════════════════════════════════════════════════════════
# 14. УСТАНОВКА ИГРОВОГО СОФТА
# ═══════════════════════════════════════════════════════════

install_gaming() {
    if [[ ${#SELECTED_GAMING[@]} -eq 0 ]]; then
        return
    fi

    title "Установка игрового софта 🎮"

    local mount_point="/mnt"
    local gaming_pkgs=""

    chaldo_work "Накатываю игровой софт!"

    # Если "ALL" — устанавливаем всё
    if [[ "${SELECTED_GAMING[0]}" == "ALL" ]]; then
        gaming_pkgs="steam lutris heroic-games-launcher-bin obs-studio"
        gaming_pkgs+=" mangohud goverlay"
        gaming_pkgs+=" wine wine-staging winetricks"
        gaming_pkgs+=" gamescope gamemode lib32-gamemode"
        gaming_pkgs+=" discord"
        gaming_pkgs+=" prismlauncher"
        gaming_pkgs+=" vulkan-icd-loader lib32-vulkan-icd-loader"
        # AUR пакеты (установим отдельно)
        EXTRA_AUR_PKGS="${EXTRA_AUR_PKGS:-} proton-ge-custom-bin"
    else
        for pkg in "${SELECTED_GAMING[@]}"; do
            case "$pkg" in
                steam)     gaming_pkgs="$gaming_pkgs steam" ;;
                lutris)    gaming_pkgs="$gaming_pkgs lutris" ;;
                heroic)    gaming_pkgs="$gaming_pkgs heroic-games-launcher-bin" ;;
                obs)       gaming_pkgs="$gaming_pkgs obs-studio" ;;
                mangohud)  gaming_pkgs="$gaming_pkgs mangohud goverlay" ;;
                wine)      gaming_pkgs="$gaming_pkgs wine wine-staging winetricks" ;;
                proton-ge) EXTRA_AUR_PKGS="${EXTRA_AUR_PKGS:-} proton-ge-custom-bin" ;;
                gamescope) gaming_pkgs="$gaming_pkgs gamescope" ;;
                gamemode)  gaming_pkgs="$gaming_pkgs gamemode lib32-gamemode" ;;
                discord)   gaming_pkgs="$gaming_pkgs discord" ;;
                prism)     gaming_pkgs="$gaming_pkgs prismlauncher" ;;
                vulkan)    gaming_pkgs="$gaming_pkgs vulkan-icd-loader lib32-vulkan-icd-loader" ;;
            esac
        done
    fi

    # Установка
    if [[ -n "$gaming_pkgs" ]]; then
        log "Устанавливаю пакеты: $gaming_pkgs"
        arch-chroot "$mount_point" pacman -S --noconfirm $gaming_pkgs --needed 2>/dev/null || \
            warn "Некоторые игровые пакеты не установились."
    fi

    # Дополнительные настройки
    # GameMode — автозапуск
    if echo "$gaming_pkgs" | grep -q "gamemode"; then
        arch-chroot "$mount_point" systemctl enable gamemoded &>/dev/null || true
        log "GameMode включён"
    fi

    # Добавляем пользователя в группу gamemode
    arch-chroot "$mount_point" usermod -aG gamemode "$USERNAME" 2>/dev/null || true

    # Steam — права на 32-bit
    arch-chroot "$mount_point" usermod -aG games "$USERNAME" 2>/dev/null || true

    log "Игровой софт установлен!"
}

# ═══════════════════════════════════════════════════════════
# 15. УСТАНОВКА AUR-ХЕЛПЕРА И AUR ПАКЕТОВ
# ═══════════════════════════════════════════════════════════

install_aur() {
    local mount_point="/mnt"

    # Проверяем, нужен ли AUR
    if [[ "${SELECTED_AUR:-false}" != "true" ]] && [[ -z "${EXTRA_AUR_PKGS:-}" ]]; then
        return
    fi

    title "Установка AUR пакетов"

    chaldo_work "Устанавливаю paru (AUR helper)..."

    # Устанавливаем paru в chroot
    arch-chroot "$mount_point" /bin/bash << 'AURSETUP'
    # Устанавливаем зависимости для сборки
    pacman -S --noconfirm --needed git base-devel &>/dev/null || true

    # Создаем временного пользователя для сборки (нельзя собирать AUR от root)
    if ! id builduser &>/dev/null; then
        useradd -m builduser
        echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/builduser
    fi

    # Устанавливаем paru
    if ! command -v paru &>/dev/null; then
        cd /tmp
        git clone https://aur.archlinux.org/paru.git &>/dev/null || true
        cd paru
        chown -R builduser:builduser /tmp/paru
        sudo -u builduser makepkg -si --noconfirm &>/dev/null || true
        cd /
        rm -rf /tmp/paru
    fi

    # Настройка paru
    if [[ -f /etc/paru.conf ]]; then
        sed -i 's/#BottomUp/BottomUp/' /etc/paru.conf
    fi

    # Удаляем builduser
    userdel -r builduser 2>/dev/null || true
    rm -f /etc/sudoers.d/builduser
AURSETUP

    if arch-chroot "$mount_point" command -v paru &>/dev/null; then
        log "Paru установлен!"
    else
        warn "Paru не установился. AUR пакеты не будут загружены."
        return
    fi

    # Устанавливаем AUR пакеты, если есть
    if [[ -n "${EXTRA_AUR_PKGS:-}" ]]; then
        chaldo_work "Устанавливаю AUR пакеты: $EXTRA_AUR_PKGS"
        arch-chroot "$mount_point" /bin/bash -c "paru -S --noconfirm $EXTRA_AUR_PKGS" 2>/dev/null || \
            warn "Некоторые AUR пакеты не установились."
    fi

    log "AUR пакеты обработаны"
}

# ═══════════════════════════════════════════════════════════
# 16. УСТАНОВКА DaVinci Resolve
# ═══════════════════════════════════════════════════════════

install_davinci() {
    if [[ "$INSTALL_DAVINCI" == "false" ]]; then
        return
    fi

    title "Установка DaVinci Resolve 🎬"

    local mount_point="/mnt"

    case "$INSTALL_DAVINCI" in
        studio)
            chaldo_work "Устанавливаю DaVinci Resolve Studio из AUR..."
            arch-chroot "$mount_point" /bin/bash -c "
                if command -v paru &>/dev/null; then
                    paru -S --noconfirm davinci-resolve-studio 2>/dev/null || \
                    paru -S --noconfirm davinci-resolve 2>/dev/null || \
                    echo 'DaVinci не найден в AUR'
                fi
            " || warn "Ошибка установки DaVinci Resolve Studio"
            ;;

        free)
            chaldo_work "Устанавливаю DaVinci Resolve (Free) из AUR..."
            arch-chroot "$mount_point" /bin/bash -c "
                if command -v paru &>/dev/null; then
                    paru -S --noconfirm davinci-resolve 2>/dev/null || \
                    echo 'DaVinci Resolve не найден в AUR'
                fi
            " || warn "Ошибка установки DaVinci Resolve"
            ;;

        manual)
            chaldo_say "Сейчас я помогу установить DaVinci Resolve вручную!" "work"
            echo ""
            echo "  1. Скачай DaVinci Resolve Studio с официального сайта:"
            echo "     https://www.blackmagicdesign.com/products/davinciresolve"
            echo ""
            echo "  2. Сохрани архив (DaVinci_Resolve_Studio_*.zip) на флешку"
            echo ""
            prompt "Путь к архиву на флешке (или Enter чтобы пропустить): "; read dv_archive

            if [[ -f "$dv_archive" ]]; then
                log "Архив найден!"
                cp "$dv_archive" "${mount_point}/tmp/"
                local archive_name=$(basename "$dv_archive")

                arch-chroot "$mount_point" /bin/bash << DVSETUP
                cd /tmp
                mkdir -p davinci_install
                unzip -q "${archive_name}" -d davinci_install 2>/dev/null || {
                    echo "Ошибка распаковки. Возможно архив повреждён."
                    exit 1
                }
                cd davinci_install
                chmod +x DaVinci_Resolve_Studio*.run 2>/dev/null || true
                echo "DaVinci Resolve готов к установке."
                echo "Запусти: sudo ./DaVinci_Resolve_Studio*.run"
DVSETUP
                log "DaVinci Resolve подготовлен! После загрузки запусти установку."
            else
                warn "Архив не найден. Установи DaVinci Resolve вручную после загрузки."
            fi
            ;;
    esac

    # Создаём скрипт для установки DaVinci Resolve после первой загрузки
    if [[ "$INSTALL_DAVINCI" != "false" ]]; then
        cat > "${mount_point}/home/${USERNAME}/install-davinci.sh" << 'DVSCRIPT'
#!/bin/bash
# ChaldOS — DaVinci Resolve Installer Helper
# Запусти этот скрипт для установки/доустановки DaVinci Resolve
echo "=== DaVinci Resolve Installer ==="
echo ""

# Проверка наличия
if command -v davinci-resolve &>/dev/null; then
    echo "✓ DaVinci Resolve уже установлен!"
    echo "  Запуск: davinci-resolve"
    exit 0
fi

echo "Установка через paru (AUR)..."
sudo paru -S davinci-resolve-studio 2>/dev/null || \
sudo paru -S davinci-resolve 2>/dev/null || \
echo "Попробуй установить вручную с сайта Blackmagic Design."

echo ""
echo "Если у тебя есть архив DaVinci Resolve (.zip/.run):"
echo "  sudo /tmp/davinci_install/DaVinci_Resolve_Studio*.run"
DVSCRIPT
        chmod +x "${mount_point}/home/${USERNAME}/install-davinci.sh"
        log "Скрипт install-davinci.sh создан в домашней папке"
    fi
}

# ═══════════════════════════════════════════════════════════
# 17. УСТАНОВКА ШЕЛЛА
# ═══════════════════════════════════════════════════════════

install_shell() {
    local mount_point="/mnt"

    if [[ "$SELECTED_SHELL" == "bash" ]]; then
        return
    fi

    title "Установка оболочки"

    case "$SELECTED_SHELL" in
        zsh)
            arch-chroot "$mount_point" pacman -S --noconfirm zsh zsh-completions --needed &>/dev/null || true
            arch-chroot "$mount_point" chsh -s /bin/zsh "$USERNAME" &>/dev/null || true
            arch-chroot "$mount_point" chsh -s /bin/zsh root &>/dev/null || true

            # Oh My Zsh
            arch-chroot "$mount_point" /bin/bash -c "
                curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh &>/dev/null || true
                git clone https://github.com/zsh-users/zsh-syntax-highlighting /home/${USERNAME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting &>/dev/null || true
                git clone https://github.com/zsh-users/zsh-autosuggestions /home/${USERNAME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions &>/dev/null || true
                chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.oh-my-zsh 2>/dev/null || true
            " &>/dev/null || true
            log "ZSH + Oh My Zsh установлен"
            ;;

        fish)
            arch-chroot "$mount_point" pacman -S --noconfirm fish --needed &>/dev/null || true
            arch-chroot "$mount_point" chsh -s /bin/fish "$USERNAME" &>/dev/null || true
            log "Fish shell установлен"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════
# 18. ДОПОЛНИТЕЛЬНЫЕ ПАКЕТЫ
# ═══════════════════════════════════════════════════════════

install_extra_packages() {
    if [[ -z "${EXTRA_PACKAGES:-}" ]]; then
        return
    fi

    title "Установка дополнительных пакетов"

    local mount_point="/mnt"

    chaldo_work "Устанавливаю: $EXTRA_PACKAGES"
    arch-chroot "$mount_point" pacman -S --noconfirm --needed $EXTRA_PACKAGES 2>/dev/null || \
        warn "Некоторые доп. пакеты не установились."
    log "Доп. пакеты установлены"
}

# ═══════════════════════════════════════════════════════════
# 19. УСТАНОВКА ЗАГРУЗЧИКА
# ═══════════════════════════════════════════════════════════

install_bootloader() {
    title "Установка загрузчика"

    local mount_point="/mnt"

    chaldo_work "Устанавливаю загрузчик..."

    # Установка GRUB
    arch-chroot "$mount_point" pacman -S --noconfirm grub --needed &>/dev/null || true

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        arch-chroot "$mount_point" pacman -S --noconfirm efibootmgr --needed &>/dev/null || true
        arch-chroot "$mount_point" grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ChaldOS --recheck &>/dev/null || {
            warn "Не удалось установить GRUB UEFI. Попробую альтернативный способ..."
            arch-chroot "$mount_point" grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ChaldOS &>/dev/null || \
                warn "GRUB UEFI не установился. Нужно будет установить вручную."
        }
    else
        arch-chroot "$mount_point" grub-install --target=i386-pc "$TARGET_DISK" --recheck &>/dev/null || {
            warn "Не удалось установить GRUB BIOS."
        }
    fi

    # Настройка GRUB
    # Добавляем параметры для NVIDIA если нужно
    local grub_cmdline="quiet splash"
    if [[ "$SELECTED_GPU" == nvidia* ]]; then
        grub_cmdline="$grub_cmdline nvidia-drm.modeset=1"
    fi

    sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/GRUB_CMDLINE_LINUX_DEFAULT=\"${grub_cmdline}/" "${mount_point}/etc/default/grub" 2>/dev/null || true

    # GRUB тема для ChaldOS
    cat > "${mount_point}/etc/default/grub" << 'GRUBCONF'
# ChaldOS GRUB Configuration
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR="ChaldOS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=1920x1080,auto
GRUB_DISABLE_RECOVERY=true
GRUB_ENABLE_BLSCFG=false
GRUBCONF

    arch-chroot "$mount_point" grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null || \
        warn "GRUB mkconfig не удался"

    log "Загрузчик установлен!"
}

# ═══════════════════════════════════════════════════════════
# 20. ФИНИШ
# ═══════════════════════════════════════════════════════════

finish_install() {
    title "Завершение установки"

    local mount_point="/mnt"

    # Копируем маскот в систему
    mkdir -p "${mount_point}/usr/local/bin"
    if [[ -f "${SCRIPT_DIR}/mascot.sh" ]]; then
        cp "${SCRIPT_DIR}/mascot.sh" "${mount_point}/usr/local/bin/chaldos-mascot"
        chmod 755 "${mount_point}/usr/local/bin/chaldos-mascot"

        # Создаём ссылку
        cat > "${mount_point}/usr/local/bin/chaldos-mascot" << 'MASCOTCMD'
#!/bin/bash
# ChaldOS Mascot — запуск из установленной системы
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASCOT_FILE="${SCRIPT_DIR}/mascot.sh"

# Пытаемся найти mascot.sh
for loc in /usr/local/bin/mascot.sh /etc/chaldos/mascot.sh /usr/share/chaldos/mascot.sh; do
    if [[ -f "$loc" ]]; then
        source "$loc"
        chaldo_say "Привет! Я Чалдо — твой цифровой помощник! Чем могу помочь? 🎮" "love"
        exit 0
    fi
done

# Встроенная версия если файл не найден
echo ""
echo "    ╔═══════════════╗"
echo "    ║  ◉      ◉    ║"
echo "    ║     ❤       ║"
echo "    ║    ╱──╲     ║"
echo "    ╚═══════════════╝"
echo ""
echo "  Привет! Я Чалдо — твой цифровой помощник!"
echo "  Добро пожаловать в ChaldOS Gaming Edition! 🎮"
echo ""
MASCOTCMD
        chmod 755 "${mount_point}/usr/local/bin/chaldos-mascot"

        # Копируем сам файл маскота
        cp "${SCRIPT_DIR}/mascot.sh" "${mount_point}/etc/chaldos/mascot.sh"
    fi

    # Чистим кэш pacman
    arch-chroot "$mount_point" pacman -Scc --noconfirm &>/dev/null || true

    # Размонтируем
    chaldo_work "Размонтирую разделы..."
    sync
    sleep 1

    if [[ -n "$SWAP_PART" ]]; then
        swapoff "$SWAP_PART" 2>/dev/null || true
    fi

    umount -R "$mount_point" 2>/dev/null || true

    # Показываем финальный экран
    clear
    chaldo_welcome
    chaldo_goodbye

    echo ""
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║         УСТАНОВКА ЗАВЕРШЕНА! 🎉              ║"
    echo "  ╠═══════════════════════════════════════════════╣"
    printf "  ║  Система:    ChaldOS ${VERSION} ${CHALDOS_CODENAME}  ║\n"
    printf "  ║  Рабочий стол: %-30s  ║\n" "$(echo "${DE_INFO[$SELECTED_DE]%%|*}")"
    printf "  ║  GPU:        %-30s  ║\n" "$SELECTED_GPU"
    printf "  ║  Пользователь: %-30s  ║\n" "$USERNAME"
    echo "  ║                                           ║"
    echo "  ║  Извлеки установочную флешку и перезагрузи! ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""

    prompt "Перезагрузить сейчас? (Y/n): "; read reboot_now
    if [[ ! "${reboot_now:-y}" =~ ^[Nn] ]]; then
        log "Перезагрузка..."
        reboot
    else
        echo ""
        log "Не забудь перезагрузиться потом!"
        echo "  # reboot"
    fi
}

# ═══════════════════════════════════════════════════════════
# ОСНОВНОЙ УСТАНОВЩИК
# ═══════════════════════════════════════════════════════════

main_installer() {
    # Сброс для повторной установки
    :
}

main() {
    # Приветствие
    clear
    chaldo_welcome

    # Проверки
    check_environment

    # Интерактивные шаги
    select_keyboard
    select_disk
    select_install_type
    partition_disk
    select_desktop
    select_gpu
    select_gaming
    select_davinci
    select_extra

    # Сводка
    show_summary

    # Установка
    install_base
    configure_system
    install_gpu_drivers
    install_desktop
    install_gaming
    install_aur
    install_davinci
    install_shell
    install_extra_packages
    install_bootloader

    # Финиш
    finish_install
}

# ─── Запуск ───────────────────────────────────────────────
if [[ "${1:-}" = "--help" ]] || [[ "${1:-}" = "-h" ]]; then
    echo "ChaldOS Installer v${VERSION} — Arch Linux Gaming Edition"
    echo ""
    echo "Использование:"
    echo "  sudo ./install-chaldos.sh              Интерактивный режим"
    echo ""
    echo "Загрузитесь с Arch Linux ISO и запустите этот скрипт."
    echo "Установщик сам скачает всё необходимое."
    echo ""
    echo "Требования:"
    echo "  • Arch Linux Live CD"
    echo "  • Интернет"
    echo "  • Минимум 20 ГБ на диске"
    echo "  • 2 ГБ RAM (рекомендуется 4 ГБ+)"
    echo ""
    echo "ChaldOS — Gaming Edition для настоящих геймеров! 🎮"
    exit 0
fi

# Запуск
main "$@"
