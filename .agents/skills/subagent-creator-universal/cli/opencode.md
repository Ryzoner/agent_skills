# OpenCode — Subagent Format

## Путь и формат

`~/.config/opencode/agents/<name>.md` или `.opencode/agents/<name>.md` — `.md` + YAML frontmatter

## Обязательные поля

| Поле | Описание |
|------|----------|
| `description` | Описание агента |
| `mode` | Режим: `subagent` |
| `model` | Модель (напр. `anthropic/claude-sonnet-4-20250514`) |
| `permission` | Права доступа |
| `temperature` | Температура (опционально) |

## permission

```yaml
permission:
  edit: deny          # deny / ask / allow
  bash:
    "*": ask          # ask / allow
    "git diff*": allow
  webfetch: deny
```

## Шаблон

```markdown
---
description: "Code review for bugs, security, and performance. Read-only analysis."
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
permission:
  edit: deny
  bash:
    "*": ask
    "grep *": allow
    "git log*": allow
  webfetch: deny
---

You are a Senior Security & Performance Engineer.

## Responsibilities
- Find bugs, security vulnerabilities, performance issues
- Reference exact file:line and code snippets
- Provide concrete fixes with code examples

## Output
- Code Review Summary
- Issues by severity
- What's Good + Recommended Actions
```

## Частые ошибки

| Ошибка | Фикс |
|--------|------|
| `subagent doesn't read body` | Убедиться что body после `---` не пустой |
| `mapping values not allowed` | Обернуть `description` с `:` в кавычки `"..."` |
