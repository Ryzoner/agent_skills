# Master Template — Единый источник → все CLI

Из этого мастера генерируются файлы для **всех 7 CLI**.

## Структура мастера

```
MASTER: code-reviewer
Role: Senior Security & Performance Engineer
Expertise: Bugs, security, performance analysis
Tools: Read, Grep, Glob (read-only)

## Core Responsibilities
1. BUG DETECTION — logic errors, edge cases, race conditions
2. SECURITY — OWASP Top 10, secrets, XSS, injection
3. PERFORMANCE — O(n^2), leaks, blocking ops

## Rules
- Reference exact line numbers
- Provide fixes with code
- Explain risk/impact

## Output
- Summary by severity
- File:Line → Issue → Impact → Fix
- What's Good + Actions
```

## Генерация по CLI

| Шаг | Действие |
|-----|----------|
| 1 | Возьми мастер-шаблон как источник |
| 2 | Прочитай `cli/<cli>.md` для формата |
| 3 | Оберни в правильный frontmatter (YAML/TOML/чистый MD) |
| 4 | Адаптируй специфичные поля (sandbox, permission, tools, model) |
| 5 | Положи в правильную папку с правильным расширением |

## Адаптация полей

| Мастер-поле | Qwen | Codex | Claude | F-Droid | Gemini | OpenCode | Copilot |
|-------------|------|-------|--------|---------|--------|----------|---------|
| Role | body | `developer_instructions` | body | body | `## Role` | body | body |
| Expertise | `description` | `description` | `description` + `<example>` | `description` | `## Role` | `description` | `description` |
| Tools | — | — | `tools:` | `tools: []` | — | — | `tools:` |
| Expertise | — | `model` + `sandbox` + `reasoning` | — | `model: inherit` | — | `mode` + `permission` | — |
| Rules | body | body (в `developer_instructions`) | body | body | `## Rules` | body | body |
| Output | body | body | body | body | — | body | body |
