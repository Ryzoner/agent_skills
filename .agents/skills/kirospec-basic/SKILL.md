---
name: kirospec-basic
description: Create and maintain .kiro specifications from local scripts without external folder dependency.
enabled: true
---

# kirospec-basic

Назначение:
- использовать локальные правила SPEC в переносимом навыке;
- создавать и поддерживать `.kiro/specs/<spec-name>/` без внешней зависимости;
- использовать каноничные шаблоны `design/requirements/tasks`.

Когда включать:
- пользователь просит `SPEC`, спецификацию, либо правки `design.md`, `requirements.md`, `tasks.md`;
- пользователь просит зафиксировать решение до начала кода.

Что делает skill:
1. Валидирует `SPEC_NAME` из окружения.
2. Создает каркас спецификации через локальный `spec-init.sh`.
3. Проверяет наличие:
   - `design.md`
   - `requirements.md`
   - `tasks.md`

Быстрый запуск:
```bash
SPEC_NAME="payments-webhook" \
SPEC_ROOT="." \
bash scripts/spec-init.sh "${SPEC_NAME}"
```

Локальные скрипты:
- create: `bash scripts/spec-init.sh <spec-name>`
- create (PowerShell): `pwsh -File scripts/spec-init.ps1 <spec-name>`
- undo: `bash scripts/spec-init-undo.sh <spec-name>`

Reference:
- правила/процесс: `references/SPEC_GUIDELINES.md`
- пример design: `references/ExampleDesign.md`
- пример requirements: `references/ExampleRequirements.md`
- пример tasks: `references/ExampleTasks.md`

Правила:
- не перезаписывать существующие файлы без явного `--force`;
- работать через относительный root проекта или `--root`;
- вести SPEC-контент на русском, если не запрошено иначе.
