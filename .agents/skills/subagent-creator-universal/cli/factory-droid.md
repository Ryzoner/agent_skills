# Factory Droid — Subagent Format

## Путь и формат

`.factory/droids/<name>.md` — `.md` + YAML frontmatter

## Обязательные поля

| Поле | Описание |
|------|----------|
| `name` | Имя агента |
| `description` | Краткое описание экспертизы |
| `model` | Модель: `inherit` (наследует от родителя) |
| `tools` | Список инструментов (массив) |

## Шаблон

```markdown
---
name: code-reviewer
description: "Looks for bugs, security issues, and performance problems in recently written code"
model: inherit
tools: ["Read", "Grep", "Glob"]
---

You are a Senior Security & Performance Engineer specializing in code review.

## Responsibilities
- Identify bugs, security vulnerabilities, performance issues
- Provide concrete fixes with code examples
- Reference exact file and line numbers

## Output
- Summary of findings grouped by severity
- Each finding: File:Line → Issue → Impact → Fix
- Acknowledge what's done well
```

## Особенности

- `model: inherit` — использует модель родительского агента
- `tools` — массив JSON: `["Read", "Grep", "Glob"]`
- Папка `.factory/droids/` относительно проекта или home
