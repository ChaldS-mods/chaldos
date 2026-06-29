# ChaldOS — Gaming Edition 🎮

```
    ╔═══════════════╗
    ║  ◉      ◉    ║
    ║     ❤       ║
    ║    ╱──╲     ║
    ╚═══════════════╝
    ╔═══════════════╗
    ║  C H A L D O  ║
    ╚═══════════════╝
```

**ChaldOS Gaming Edition v2.0** — геймерская операционная система на базе **Arch Linux** с фокусом на производительность в играх, удобство и стиль.

🎮 **Для геймеров, создателей контента и энтузиастов!**

---

## ✨ Возможности

### 🖥️ Выбор рабочего стола
| Окружение | Описание |
|-----------|----------|
| **KDE Plasma 6** | 🎮 Современный, красивый, идеален для игр |
| **GNOME 46** | 🖥️ Интуитивный, минималистичный |
| **XFCE 4.18** | ⚡ Лёгкий, быстрый, для старого железа |
| **Hyprland** | ✨ Стильный Wayland композитор |
| **Sway** | 🪟 i3-подобный тайловый |
| **Budgie 10** | 🌿 Элегантный и простой |
| **Cinnamon** | 🍭 Классический, как Windows |
| **MATE 1.28** | 🍃 Лёгкий, традиционный |
| **i3 WM** | 🔲 Минималистичный тайловый |

### 🎮 GPU драйверы с таблицей выбора
| # | Драйвер | Для кого |
|---|---------|----------|
| 1 | **NVIDIA — nvidia** | ⭐ Все карты (проприетарный) |
| 2 | **NVIDIA — nvidia-open** | 🔓 RTX 2xxx+ (открытый модуль) |
| 3 | **NVIDIA — nvidia-dkms** | 🔧 Кастомное ядро |
| 4 | **NVIDIA — nvidia-lts** | 🛡️ LTS ядро |
| 5 | **NVIDIA — nouveau** | 🐧 Свободный драйвер |
| 6 | **AMD — amdgpu/mesa** | ⭐ Отличная поддержка! |
| 7 | **AMD — amd-pro (AUR)** | 💼 Рабочие станции |
| 8 | **Intel — i915/mesa** | ⭐ Встроенная графика |
| 9 | **Intel — compute** | 🔬 Вычислительные задачи |
| 10 | **VM/Virt** | 🖥️ Виртуальные машины |

### 📥 Скачать ISO

Готовые ISO можно скачать на официальном сайте: **[chaldos.dev](https://chaldos.dev)** 🎮

Или собрать самому:
```bash
git clone https://github.com/chaldos/chaldos.git
cd chaldos
sudo pacman -S archiso
./build.sh
```

### 📦 Геймерский софт
- **Steam** — главный игровой магазин 🎮
- **Lutris** — открытая игровая платформа 🐧
- **Heroic Games Launcher** — Epic Games + GOG 🎯
- **OBS Studio** — запись и стриминг 📺
- **MangoHud + GOverlay** — FPS мониторинг 📊
- **Wine + Wine-Staging** — Windows игры на Linux 🍷
- **Proton GE** — кастомный Proton 🛠️
- **Gamescope** — микро-композитор для игр 🖥️
- **GameMode** — оптимизация системы ⚡
- **Discord** — голосовой чат 💬
- **Prism Launcher** — Майнкрафт лаунчер 🧊
- **Vulkan Tools** — современная графика 🖌️

### 🎬 DaVinci Resolve Studio
Профессиональный видеоредактор:
- Авто-установка через AUR (paru)
- Ручная установка с сайта Blackmagic Design
- Скрипт запуска `resolvere`

### 🤖 Маскот "Чалдо"
ASCII-персонаж, который помогает пользователю:
- Разные эмоции в зависимости от ситуации
- Показывает прогресс установки
- Поднимает настроение после успешной установки!

```
    ╔═══════════════╗
    ║  ◉      ◉    ║
    ║     ❤       ║
    ║    ╱──╲     ║
    ╚═══════════════╝
```

---

## 🚀 Установка

### Быстрый старт (с Arch Live CD)

1. Загрузитесь с [Arch Linux ISO](https://archlinux.org/download/)
2. Подключитесь к интернету
3. Запустите установщик:

```bash
# Способ 1: Онлайн
curl -L https://chaldos.dev/install | bash

# Способ 2: Если у вас ISO ChaldOS
sudo chaldos-install

# Способ 3: Локальный запуск
sudo ./installer/install-chaldos.sh
```

### Что делает установщик:
1. **Проверяет** окружение и интернет
2. **Настраивает** раскладку и часовой пояс
3. **Размечает** диск (авто, рядом с ОС или вручную)
4. **Выбирает** рабочий стол (KDE, GNOME, XFCE и др.)
5. **Выбирает** драйвер видеокарты из таблицы
6. **Выбирает** игровой софт
7. **Устанавливает** DaVinci Resolve (опционально)
8. **Устанавливает** Arch Linux + всё выбранное
9. **Настраивает** систему, пользователя, sudo
10. **Устанавливает** GRUB загрузчик

---

## 🎮 После установки

### Команды:
| Команда | Описание |
|---------|----------|
| `chaldos-mascot` | 🤖 Показать маскота Чалдо |
| `chaldos-mascot dance` | 🎃 Чалдо танцует! |
| `chaldos-info` | ℹ️ Информация о системе |
| `sysinfo` | 📊 Быстрая информация |
| `resolvere` | 🎬 Запуск DaVinci Resolve |
| `update` | 🔄 Обновление системы |
| `install <пакет>` | 📦 Установка пакета |
| `neofetch` | 🖥️ Красивый вывод информации |

### Алиасы:
- `update` → `sudo pacman -Syu`
- `install` → `sudo pacman -S`
- `remove` → `sudo pacman -Rns`
- `search` → `pacman -Ss`

---

## 🏗️ Структура проекта

```
chaldos/
├── archlive/                  # 🏗️ Архив archiso для сборки ISO
│   ├── profiledef.sh          # 📋 Профиль сборки
│   ├── packages.x86_64        # 📦 Пакеты live-среды
│   ├── prepare-airootfs.sh    # 🔧 Подготовка оверлея
│   ├── airootfs/              # 📁 Файлы live-системы
│   ├── grub/                  # 🖥️ GRUB BIOS
│   ├── efiboot/               # 🖥️ Загрузка UEFI
│   └── syslinux/              # 🖥️ SYSLINUX Legacy
├── installer/
│   ├── install-chaldos.sh     # 🚀 Главный установщик (Arch-based)
│   ├── mascot.sh              # 🤖 Маскот Чалдо
│   ├── davinci-resolve.sh     # 🎬 DaVinci Resolve установщик
│   ├── post-install.sh        # 🔧 Пост-установка
│   └── install-libs.sh        # 📚 Библиотека функций
├── config/
│   └── chaldos.conf           # ⚙️ Конфигурация
├── rootfs/
│   └── usr/bin/
│       └── chaldos-mascot     # 🤖 Системная команда маскота
├── packages/                  # 📦 Пакетный менеджер (chaldos-pkg)
├── build.sh                   # 🔨 Скрипт сборки ISO
├── Makefile                   # 📐 Make цели
└── README.md                  # 📖 Этот файл
```

---

## 📋 Требования

- **Процессор:** x86_64 (Intel Core 2 / AMD K8 или новее)
- **RAM:** 2 ГБ минимум (8+ ГБ для игр и DaVinci Resolve)
- **Диск:** 20 ГБ минимум (50+ ГБ для игр)
- **Загрузка:** UEFI (рекомендуется) или BIOS
- **Интернет:** Требуется для установки

---

## 🏗️ Сборка своего ISO

ChaldOS собирается через **archiso** (`mkarchiso`). Профиль находится в `archlive/`.

```bash
# 1. Установи archiso
sudo pacman -S archiso

# 2. Собери ISO (из корня проекта)
./build.sh

# 3. ISO появится в output/
#    output/chaldos-YYYYMMDD-x86_64.iso

# 4. Запиши на USB
sudo dd if=output/chaldos-*.iso of=/dev/sdX bs=4M status=progress
```

### Структура archiso профиля

```
archlive/
├── profiledef.sh                    # 📋 Метаданные профиля
├── packages.x86_64                  # 📦 Пакеты live-среды
├── pacman.conf                      # ⚙️ Конфиг pacman
├── prepare-airootfs.sh              # 🔧 Копирует файлы установщика
├── airootfs/
│   ├── etc/
│   │   ├── motd                     # 📜 Приветствие при загрузке
│   │   ├── os-release               # 🏷️ Информация о системе
│   │   └── skel/.bashrc             # 🐚 Баш-профиль по умолчанию
│   └── root/chaldos/                # 📁 Скрипты установщика
├── grub/
│   ├── grub.cfg                     # 🖥️ GRUB для BIOS
│   ├── loopback.cfg                 # 🔄 Loopback загрузка
│   └── themes/chaldos/              # 🎨 GRUB тема
├── efiboot/                         # 🖥️ systemd-boot для UEFI
└── syslinux/                        # 🖥️ SYSLINUX для BIOS (legacy)
```

### Кастомизация

Хочешь добавить свои пакеты в ISO?
- Отредактируй `archlive/packages.x86_64`
- Или добавь пакеты в `archlive/airootfs/root/chaldos/`

Чтобы изменить версию или кодовое имя:
- Отредактируй `config/chaldos.conf`

---

## 📝 Лицензия

ChaldOS — open source проект. Arch Linux — GNU GPL.
Основано на любви к играм и пингвинам 🐧

---

### 🙏 Благодарности

- **Arch Linux** — за надёжную основу
- **Blackmagic Design** — за DaVinci Resolve
- **Valve** — за Steam, Proton и Gamescope
- **Всем геймерам на Linux!** 🎮

---

*Сделано с ❤ для геймеров. Играй на ChaldOS! 🎮*
