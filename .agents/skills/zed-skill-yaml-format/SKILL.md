---
name: zed-skill-yaml-format
description: "Строгие правила YAML frontmatter для Zed Agent Skills. Применяй при создании/редактировании любого SKILL.md, иначе Zed отвергнет скилл с Invalid YAML frontmatter. Триггеры: создай скилл, новый SKILL.md, поправь yaml, Invalid YAML frontmatter, скилл не загружается, zed skill format."
---

# Zed Skill YAML Format — строгие правила frontmatter

## Контекст

Zed Agent использует строгий YAML-парсер (`yaml-rust` / `serde_yaml`). Эталонные скиллы (`caveman`, `subagent-creator-universal`) пишут description **только в кавычках** или через folded scalar `>`. Свободный YAML в description Zed ломает.

**Симптомы:**
- `Invalid YAML frontmatter` — скилл не загружается
- `SKILL.md must start with YAML frontmatter (---)` — frontmatter отсутствует
- `SKILL.md missing closing frontmatter delimiter (---)` — нет закрывающего `---`

## Правила

### 1. Структура файла (обязательно)
```markdown
---
name: <kebab-case>
description: "<quoted string>"
---

# <Заголовок>
<тело скилла>
```

### 2. `name`
- Только `kebab-case` (маленькие буквы, цифры, дефисы)
- Без пробелов, без точек, без подчёркиваний
- Должно совпадать с именем директории

✅ `live-runner`, `git-secrets-precommit-scanner`, `zed-skill-yaml-format`
❌ `Live Runner`, `git_secrets`, `GitSecrets`

### 3. `description` — ВСЕГДА в двойных кавычках
Zed-парсер ломается на:
- Кириллических кавычках-ёлочках `«»`
- Внутренних `"..."` без экранирования
- Многострочном тексте без folded scalar

**Правило:** description — однострочный, в `"..."`, без `«»`, без переносов.

✅ **Правильно:**
```yaml
description: "Запуск скриптов, серверов, тестов, билдов на лету. Триггеры: запусти, прогони, проверь, почини, останови."
```

❌ **Неправильно (словишь Invalid YAML):**
```yaml
description: Запуск скриптов, серверов. Триггеры: «запусти», «прогони».
description: Запуск скриптов: серверов (двоеточие + не-quoted ломает парсер)
```

### 4. Если description длинный (>120 символов) — folded scalar `>`
```yaml
description: >
  Ultra-compressed communication mode. Slash token usage ~75%.
  Use when user says caveman mode, talk like caveman, or invokes /caveman.
```

### 5. Закрывающий `---` обязателен
Парсер ищет пару `---` ... `---`. Без закрывающего — ошибка.

### 6. Пустая строка после закрывающего `---`
Между `---` и `# Заголовок` — одна пустая строка.

## Чеклист перед сохранением SKILL.md

- [ ] Файл начинается с `---` на первой строке
- [ ] `name: <kebab-case>` совпадает с именем папки
- [ ] `description: "<строка>"` — в кавычках, без `«»`
- [ ] Закрывающий `---` есть
- [ ] После `---` пустая строка
- [ ] Длина description ≤ 200 символов (или folded scalar `>`)

## Эталоны в репо

Рабочие форматы — смотри:
- `~/.agents/skills/caveman/SKILL.md` (folded scalar)
- `~/.agents/skills/subagent-creator-universal/SKILL.md` (quoted)

## Алгоритм исправления «Invalid YAML frontmatter»

1. Открой SKILL.md
2. Найди строку `description:`
3. Оберни значение в `"..."` (замени `«»` на запятые)
4. Если есть переносы — замени на folded scalar `>` или склей в одну строку
5. Проверь закрывающий `---`
6. Перезапусти Zed

## Примеры

### ✅ Правильный скилл
```markdown
---
name: my-skill
description: "Краткое описание скилла и триггеры. Триггеры: сделай X, запусти Y, проверь Z."
---

# My Skill

## Алгоритм
...
```

### ❌ Сломанный (Invalid YAML)
```markdown
---
name: my-skill
description: Краткое описание. Триггеры: «сделай X», «запусти Y».
---
```

Причина: `«»` ломают парсер + нет кавычек.

## Ссылки
- Эталон: `~/.agents/skills/caveman/SKILL.md`
- Эталон: `~/.agents/skills/subagent-creator-universal/SKILL.md`
- AGENTS.md правило #2 (думай как умно)
