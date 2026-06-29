#!/bin/bash
# ChaldOS Mascot — "Чалдо" (Chaldo)
# ======================================
# ASCII-персонаж, который помогает пользователю
# во время установки и работы с системой.
#
# Использование:
#   source mascot.sh
#   chaldo_say "Привет!" happy
#   chaldo_think "Выбирай..."
#   chaldo_warn "Осторожно!"
#   chaldo_dance
#
# Эмоции: happy, think, work, love, dance, warn, sleep, cool

# Цвета для маскота
C_RESET='\033[0m'
C_HAT='\033[1;35m'      # Фиолетовый — шапка
C_FACE='\033[1;33m'      # Жёлтый — лицо
C_EYES='\033[1;36m'      # Голубой — глаза
C_MOUTH='\033[1;31m'     # Красный — рот
C_TEXT='\033[1;37m'      # Белый — текст
C_BUBBLE='\033[1;34m'    # Синий — облачко

# ─── Аватары (разные эмоции) ───────────────────────────────

chaldo_happy() {
    cat << 'EOF'
    ╔═══════════════╗
    ║   ◉      ◉    ║
    ║      ❤       ║
    ║    ╱──╲     ║
    ╚═══════════════╝
EOF
}

chaldo_think() {
    cat << 'EOF'
    ╔═══════════════╗
    ║  ◉      ◉     ║
    ║     •?•       ║
    ║    ╭──╮     ║
    ╚═══════════════╝
EOF
}

chaldo_work() {
    cat << 'EOF'
    ╔═══════════════╗
    ║  ◉      ◉     ║
    ║     ▄▄▄      ║
    ║    ╧──╧     ║
    ╚═══════════════╝
EOF
}

chaldo_love() {
    cat << 'EOF'
    ╔═══════════════╗
    ║  ◉      ◉     ║
    ║  ♥  ♥  ♥    ║
    ║    ╰──╯     ║
    ╚═══════════════╝
EOF
}

chaldo_dance() {
    cat << 'EOF'
    ╔═══════════════╗
    ║  ◉      ◉     ║
    ║     ★ ★     ║
    ║  ♪╲──╱♪    ║
    ╚═══════════════╝
EOF
}

chaldo_warn() {
    cat << 'EOF'
    ╔═══════════════╗
    ║  ⊙      ⊙     ║
    ║     █▬█      ║
    ║    ╰──╯     ║
    ╚═══════════════╝
EOF
}

chaldo_sleep() {
    cat << 'EOF'
    ╔═══════════════╗
    ║  ﹏      ﹏    ║
    ║     z Z Z    ║
    ║    ╭──╮     ║
    ╚═══════════════╝
EOF
}

chaldo_cool() {
    cat << 'EOF'
    ╔═══════════════╗
    ║  ‾◉    ◉‾   ║
    ║     ▀▄▀      ║
    ║    ╭──╮     ║
    ╚═══════════════╝
EOF
}

chaldo_big() {
    # Большая версия для приветствия
    cat << 'EOF'
    ╔═══════════════════╗
    ║  ╱◉‿◉╲  │  ║
    ║  │  ❤  │  │  ║
    ║  │ ╱─╲ │  │  ║
    ║  ╰─────╯  │  ║
    ╚═══════════════════╝
    ╔═══════════════════╗
    ║  C H A L D O    ║
    ╚═══════════════════╝
EOF
}

# ─── Функции отображения ──────────────────────────────────

# Показать маскота с указанной эмоцией
chaldo_show() {
    local emotion="${1:-happy}"
    local msg="$2"

    echo ""
    case "$emotion" in
        happy)  echo -e "${C_HAT}$(chaldo_happy)${C_RESET}" ;;
        think)  echo -e "${C_FACE}$(chaldo_think)${C_RESET}" ;;
        work)   echo -e "${C_FACE}$(chaldo_work)${C_RESET}" ;;
        love)   echo -e "${C_HAT}$(chaldo_love)${C_RESET}" ;;
        dance)  echo -e "${C_HAT}$(chaldo_dance)${C_RESET}" ;;
        warn)   echo -e "${C_HAT}$(chaldo_warn)${C_RESET}" ;;
        sleep)  echo -e "${C_FACE}$(chaldo_sleep)${C_RESET}" ;;
        cool)   echo -e "${C_HAT}$(chaldo_cool)${C_RESET}" ;;
        big)    echo -e "${C_HAT}$(chaldo_big)${C_RESET}" ;;
        *)      echo -e "${C_FACE}$(chaldo_happy)${C_RESET}" ;;
    esac

    if [[ -n "$msg" ]]; then
        local msg_len=${#msg}
        local box_width=$((msg_len + 4))

        # Верхняя граница облачка
        echo -ne "${C_BUBBLE}╭"
        printf '─%.0s' $(seq 1 $box_width)
        echo "╮${C_RESET}"

        # Сам текст
        echo -e "${C_BUBBLE}│  ${C_TEXT}${msg}${C_BUBBLE}  │${C_RESET}"

        # Нижняя граница
        echo -ne "${C_BUBBLE}╰"
        printf '─%.0s' $(seq 1 $box_width)
        echo "╯${C_RESET}"
    fi
    echo ""
}

# Сказать (с эмоцией)
chaldo_say() {
    local msg="$1"
    local emotion="${2:-happy}"
    chaldo_show "$emotion" "$msg"
}

# Подумать (вопросительная эмоция)
chaldo_think() {
    chaldo_show "think" "🤔 $1"
}

# Предупредить
chaldo_warn() {
    chaldo_show "warn" "⚠️  $1"
}

# Поработать (процесс)
chaldo_work() {
    chaldo_show "work" "🔧 $1"
}

# Потанцевать (победа!)
chaldo_dance() {
    chaldo_show "dance" "🎉 $1"
}

# Показать прогресс-бар
chaldo_progress() {
    local current="$1"
    local total="$2"
    local msg="${3:-Установка...}"
    local bar_len=30

    local percent=$((current * 100 / total))
    local filled=$((current * bar_len / total))

    echo -ne "\r${C_BUBBLE}[${C_HAT}"
    printf '█%.0s' $(seq 1 $filled)
    printf '░%.0s' $(seq 1 $((bar_len - filled)))
    echo -ne "${C_BUBBLE}] ${C_TEXT}${percent}%% — ${msg}${C_RESET}"

    if [[ "$current" -eq "$total" ]]; then
        echo ""
    fi
}

# Главный экран приветствия
chaldo_welcome() {
    clear
    echo ""
    echo -e "${C_HAT}"
    echo "    ╔═══════════════════════════════════════╗"
    echo "    ║                                       ║"
    echo "    ║   ╱◉‿◉╲                               ║"
    echo "    ║   │  ❤  │          Ч А Л Д О        ║"
    echo "    ║   │ ╱─╲ │                              ║"
    echo "    ║   ╰─────╯                              ║"
    echo "    ║                                       ║"
    echo "    ║   🎮  Gaming Edition v2.0            ║"
    echo "    ║   🐧  Arch Linux Powered             ║"
    echo "    ║   ✨  Pixel Perfect                  ║"
    echo "    ╚═══════════════════════════════════════╝"
    echo -e "${C_RESET}"
    echo ""
    echo -e "${C_TEXT}Привет! Я — Чалдо (Chaldo), твой цифровой помощник! 🤖${C_RESET}"
    echo -e "${C_TEXT}Я помогу тебе установить идеальную геймерскую систему.${C_RESET}"
    echo ""
}

# Прощальный экран
chaldo_goodbye() {
    echo ""
    echo -e "${C_HAT}"
    echo "    ╔═══════════════════════════════════════╗"
    echo "    ║  ★  ★  ★  ★  ★  ★  ★  ★  ★  ★  ║"
    echo "    ║                                       ║"
    echo "    ║   ◉              ◉                    ║"
    echo "    ║        ♪   ♪   ♪                    ║"
    echo "    ║      ♪  ╲──╱  ♪                    ║"
    echo "    ║                                       ║"
    echo "    ║   Спасибо, что выбрал ChaldOS!       ║"
    echo "    ║   Тебя ждут великие игры! 🎮         ║"
    echo "    ╚═══════════════════════════════════════╝"
    echo -e "${C_RESET}"
}

# Экспорт функций, если скрипт загружен через source
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    # Запущен как отдельная команда
    chaldo_say "${2:-Привет! Я Чалдо!}" "${1:-happy}"
fi
