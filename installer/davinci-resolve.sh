#!/bin/bash
# ChaldOS — DaVinci Resolve Studio Installer
# =============================================
# Автоматическая установка DaVinci Resolve (Studio/Free)
# Скачивает архив с сайта Blackmagic Design, устанавливает
# зависимости и запускает установщик.
#
# Использование:
#   sudo ./davinci-resolve.sh                    # Интерактивный режим
#   sudo ./davinci-resolve.sh --studio           # Установить Studio версию
#   sudo ./davinci-resolve.sh --free             # Установить Free версию
#   sudo ./davinci-resolve.sh --help             # Помощь
#
# DaVinci Resolve Studio — профессиональный видеоредактор
# и инструмент цветокоррекции от Blackmagic Design.
# =============================================

set -euo pipefail

# ─── Цвета ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
header() { echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}\n"; }

# ─── Маскот (если доступен) ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "${SCRIPT_DIR}/mascot.sh" ]]; then
    source "${SCRIPT_DIR}/mascot.sh"
else
    chaldo_say()   { echo -e "${MAGENTA}🤖 ${1}${NC}"; }
    chaldo_work()  { echo -e "${MAGENTA}🔧 ${1}${NC}"; }
    chaldo_warn()  { echo -e "${MAGENTA}⚠️  ${1}${NC}"; }
    chaldo_dance() { echo -e "${MAGENTA}🎉 ${1}${NC}"; }
fi

# ─── Конфигурация ─────────────────────────────────────────
DAVINCI_VERSION=""
DAVINCI_TYPE="studio"  # studio или free
INSTALL_DIR="/opt/resolve"
DOWNLOAD_DIR="/tmp/davinci-download"
WORK_DIR="/tmp/davinci-install"

# DaVinci Resolve официальный URL
# (актуальные ссылки проверяются на сайте Blackmagic Design)
DAVINCI_URL_STUDIO="https://www.blackmagicdesign.com/api/register/us/download/davinci-resolve-studio"
DAVINCI_URL_FREE="https://www.blackmagicdesign.com/api/register/us/download/davinci-resolve"

# AUR пакеты
AUR_PACKAGES_STUDIO="davinci-resolve-studio"
AUR_PACKAGES_FREE="davinci-resolve"

# ─── Проверка ─────────────────────────────────────────────

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Запусти с sudo! Требуются root-права."
    fi
}

check_arch() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" != "x86_64" ]]; then
        error "DaVinci Resolve работает только на x86_64! Твоя архитектура: $arch"
    fi
    log "Архитектура: $arch"
}

check_deps() {
    local deps=(curl wget unzip tar pacman)
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Команда '$cmd' не найдена. Установи: sudo pacman -S $cmd"
        fi
    done
    log "Зависимости найдены"
}

check_system() {
    # Проверка на ChaldOS / Arch
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" != "chaldos" ]] && [[ "$ID" != "arch" ]]; then
            warn "Похоже, система не Arch/ChaldOS. DaVinci может не установиться."
            prompt "Продолжить? (y/N): "; read confirm
            [[ "$confirm" =~ ^[Yy] ]] || exit 0
        fi
        log "Система: ${PRETTY_NAME:-$ID}"
    fi

    # Проверка GPU (для DaVinci нужна хорошая видеокарта)
    if command -v lspci &>/dev/null; then
        local gpu_info
        gpu_info=$(lspci | grep -E 'VGA|3D|Display' 2>/dev/null || true)
        if [[ -n "$gpu_info" ]]; then
            log "Обнаружено GPU: $gpu_info"
        fi
    fi

    # Рекомендации по RAM
    local total_ram_kb
    total_ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
    local total_ram_gb=$((total_ram_kb / 1024 / 1024))
    if [[ $total_ram_gb -lt 8 ]]; then
        warn "У тебя ${total_ram_gb}ГБ RAM. DaVinci Resolve рекомендуется от 16ГБ!"
    else
        log "RAM: ${total_ram_gb}ГБ 👍"
    fi
}

# ─── Установка через AUR (paru) ──────────────────────────

install_aur_helper() {
    # Проверяем, установлен ли paru/yay
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
        log "Paru уже установлен!"
        return 0
    fi

    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
        log "Yay уже установлен!"
        return 0
    fi

    log "Устанавливаю paru (AUR helper)..."

    # Устанавливаем зависимости для сборки
    pacman -S --noconfirm --needed git base-devel &>/dev/null || {
        error "Не удалось установить зависимости для сборки."
    }

    # Создаём builduser
    if ! id builduser &>/dev/null; then
        useradd -m builduser
        echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/builduser
    fi

    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git &>/dev/null || {
        error "Не удалось склонировать paru из AUR"
    }
    cd paru
    chown -R builduser:builduser /tmp/paru
    sudo -u builduser makepkg -si --noconfirm &>/dev/null || {
        # Пробуем yay как альтернативу
        cd /tmp
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git &>/dev/null || {
            userdel -r builduser 2>/dev/null || true
            error "Не удалось установить AUR helper."
        }
        cd yay
        chown -R builduser:builduser /tmp/yay
        sudo -u builduser makepkg -si --noconfirm &>/dev/null || {
            userdel -r builduser 2>/dev/null || true
            error "Не удалось установить paru или yay."
        }
        AUR_HELPER="yay"
    }

    AUR_HELPER="${AUR_HELPER:-paru}"
    userdel -r builduser 2>/dev/null || true
    rm -f /etc/sudoers.d/builduser
    cd /
    rm -rf /tmp/paru /tmp/yay

    log "${AUR_HELPER} установлен!"
}

install_davinci_aur() {
    local pkg_name="$1"  # davinci-resolve-studio или davinci-resolve

    log "Устанавливаю $pkg_name из AUR..."

    # Обновляем систему
    pacman -Sy --noconfirm &>/dev/null || true

    # Устанавливаем через AUR helper
    # DaVinci Resolve требует мультибиблиотеки
    if ! grep -q '^\[multilib\]' /etc/pacman.conf 2>/dev/null; then
        echo "" >> /etc/pacman.conf
        echo "[multilib]" >> /etc/pacman.conf
        echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
        pacman -Sy --noconfirm &>/dev/null || true
    fi

    # Установка
    ${AUR_HELPER} -S --noconfirm "$pkg_name" 2>/dev/null || {
        warn "Установка через AUR не удалась."
        return 1
    }

    log "DaVinci Resolve установлен через AUR!"
    return 0
}

# ─── Ручная установка (скачать и установить) ──────────────

install_davinci_manual() {
    local version_type="$1"

    header "DaVinci Resolve — Ручная установка"

    chaldo_say "Сейчас установим DaVinci Resolve вручную!"
    echo ""
    echo "  Способ 1 — Авто-загрузка с сайта Blackmagic Design"
    echo "  Способ 2 — У меня уже есть архив (.zip)"
    echo "  Способ 3 — Я скачаю позже сам"
    echo ""
    read -p "  Выбери способ (1-3) [1]: " method

    case "${method:-1}" in
        1|2) ;;
        *)
            warn "Установка отложена. Запусти install-davinci.sh позже."
            return 0
            ;;
    esac

    if [[ "${method:-1}" == "1" ]]; then
        download_from_blackmagic "$version_type"
    else
        use_local_archive
    fi
}

download_from_blackmagic() {
    local version_type="$1"

    echo ""
    echo "  ╔═══════════════════════════════════════════════════╗"
    echo "  ║     DaVinci Resolve — Загрузка с сайта           ║"
    echo "  ╚═══════════════════════════════════════════════════╝"
    echo ""
    echo "  Для загрузки нужен аккаунт Blackmagic Design."
    echo "  Зарегистрируйся: https://www.blackmagicdesign.com/"
    echo ""
    echo "  После регистрации, скачай архив:"
    echo ""
    if [[ "$version_type" == "studio" ]]; then
        echo "  📥 DaVinci Resolve Studio:"
        echo "     https://www.blackmagicdesign.com/products/davinciresolve"
    else
        echo "  📥 DaVinci Resolve (Free):"
        echo "     https://www.blackmagicdesign.com/products/davinciresolve"
    fi
    echo ""
    echo "  Сохрани .zip файл на диск и выбери способ 2."
    echo ""

    read -p "  Нажми Enter чтобы продолжить..."

    use_local_archive
}

use_local_archive() {
    echo ""
    echo "  Укажи путь к архиву DaVinci Resolve (.zip):"
    echo "  (можно перетащить файл в терминал)"
    echo ""
    read -p "  Путь к архиву: " archive_path

    # Убираем кавычки если пользователь перетащил файл
    archive_path="${archive_path%\'}"
    archive_path="${archive_path#\'}"
    archive_path="${archive_path%\"}"
    archive_path="${archive_path#\"}"

    if [[ ! -f "$archive_path" ]]; then
        warn "Файл '$archive_path' не найден."
        read -p "  Попробовать другой путь? (Y/n): " retry
        if [[ ! "${retry:-y}" =~ ^[Nn] ]]; then
            use_local_archive
        else
            return 1
        fi
    fi

    log "Архиф найден: $(basename "$archive_path") ($(du -h "$archive_path" | cut -f1))"

    # Создаём рабочую директорию
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"

    echo ""
    log "Распаковываю архив..."
    echo "  Это может занять несколько минут..."

    if ! unzip -q "$archive_path" -d "$WORK_DIR" 2>/dev/null; then
        warn "Ошибка распаковки. Может быть это не zip?"
        # Пробуем как .run файл напрямую
        if [[ "$archive_path" == *.run ]]; then
            log "Похоже на .run файл, копирую напрямую..."
            cp "$archive_path" "$WORK_DIR/"
        else
            error "Не удалось распаковать архив."
        fi
    fi

    echo ""
    log "Файлы распакованы. Ищу установщик..."

    # Ищем .run файл
    local run_file
    run_file=$(find "$WORK_DIR" -name '*.run' -type f 2>/dev/null | head -1)

    if [[ -z "$run_file" ]]; then
        error "Не найден установщик (.run) в архиве."
    fi

    log "Найден установщик: $(basename "$run_file")"

    # Устанавливаем зависимости
    echo ""
    log "Устанавливаю зависимости..."
    pacman -S --noconfirm --needed \
        alsa-lib libgl libpulse \
        gst-plugins-base-libs gst-plugins-good \
        libxv libxmu libxinerama libxcb \
        libxkbcommon libsm libice \
        ocl-icd opencl-headers \
        desktop-file-utils shared-mime-info \
        &>/dev/null || warn "Некоторые зависимости не установились"

    # Запускаем установщик
    echo ""
    log "Готово! Запускаю установщик DaVinci Resolve..."
    echo ""
    echo "  ⚠️  Установщик графический. Следуй инструкциям на экране."
    echo "  📁 Папка установки: /opt/resolve"
    echo ""
    read -p "  Нажми Enter чтобы запустить установщик..."

    chmod +x "$run_file"

    # Запускаем установщик (может быть GUI)
    if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        # Есть графический режим
        "$run_file" -i || {
            warn "Графический установщик не запустился."
            echo "Попробуй запустить вручную:"
            echo "  sudo $run_file -i"
        }
    else
        # Нет графики — запускаем в терминале
        warn "Нет графического режима. Запускаю в терминале..."
        "$run_file" -i -noprogress 2>&1 || {
            warn "Установщик не запустился."
            echo "Запусти потом вручную:"
            echo "  sudo $run_file -i"
            echo "  Или следуй инструкции на экране."
        }
    fi

    # Чистим за собой
    rm -rf "$WORK_DIR" &>/dev/null || true

    # Проверяем установку
    if [[ -f "/opt/resolve/bin/resolve" ]]; then
        chaldo_dance "DaVinci Resolve установлен! 🎬🎉"
        echo ""
        echo "  Запуск:"
        echo "    resolvere (как пользователь, не root!)"
        echo ""
        echo "  Или найди DaVinci Resolve в меню приложений."
    else
        warn "DaVinci Resolve не найден в /opt/resolve."
        echo "Возможно установка не завершилась."
        echo "Попробуй запустить установщик вручную."
    fi
}

# ─── Создание скрипта запуска ─────────────────────────────

create_launcher() {
    cat > /usr/local/bin/resolvere << 'LAUNCHER'
#!/bin/bash
# ChaldOS — DaVinci Resolve Launcher
# Запускает DaVinci Resolve с правильными настройками

# Путь к DaVinci Resolve
RESOLVE="/opt/resolve/bin/resolve"

if [[ ! -f "$RESOLVE" ]]; then
    echo "DaVinci Resolve не найден в /opt/resolve"
    echo "Установи: sudo ./davinci-resolve.sh"
    exit 1
fi

# Проверка — не root ли?
if [[ $EUID -eq 0 ]]; then
    echo "⚠️  Не запускай DaVinci Resolve от root!"
    echo "Запусти как обычный пользователь."
    exit 1
fi

# Настройки окружения
export LD_LIBRARY_PATH="/opt/resolve/libs:$LD_LIBRARY_PATH"
export RESOLVE_INSTALL_DIR="/opt/resolve"

# Определение GPU для OpenCL
if lspci 2>/dev/null | grep -qi nvidia; then
    export DISPLAY_DRIVER="nvidia"
elif lspci 2>/dev/null | grep -qi amd; then
    export DISPLAY_DRIVER="amd"
fi

echo "🚀 Запуск DaVinci Resolve..."
echo "   GPU: ${DISPLAY_DRIVER:-автоопределение}"
echo ""
exec "$RESOLVE" "$@"
LAUNCHER
    chmod 755 /usr/local/bin/resolvere
    log "Скрипт запуска создан: resolvere"
}

# ─── Создание файла .desktop ──────────────────────────────

create_desktop_file() {
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/davinci-resolve.desktop << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=DaVinci Resolve
Comment=Professional video editing and color correction
Exec=/opt/resolve/bin/resolve
Icon=/opt/resolve/ResolveIcon.png
Terminal=false
Categories=AudioVideo;Video;Graphics;
StartupNotify=true
MimeType=application/x-resolveproject;
DESKTOP
    log "Файл .desktop создан"
}

# ═══════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════

main() {
    # Парсинг аргументов
    local method=""

    for arg in "$@"; do
        case "$arg" in
            --studio)   DAVINCI_TYPE="studio" ;;
            --free)     DAVINCI_TYPE="free" ;;
            --aur)      method="aur" ;;
            --manual)   method="manual" ;;
            --help|-h)
                echo "DaVinci Resolve Installer для ChaldOS"
                echo ""
                echo "Использование:"
                echo "  sudo ./davinci-resolve.sh                      Интерактивный режим"
                echo "  sudo ./davinci-resolve.sh --studio             Studio версия через AUR"
                echo "  sudo ./davinci-resolve.sh --free               Free версия через AUR"
                echo "  sudo ./davinci-resolve.sh --manual             Ручная установка"
                echo "  sudo ./davinci-resolve.sh --help               Это сообщение"
                exit 0
                ;;
        esac
    done

    clear
    header
    echo "  🎬 DaVinci Resolve Installer"
    echo "  Установка на ChaldOS / Arch Linux"
    header

    # Проверки
    check_root
    check_arch
    check_deps
    check_system

    # Показываем маскота
    if [[ -f "${SCRIPT_DIR}/mascot.sh" ]]; then
        chaldo_say "Устанавливаю DaVinci Resolve! Это проф. видео-редактор 🎬" "work"
    fi

    echo ""
    echo "  Выбери версию DaVinci Resolve:"
    echo "   1) Studio — $99 (полная версия)"
    echo "   2) Free   — бесплатно (ограничения)"
    echo ""
    read -p "  Выбери (1-2): " ver_choice
    case "${ver_choice:-2}" in
        1) DAVINCI_TYPE="studio" ;;
        *) DAVINCI_TYPE="free" ;;
    esac

    echo ""
    log "Версия: ${DAVINCI_TYPE}"

    # Выбор метода установки
    if [[ -z "$method" ]]; then
        echo ""
        echo "  Способ установки:"
        echo "   1) Через AUR (автоматически, рекомендуется)"
        echo "   2) Вручную (скачать с сайта Blackmagic Design)"
        echo ""
        read -p "  Выбери способ (1-2) [1]: " method_choice
        case "${method_choice:-1}" in
            2) method="manual" ;;
            *) method="aur" ;;
        esac
    fi

    case "$method" in
        aur)
            install_aur_helper
            if [[ "$DAVINCI_TYPE" == "studio" ]]; then
                install_davinci_aur "$AUR_PACKAGES_STUDIO" || {
                    warn "AUR установка не удалась. Перехожу к ручной..."
                    install_davinci_manual "studio"
                }
            else
                install_davinci_aur "$AUR_PACKAGES_FREE" || {
                    warn "AUR установка не удалась. Перехожу к ручной..."
                    install_davinci_manual "free"
                }
            fi
            ;;

        manual)
            install_davinci_manual "$DAVINCI_TYPE"
            ;;
    esac

    # Создаём вспомогательные файлы
    create_launcher 2>/dev/null || true
    create_desktop_file 2>/dev/null || true

    # Финальное сообщение
    echo ""
    if [[ -f /opt/resolve/bin/resolve ]]; then
        chaldo_dance "DaVinci Resolve ${DAVINCI_TYPE} готов к работе! 🎬"
        echo ""
        echo "  Запуск:"
        echo "    resolvere           — через скрипт"
        echo "    /opt/resolve/bin/resolve  — напрямую"
        echo ""
        echo "  Или найди в меню приложений."
        echo ""
        echo "  ⚠️  Важно: запускай от обычного пользователя, не от root!"
    else
        chaldo_say "DaVinci Resolve не обнаружен в /opt/resolve." "warn"
        echo ""
        echo "  Возможно установка не завершилась."
        echo "  Запусти скрипт снова или установи вручную:"
        echo ""
        echo "  Через AUR:"
        echo "    sudo paru -S davinci-resolve${DAVINCI_TYPE:+-studio}"
        echo ""
        echo "  Вручную:"
        echo "    Скачай с https://www.blackmagicdesign.com/products/davinciresolve"
        echo "    и запусти установщик."
    fi
}

main "$@"
