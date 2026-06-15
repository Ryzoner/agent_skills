# GitHub Copilot CLI — Subagent Format

## Пути и приоритет

| Уровень | Путь | Описание |
|---------|------|----------|
| **User** | `~/.copilot/agents/` | Глобальные агенты, доступны во всех проектах |
| **Project** | `.github/agents/` | Агенты репозитория, коммитятся в git |
| **Приоритет** | — | `~/.copilot/agents/` переопределяет `.github/agents/` при совпадении имён |

## Формат

`<name>.agent.md` — `.agent.md` расширение + YAML frontmatter

**Важно:** расширение именно `.agent.md`, не `.md`!

## Обязательные поля

| Поле | Описание |
|------|----------|
| `name` | Имя агента (lowercase-with-hyphens) |
| `description` | Описание + триггеры |
| `tools` | Список инструментов (опционально, по умолчанию — все) |

## Конфигурация

| Файл | Путь | Описание |
|------|------|----------|
| `config.json` | `~/.copilot/config.json` | `trusted_folders`, права |
| Переопределение | `$COPILOT_HOME` | Переменная окружения для смены базовой папки |

## Вызов агентов

| Способ | Синтаксис |
|--------|-----------|
| **Slash** | `/agent` → выбор из списка → промпт |
| **Явный** | `Use the security-auditor agent on all files in /src` |
| **Неявный (триггер)** | `seccheck /src/app/` — совпадение с `description` |
| **CLI флаг** | `copilot --agent security-auditor --prompt "Check /src"` |

## Флаги управления инструментами

```bash
copilot --allow-all-tools           # Авто-одобрение всех инструментов
copilot --allow-tool='shell'        # Разрешить конкретный инструмент
copilot --deny-tool='shell(rm *)'   # Запретить (приоритет выше --allow)
copilot --available-tools='shell'   # Строгий белый список
copilot --yolo                      # Разрешить всё (tools + paths + urls)
```

## Субагенты

Кастомные агенты выполняются как временные **subagent** с изолированным контекстным окном. Основной агент делегирует задачи субагенту, разгружая свой контекст. Fleet mode — параллельный запуск нескольких субагентов.

## Шаблон (User-level)

```markdown
---
name: code-reviewer
description: "Review recently written code for bugs, security vulnerabilities, and performance issues. Trigger: review, code review, провери код, security audit."
tools: Read, Grep, Glob
---

You are a Senior Security & Performance Engineer with 15+ years of experience in identifying subtle bugs, security vulnerabilities, and performance bottlenecks.

## Core Responsibilities

### 1. BUG DETECTION
- Logic errors and incorrect algorithmic implementations
- Edge cases and boundary conditions
- Race conditions and concurrency issues
- Incorrect error handling and state management

### 2. SECURITY VULNERABILITIES
- OWASP Top 10 (injection, XSS, broken auth, CSRF)
- Hardcoded secrets, API keys, credentials
- Sensitive data exposure in logs or responses
- Insecure dependencies and supply chain risks

### 3. PERFORMANCE ISSUES
- O(n^2) algorithms, N+1 queries
- Resource leaks (connections, file handles, timers)
- Unnecessary re-renders and blocking operations

## Rules
- Be specific: reference exact file:line and code snippets
- Provide concrete fixes with code examples
- Explain risk/impact briefly
- Distinguish theoretical vs practical risks

## Output Format
## Code Review Summary
**Overall Assessment**: [Brief summary]

### Critical Issues
- **[File:Line]** — Issue description
  - **Impact**: What could go wrong
  - **Fix**: Concrete solution with code

### What's Good
[Acknowledge well-implemented aspects]

### Recommended Actions
[Prioritized list of improvements]
```

## Шаблон (Project-level, `.github/agents/`)

```markdown
---
name: code-reviewer
description: "Review code for bugs, security, and performance. Trigger: review, code review, провери код."
---

You are a Senior Developer on this team. Review code for:
- Bugs, edge cases, error handling
- Security: OWASP, secrets, injection
- Performance: algorithms, leaks, blocking ops

Reference file:line, provide fixes with code.
```

## Примеры вызова

```bash
# Slash-команда (интерактивный режим)
/agent → code-reviewer → "Review src/auth/"

# Явный запрос
Use the code-reviewer agent on src/auth/login.ts

# Неявный триггер (совпадение с description)
review this authentication code in src/auth/

# CLI флаг
copilot --agent code-reviewer --prompt "Review src/auth/ for security issues"
```

## Важные правила

- **Имя файла:** `lowercase-with-hyphens.agent.md` (из `name` поля)
- **Перезагрузка:** после добавления/изменения агента — **полный перезапуск CLI**
- **tools:** опционально. По умолчанию — все инструменты доступны
- **Установка:** `gh auth login --web && gh extension install github/gh-copilot --force`

## Частые ошибки

| Ошибка | Фикс |
|--------|------|
| `wrong file extension` | Должно быть `.agent.md`, не просто `.md` |
| `agent not loading after edit` | Полный перезапуск CLI (`exit` + новый запуск) |
| `name conflict: user vs project` | `~/.copilot/agents/` приоритетнее `.github/agents/` |
| `missing YAML frontmatter` | Добавить `---` с `name:`/`description:` |
