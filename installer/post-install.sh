#!/bin/bash
# ChaldOS Post-Installation Script
# ==================================
# Запускается внутри установленной системы (chroot).
# Настройка пользователя, окружения, брендинга.

set -euo pipefail

VERSION="2.0.0"
LOG_FILE="/var/log/chaldos-postinstall.log"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║     ChaldOS Post-Installation v${VERSION}      ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# ─── Проверка ───────────────────────────────────────────
if [[ ! -f /etc/os-release ]] || ! grep -q 'ID=chaldos\|ID=arch' /etc/os-release 2>/dev/null; then
    log "⚠️  Похоже это не ChaldOS/Arch система. Пропускаю."
    exit 1
fi

# ─── Пользователь ───────────────────────────────────────
if [[ -z "${CHALDOS_USER:-}" ]]; then
    CHALDOS_USER=$(grep -oP '^CHALDOS_USER\s*=\s*\K.*' /etc/chaldos/chaldos.conf 2>/dev/null || echo "")
    CHALDOS_USER="${CHALDOS_USER:-chaldos}"
fi

if ! id "$CHALDOS_USER" &>/dev/null; then
    log "Создаю пользователя '$CHALDOS_USER'..."
    useradd -m -G wheel,audio,video,optical,storage,input,games -s /bin/bash "$CHALDOS_USER"
    echo "${CHALDOS_USER}:${CHALDOS_USER}" | chpasswd
    log "Пользователь '$CHALDOS_USER' создан"
else
    log "Пользователь '$CHALDOS_USER' уже существует"
fi

# ─── SUDO ───────────────────────────────────────────────
if ! grep -q '^%wheel ALL=(ALL:ALL) ALL' /etc/sudoers 2>/dev/null; then
    echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
    log "sudo настроен для группы wheel"
fi

# ─── MOTD ───────────────────────────────────────────────
if [[ ! -f /etc/motd ]]; then
    cat > /etc/motd << 'MOTD'
╔═══════════════════════════════════════════════╗
║          ДОБРО ПОЖАЛОВАТЬ В ChaldOS!          ║
║                                               ║
║     ╱◉‿◉╲                                     ║
║     │  ❤  │  🎮 Gaming Edition v2.0           ║
║     │ ╱─╲ │  🐧 Arch Linux Powered            ║
║     ╰─────╯                                   ║
║                                               ║
║  Введи: chaldos-mascot  — приветствие         ║
║         chaldos-info     — инфо о системе      ║
║         chaldos-pkg -Sy  — обновить пакеты     ║
║         pacman -S <pkg>  — установить пакет    ║
╚═══════════════════════════════════════════════╝
MOTD
    log "MOTD установлен"
fi

# ─── ChaldOS branding ──────────────────────────────────
if [[ ! -f /usr/share/chaldos/banner.txt ]]; then
    mkdir -p /usr/share/chaldos
    cat > /usr/share/chaldos/banner.txt << 'BANNER'
    ╔═══════════════════════════════════════╗
    ║                                       ║
    ║     ╱◉‿◉╲                             ║
    ║     │  ❤  │    C H A L D O S         ║
    ║     │ ╱─╲ │    Gaming Edition 2.0    ║
    ║     ╰─────╯    Arch Linux Power      ║
    ║                                       ║
    ╚═══════════════════════════════════════╝
BANNER
    log "Баннер ChaldOS установлен"
fi

# ─── Алиасы для пользователя ───────────────────────────
if [[ -f "/home/${CHALDOS_USER}/.bashrc" ]]; then
    cat >> "/home/${CHALDOS_USER}/.bashrc" << 'ALIASES'

# ChaldOS алиасы
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias info='pacman -Qi'
alias cleanup='sudo pacman -Sc'
alias chaldos='chaldos-mascot'
alias neofetch='fastfetch'
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias grep='grep --color=auto'

# Игровые алиасы
alias steam='steam-runtime'
alias lutris='lutris'
alias obs='obs-studio'
alias resolvere='/opt/resolve/bin/resolve 2>/dev/null || echo "DaVinci не установлен"'

# Функция: быстрая информация о системе
sysinfo() {
    echo "ChaldOS Gaming Edition v2.0"
    echo "─────────────────────────────"
    echo "Ядро: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Пользователь: $(whoami)"
    echo "Память: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "GPU: $(lspci 2>/dev/null | grep -E 'VGA|3D' | head -1 | sed 's/.*: //')"
    echo ""
}
ALIASES
    log "Алиасы добавлены в .bashrc"
fi

# ─── .bashrc для root ──────────────────────────────────
if [[ -f /root/.bashrc ]]; then
    cat >> /root/.bashrc << 'ROOTALIASES'

# ChaldOS root алиасы
alias update='pacman -Syu'
alias install='pacman -S'
alias remove='pacman -Rns'
alias chaldos='chaldos-mascot'
ROOTALIASES
    log "Алиасы добавлены для root"
fi

# ─── chaldos-info команда ──────────────────────────────
if [[ ! -f /usr/local/bin/chaldos-info ]]; then
    cat > /usr/local/bin/chaldos-info << 'INFO'
#!/bin/bash
# ChaldOS System Information
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       ChaldOS System Info           ║"
echo "  ╠══════════════════════════════════════╣"
printf "  ║  %-15s │ %-19s ║\n" "Система" "$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
printf "  ║  %-15s │ %-19s ║\n" "Ядро" "$(uname -r)"
printf "  ║  %-15s │ %-19s ║\n" "Рабочий стол" "${XDG_CURRENT_DESKTOP:-не определён}"
printf "  ║  %-15s │ %-19s ║\n" "Пользователь" "$(whoami)"
printf "  ║  %-15s │ %-19s ║\n" "Память" "$(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
printf "  ║  %-15s │ %-19s ║\n" "Архитектура" "$(uname -m)"
echo "  ╚══════════════════════════════════════╝"
echo ""
INFO
    chmod 755 /usr/local/bin/chaldos-info
    log "Команда chaldos-info создана"
fi

# ─── Очистка ───────────────────────────────────────────
log "Очистка кэша pacman..."
pacman -Scc --noconfirm &>/dev/null || true

# ─── Финиш ─────────────────────────────────────────────
echo ""
echo "  ╔═══════════════════════════════════════╗"
echo "  ║  ChaldOS готов к использованию!     ║"
echo "  ║  Введи: chaldos-mascot              ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""
log "Post-installation завершён!"
