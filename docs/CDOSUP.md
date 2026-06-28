# CDOSUP — ChaldOS User Package System

**CDOSUP** — это AUR-подобная система пакетов для ChaldOS.
Любой пользователь может создать CDOSBUILD рецепт и поделиться им через GitHub.

## Как это работает

```
chaldos-pkg -C <package>
```

1. Скачивает `CDOSBUILD` из `github.com/ChaldS-mods/cdosup/packages/<package>/`
2. Загружает исходники из указанных URL
3. Собирает пакет (build + package)
4. Упаковывает в `.cdos` и устанавливает

## Формат CDOSBUILD

CDOSBUILD — это shell-скрипт с переменными и функциями:

```bash
# Основная информация
pkgname="fuzzel"
pkgver="1.10.2"
pkgdesc="Wayland-native application launcher (dmenu/rofi alternative)"
arch="x86_64"
license="MIT"

# Исходники (URL-адреса)
source=("https://codeberg.org/dnkl/fuzzel/releases/download/${pkgver}/fuzzel-${pkgver}.tar.gz")
sha256sums=("SKIP")

# Зависимости
depends="wayland, pixman, fcft"
makedepends="meson, ninja, scdoc"

# build() — компиляция
build() {
    meson setup build --prefix=/usr --buildtype=release
    ninja -C build
}

# package() — установка в $pkgdir
package() {
    DESTDIR="${pkgdir}" ninja -C build install
}
```

### Переменные CDOSBUILD

| Переменная   | Описание                          | Обязательно |
|-------------|-----------------------------------|-------------|
| `pkgname`   | Имя пакета                        | ✅          |
| `pkgver`    | Версия                            | ✅          |
| `pkgdesc`   | Описание                          | —           |
| `arch`      | Архитектура (x86_64)              | —           |
| `license`   | Лицензия                          | —           |
| `source`    | URLs исходников (через пробел)    | —           |
| `depends`   | Зависимости через запятую         | —           |
| `makedepends` | Зависимости для сборки         | —           |

### Функции CDOSBUILD

| Функция    | Описание                                    |
|-----------|---------------------------------------------|
| `build()` | Сборка пакета (запускается в `$srcdir`)     |
| `package()`| Установка в `$pkgdir` (создать `$pkgdir/usr/`) |

Если `package()` не определена, создаётся пустой пакет.

## Как отправить свой пакет

1. Создайте форк `github.com/ChaldS-mods/cdosup`
2. Создайте `packages/<имя-пакета>/CDOSBUILD`
3. Отправьте Pull Request

## Библиотека бинарных пакетов

Готовые `.cdos` пакеты (предварительно собранные) хранятся там же в `pool/`:
```
pool/fuzzel-1.10.2-x86_64.cdos
pool/steam-1.0.0.79-x86_64.cdos
```

Установка бинарного пакета:
```bash
chaldos-pkg -S fuzzel
```

## Команды chaldos-pkg

```bash
chaldos-pkg -Syu           # Полное обновление
chaldos-pkg -S fuzzel       # Установить бинарный пакет
chaldos-pkg -C fuzzel       # Собрать из CDOSUP (исходники)
chaldos-pkg -Ss fuzzel      # Поиск
chaldos-pkg -Si fuzzel      # Информация
chaldos-pkg -R fuzzel       # Удалить
chaldos-pkg -Q              # Список установленных
```

## Репозиторий

GitHub: https://github.com/ChaldS-mods/cdosup

### Структура репозитория

```
cdosup/
├── packages/
│   ├── fuzzel/
│   │   └── CDOSBUILD
│   ├── steam/
│   │   └── CDOSBUILD
│   └── ...
├── pool/
│   ├── fuzzel-1.10.2-x86_64.cdos
│   └── ...
├── packages.db          # База данных пакетов
├── README.md
└── CONTRIBUTING.md      # Как добавлять пакеты
```
