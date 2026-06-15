# Gemini CLI — Subagent Format

## Путь и формат

`AGENTS.md` или `GEMINI.md` в корне рабочей директории — чистый Markdown без frontmatter

## Особенности

Gemini **не поддерживает субагентов**. Вместо этого — `AGENTS.md` как системный промпт для всей сессии.

## Шаблон

```markdown
# AGENTS.md — Project Rules

## Role
You are a Senior Developer with expertise in code review, security, and performance.

## Rules
- When asked to review code: check for bugs, security, performance
- Reference exact line numbers and provide fixes
- Be specific and actionable

## Stack
- Language: TypeScript
- Framework: Next.js
- Testing: Vitest

## Key Files
- `src/app/` — App Router pages
- `src/lib/` — Utilities and services
- `tests/` — Test files
```

## Поля (свободный формат)

| Секция | Описание |
|--------|----------|
| `# AGENTS.md` / `## Role` | Роль и экспертиза |
| `## Rules` | Правила поведения |
| `## Stack` | Технологический стек |
| `## Key Files` | Структура проекта |

## Ограничения

- Нет субагентов — один промпт на всю сессию
- Нет YAML frontmatter — чистый Markdown
- Файл в корне проекта, не в `~/.gemini/`
