---
name: v2raya-linux-basic
description: KISS reference skill for v2rayA on Arch/Ubuntu/Fedora with TUN, RoutingA, DoH DNS and Outline key import.
enabled: true
---

# v2raya-linux-basic

Назначение:
- дать рабочий runbook по установке `v2rayA` на Arch Linux, Ubuntu и Fedora;
- зафиксировать UI-настройки для системного прокси, TUN и `RoutingA`;
- явно показать, как использовать ключи Outline (`ss://`) в `v2rayA`.

Что покрывает:
1. Установка `v2rayA` + core (`xray`/`v2ray`) по дистрибутивам.
2. Запуск и автозапуск через `systemd`.
3. Вход в UI: `http://127.0.0.1:2017`.
4. Готовый `RoutingA` шаблон с local bypass + dev/media правилами.
5. Анти-DNS-подмена через DoH в UI.
6. Импорт ключей Outline в `v2rayA`.

Основной инструмент:
- `scripts/v2raya-install.sh`

Быстрый старт:
```bash
# preview авто-детекта (без установки)
bash scripts/v2raya-install.sh

# выполнить установку
bash scripts/v2raya-install.sh --apply

# проверить install helper
bash scripts/v2raya-install.sh

# открыть reference
sed -n '1,260p' references/V2RAYA_LINUX_GUIDELINES.md
```

Ограничения:
- skill справочный, не запускает `sudo` шаги автоматически;
- не хранить ключи (`ss://...`) в репозитории и логах;
- для TUN/transparent proxy применять только через UI и проверять доступ после каждого изменения.

Reference:
- `references/V2RAYA_LINUX_GUIDELINES.md`
