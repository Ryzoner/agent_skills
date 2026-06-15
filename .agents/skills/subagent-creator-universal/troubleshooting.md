# Troubleshooting — Частые ошибки и фиксы

## Все CLI

| Ошибка | CLI | Фикс |
|--------|-----|------|
| `missing YAML frontmatter` | Qwen, Claude, Copilot | Добавить `---` с `name:`/`description:` |
| `invalid YAML: metadata` | Все | Убрать `metadata: \|` с JSON |
| `mapping values not allowed` | Все | Обернуть `description` с `:` в кавычки `"..."` |
| Агент не виден | Все | Файл в правильной директории (`~/.<cli>/agents/`) |

## Codex CLI

| Ошибка | Фикс |
|--------|------|
| `unknown variant 'relaxed'` | `read-only` / `workspace-write` / `danger-full-access` |
| TOML parse error | Проверить кавычки, многострочные `"""`, отсутствие YAML-синтаксиса |

## OpenCode

| Ошибка | Фикс |
|--------|------|
| `subagent doesn't read body` | Убедиться что body после `---` не пустой |

## GitHub Copilot CLI

| Ошибка | Фикс |
|--------|------|
| `wrong file extension` | Должно быть `.agent.md`, не просто `.md` |
| `agent not loading after edit` | Полный перезапуск CLI (`exit` + новый запуск) |
| `name conflict: user vs project` | `~/.copilot/agents/` приоритетнее `.github/agents/` |
