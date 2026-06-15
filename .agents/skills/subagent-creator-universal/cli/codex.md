# Codex CLI — Subagent Format

## Путь и формат

`~/.codex/agents/<name>.toml` — TOML формат

## Обязательные поля

| Поле | Описание |
|------|----------|
| `name` | Имя агента |
| `description` | Описание + триггеры |
| `model` | Модель (напр. `gpt-5.4-codex`) |
| `model_reasoning_effort` | Уровень рассуждения |
| `sandbox_mode` | Изоляция |
| `developer_instructions` | Тело промпта (многострочная строка `"""..."""`) |

## sandbox_mode

| Значение | Права | Для каких агентов |
|----------|-------|-------------------|
| `read-only` | Только чтение | code-reviewer, security-auditor |
| `workspace-write` | Чтение + запись | debugger, refactor-architect, docs-writer |
| `danger-full-access` | Полный доступ + Bash | git-doctor, dependency-manager |

## model_reasoning_effort

| Значение | Когда |
|----------|-------|
| `low` | Простые задачи, форматирование |
| `medium` | Документация, git, рутина |
| `high` | Анализ кода, дебаг, архитектура |

## Шаблон

```toml
name = "code-reviewer"
description = "Review code for bugs, security, and performance issues. Trigger: review, code review, провери код, security."
model = "gpt-5.4-codex"
model_reasoning_effort = "high"
sandbox_mode = "read-only"

developer_instructions = """
You are a Senior Security & Performance Engineer with 15+ years of experience.

## Core Responsibilities

### 1. BUG DETECTION
- Logic errors, edge cases, race conditions
- Incorrect error handling, state management problems

### 2. SECURITY VULNERABILITIES
- OWASP Top 10 (injection, XSS, broken auth)
- Hardcoded secrets, sensitive data exposure

### 3. PERFORMANCE ISSUES
- O(n^2) algorithms, N+1 queries
- Resource leaks (connections, file handles)

## Rules
- Be specific: reference exact line numbers
- Provide solutions with code examples
- Explain why: briefly describe risk/impact
- Distinguish theoretical vs practical risks

## Output Format
- Code Review Summary
- Issues by severity: File:Line → Issue → Impact → Fix
- What's Good + Recommended Actions
"""
```

## Частые ошибки

| Ошибка | Фикс |
|--------|------|
| `unknown variant 'relaxed'` | Использовать `read-only` / `workspace-write` / `danger-full-access` |
| `mapping values not allowed` | Обернуть `description` с `:` в кавычки `"..."` |
| TOML parse error | Проверить кавычки, многострочные `"""`, отсутствие YAML-синтаксиса |
