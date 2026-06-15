---
name: subagent-creator-universal
description: "Создание кастомных субагентов для ЛЮБОГО AI CLI: Qwen Code, Codex, Claude Code, Factory Droid, Gemini CLI, OpenCode, GitHub Copilot CLI. Use when: создать агент, subagent, custom agent, сабагент, агент для CLI, кастомный субагент, agent for CLI, copilot agent"
---

# Subagent Creator Universal

Маршрутизатор. Определи нужный CLI → читай только соответствующий подскилл.

## Таблица CLI

| CLI | Подскилл | Папка | Формат | Файл |
|-----|----------|-------|--------|------|
| **Qwen Code** | [`cli/qwen-code.md`](cli/qwen-code.md) | `~/.qwen/agents/` | `.md` + YAML frontmatter | `<name>.md` |
| **Codex CLI** | [`cli/codex.md`](cli/codex.md) | `~/.codex/agents/` | `.toml` | `<name>.toml` |
| **Claude Code** | [`cli/claude-code.md`](cli/claude-code.md) | `~/.claude/agents/` | `.md` + YAML frontmatter | `<name>.md` |
| **Factory Droid** | [`cli/factory-droid.md`](cli/factory-droid.md) | `.factory/droids/` | `.md` + YAML frontmatter | `<name>.md` |
| **Gemini CLI** | [`cli/gemini-cli.md`](cli/gemini-cli.md) | `AGENTS.md` в корне | Чистый `.md` | `AGENTS.md` или `GEMINI.md` |
| **OpenCode** | [`cli/opencode.md`](cli/opencode.md) | `~/.config/opencode/agents/` | `.md` + YAML frontmatter | `<name>.md` |
| **GitHub Copilot CLI** | [`cli/github-copilot.md`](cli/github-copilot.md) | `~/.copilot/agents/` или `.github/agents/` | `.agent.md` + YAML frontmatter | `<name>.agent.md` |

## Обязательные поля (сводка)

Подробности — в каждом подскилле.

| Поле | Qwen | Codex | Claude | F-Droid | Gemini | OpenCode | Copilot |
|------|------|-------|--------|---------|--------|----------|---------|
| `name` | ✅ | ✅ | ✅ | ✅ | — | — | ✅ |
| `description` | ✅ | ✅ | ✅ | ❌ opt | — | ✅ | ✅ |
| `color` | ✅ | ❌ | ❌ | ❌ | — | ❌ opt | ❌ |
| `model` | ❌ | ✅ | ❌ | ❌ inherit | — | ❌ opt | ❌ |
| `tools` | ❌ hint | ❌ | ✅ | ✅ | — | ❌ | ✅ opt |
| `mode` | ❌ | ❌ | ❌ | ❌ | — | ✅ | ❌ |
| `permission` | ❌ | ❌ | ❌ | ❌ | — | ✅ | ❌ |
| `sandbox_mode` | ❌ | ✅ | ❌ | ❌ | — | ❌ | ❌ |

## Процесс создания

1. **Определи CLI** — спроси пользователя или используй контекст
2. **Прочитай подскилл** — только нужный `cli/<cli>.md`
3. **Определи роль** — имя, экспертиза, тулы, sandbox/permission
4. **Прочитай `master-template.md`** — единый источник для генерации
5. **Сгенерируй файл** по формату из подскилла
6. **Положи** в правильную папку
7. **Перезапусти** CLI для загрузки агентов

## Золотое правило

**Создавать агентов ТОЛЬКО для того CLI, который явно просит пользователь.**

- ❌ НЕ создавать файлы для всех CLI сразу
- ❌ НЕ дублировать в Codex/Claude если просили только Qwen
- ✅ Спросить: «Для какого CLI создать агента?» если неясно
- ✅ По умолчанию — Qwen Code (текущий контекст)
- ✅ Если «для Codex» — только Codex
- ✅ Если «для Copilot CLI» — только `~/.copilot/agents/` или `.github/agents/`

## Подскиллы

| Файл | Назначение |
|------|-----------|
| [`master-template.md`](master-template.md) | Мастер-шаблон — единый источник → генерация во все форматы |
| [`troubleshooting.md`](troubleshooting.md) | Частые ошибки и фиксы для всех CLI |
