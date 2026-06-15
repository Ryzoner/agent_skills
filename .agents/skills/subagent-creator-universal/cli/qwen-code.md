# Qwen Code — Subagent Format

## Путь и формат

`~/.qwen/agents/<name>.md` — `.md` + YAML frontmatter

## Обязательные поля

| Поле | Описание |
|------|----------|
| `name` | Имя агента (lowercase-with-hyphens) |
| `description` | Описание + триггеры |
| `color` | Цвет тега в UI |

## Цвета

`Green` `Orange` `Purple` `Blue` `Red` `Cyan` `Yellow` `Magenta`

## Шаблон

```markdown
---
name: code-reviewer
description: "Review code for bugs, security, and performance. Trigger: review, code review, провери код, security.

<example>
Context: User wrote a new function and wants it reviewed.
user: \"Review this login function\"
<commentary>
User asks for code review. Use code-reviewer agent.
</commentary>
</example>"
color: Green
---

You are a Senior Security & Performance Engineer.

## Core Responsibilities
### 1. BUG DETECTION
- Logic errors, edge cases, race conditions
- Incorrect error handling, state management

### 2. SECURITY VULNERABILITIES
- OWASP Top 10, hardcoded secrets, XSS
- Sensitive data exposure

### 3. PERFORMANCE ISSUES
- O(n^2) algorithms, resource leaks
- Synchronous blocking in async contexts

## Rules
- Be specific: reference exact line numbers
- Provide solutions with code examples
- Explain why: briefly describe risk/impact

## Output Format
- Code Review Summary with severity grouping
- Issues: File:Line → Issue → Impact → Fix
- What's Good + Recommended Actions
```

## Частые ошибки

| Ошибка | Фикс |
|--------|------|
| `missing YAML frontmatter` | Добавить `---` с `name:`/`description:`/`color:` |
| `invalid YAML: metadata` | Убрать `metadata: |` с JSON |
| `mapping values not allowed` | Обернуть `description` с `:` в кавычки `"..."` |
