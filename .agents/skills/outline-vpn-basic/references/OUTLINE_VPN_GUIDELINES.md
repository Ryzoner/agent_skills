# OUTLINE_VPN_GUIDELINES

## Цель
- Дать простой и безопасный playbook для Outline VPN на VPS.
- Сохранить KISS: минимальный набор команд для реальной эксплуатации.

## Сценарии
1. Установить Outline на VPS.
2. Поднять manager-config локально.
3. Создать/доздать ключи.
4. Удалить лишние ключи.
5. Настроить лимит/безлимит.

## Принципы безопасности
1. Ключи и manager API URL не храним в git.
2. Все чувствительные файлы держим в `${XDG_CONFIG_HOME:-$HOME/.config}/codex/outline`.
3. Массовое удаление ключей только с `--yes` и после предварительного списка.

## Минимальный рабочий поток
1. `install --host-id <id> --ssh-host <user@host>`
2. `keys-list --host-id <id>`
3. `keys-create --host-id <id> --count <n> --name-prefix <prefix>`
4. `key-delete --host-id <id> --id <key-id>` при необходимости

## Ограничение/безлимит
1. Лимит:
   - `key-limit --host-id <id> --id <key-id> --bytes <n>`
2. Без лимита:
   - `key-unlimit --host-id <id> --id <key-id>`

## Наблюдаемость
1. Перед изменениями: `status` + `keys-list`.
2. После изменений: повторный `keys-list`.
3. При установке проверять, что `shadowbox` работает.
