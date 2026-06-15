---
name: outline-vpn-basic
description: KISS operations skill for Outline VPN on VPS (install, key lifecycle, status, limits).
enabled: true
---

# outline-vpn-basic

Назначение:
- управлять Outline VPN на VPS простыми командами;
- покрыть полный цикл ключей: создать, доздать, удалить, лимит/безлимит;
- хранить чувствительные данные только вне репозитория.

Что включает:
1. Установка Outline на VPS.
2. Синхронизация manager-конфига (`apiUrl`, `certSha256`) в локальный приватный каталог.
3. Просмотр статуса сервера и списка ключей.
4. Создание ключей (по умолчанию без лимита).
5. Удаление ключей (точечно и batch).
6. Включение/снятие лимитов трафика.

Основной инструмент:
- `scripts/outlinectl.sh`

Быстрый старт:
```bash
# 1) установка и первичная конфигурация
bash scripts/outlinectl.sh install \
  --host-id agents-prod-01 \
  --ssh-host root@<your-vps-ip>

# 2) создать 8 безлимитных ключей
bash scripts/outlinectl.sh keys-create \
  --host-id agents-prod-01 \
  --count 8 \
  --name-prefix p11-unlimited

# 3) показать ключи (без вывода access_url в stdout)
bash scripts/outlinectl.sh keys-list --host-id agents-prod-01
```

Где хранятся приватные данные:
- manager config: `${XDG_CONFIG_HOME:-$HOME/.config}/codex/outline/<host-id>.manager.env`
- экспорт ключей: `${XDG_CONFIG_HOME:-$HOME/.config}/codex/outline/<host-id>-keys-<timestamp>.txt`

KISS-правила:
1. Один script (`outlinectl.sh`) и явные подкоманды.
2. Без хранения ключей/API URL в репозитории.
3. Опасные операции (`keys-delete-all`) требуют `--yes`.

Reference:
- `references/OUTLINE_VPN_GUIDELINES.md`

Ограничения:
- для VPS операций нужен обычный `ssh`-доступ к серверу;
- команды key-management требуют валидный manager config;
- любые массовые удаления делать только после `keys-list` и backup/export.
