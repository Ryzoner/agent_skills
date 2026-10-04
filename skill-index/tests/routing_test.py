#!/usr/bin/env python3
"""Routing test for skill-index.

  python routing_test.py batches <sandbox_home> <out_dir> [n_batches]   write prompts for cold subagents
  python routing_test.py score   <sandbox_home> <out_dir>               score results/batch_*.json

A cold agent gets only the AGENTS.md routing rule and the task. It must route through the index and report
the skills it would apply plus a proof line read from each SKILL.md. Expected skills are listed per task.
"""
import fnmatch, json, random, re, sys
from pathlib import Path

# (id, task, [acceptable skills, globs allowed])
CASES = [
 ("mod-any-game", "Хочу сделать мод для Terraria: добавить новое оружие. С чего начать?", ["mod-any-game"]),
 ("game-recon", "Определи, на каком движке игра в папке D:/Games/Foo и есть ли в ней античит.", ["game-recon"]),
 ("reverse-engineering", "Нужно декомпилировать .NET-сборку игры и разобрать формат её файла сохранений.", ["reverse-engineering"]),
 ("asset-pipeline", "Подготовь спрайт для игры: вырежи фон, подгони под 64x64 и собери спрайт-лист.", ["asset-pipeline"]),
 ("game-automation", "Запусти игру, сними скриншот окна и закрой окно краш-репортера.", ["game-automation"]),
 ("showcase-video", "Нарежь ролик-демонстрацию мода из записи экрана, музыка по битам.", ["showcase-video"]),
 ("mashup-mods", "Хочу перенести механику Minecraft внутрь GTA V как мод.", ["mashup-mods"]),
 ("publish-mod", "Проверь мод перед публикацией, упакуй и подготовь credits.", ["publish-mod"]),
 ("share-field-notes", "Запиши, что я узнал при моддинге игры, как заметку для следующего агента и открой PR.", ["share-field-notes"]),
 ("gemini-assets", "Мне нужны иконки предметов для мода: напиши промпты, картинки я сгенерирую в Gemini.", ["gemini-assets"]),
 ("sprite-forge", "Из этого пиксель-арт персонажа сделай новую позу и цикл ходьбы.", ["sprite-forge"]),
 ("pixel-art", "Нарисуй пиксель-арт меч 16x16 кодом, без ИИ-моделей.", ["pixel-art"]),
 ("parametric-3d-printing", "Спроектируй параметрический корпус для Arduino под 3D-печать, на выходе STL.", ["parametric-3d-printing"]),
 ("hyperframes", "Сделай 15-секундный промо-ролик из HTML для моего проекта.", ["hyperframes"]),
 ("hyperframes-cli", "Рендер hyperframes падает с ошибкой, разберись с CLI: lint, preview, render.", ["hyperframes-cli", "hyperframes"]),
 ("hyperframes-core", "Как устроен HTML композиции для рендера видео: data-атрибуты, треки, клипы?", ["hyperframes-core", "hyperframes"]),
 ("hyperframes-creative", "Подбери палитру, типографику и план битов для видеоролика.", ["hyperframes-creative", "hyperframes"]),
 ("media-use", "Найди фоновую музыку и звуковые эффекты и сделай озвучку для видео.", ["media-use"]),
 ("motion-graphics", "Сделай 6-секундную анимацию: счётчик статистики и кинетическая типографика.", ["motion-graphics"]),
 ("terraform-style-guide", "Перепиши мой Terraform-код по официальному стилю HashiCorp.", ["terraform-style-guide"]),
 ("terraform-test", "Напиши тесты .tftest.hcl для моего модуля с моками провайдера.", ["terraform-test"]),
 ("refactor-module", "У меня один огромный main.tf, разбей его на переиспользуемые модули.", ["refactor-module", "terraform-module-library"]),
 ("terraform-stacks", "Настрой Terraform Stack на несколько регионов (tfcomponent.hcl).", ["terraform-stacks"]),
 ("terraform-search-import", "В облаке есть ресурсы вне Terraform: найди их и массово импортируй.", ["terraform-search-import"]),
 ("terraform-policy", "Сконвертируй мои Sentinel-политики в формат .policy.hcl.", ["terraform-policy"]),
 ("terraform-module-library", "Собери библиотеку переиспользуемых Terraform-модулей для AWS и Azure.", ["terraform-module-library", "refactor-module"]),
 ("kubernetes-skill", "Проверь мои Kubernetes-манифесты на небезопасные дефолты и типичные ошибки.", ["kubernetes-skill", "k8s-security-policies"]),
 ("k8s-manifest-generator", "Сгенерируй продакшен-манифесты Deployment, Service и ConfigMap для моего приложения.", ["k8s-manifest-generator", "kubernetes-skill"]),
 ("k8s-security-policies", "Настрой NetworkPolicy и RBAC в кластере, изолируй неймспейсы.", ["k8s-security-policies"]),
 ("helm-chart-scaffolding", "Упакуй приложение в Helm-чарт с values и шаблонами.", ["helm-chart-scaffolding"]),
 ("gitops-workflow", "Настрой ArgoCD, чтобы кластер сам синхронизировался с git.", ["gitops-workflow"]),
 ("gitlab-ci-patterns", "Напиши .gitlab-ci.yml с несколькими стадиями, кешем и раннерами.", ["gitlab-ci-patterns"]),
 ("deployment-pipeline-design", "Спроектируй пайплайн деплоя с approval-гейтами и канареечным выкатом.", ["deployment-pipeline-design"]),
 ("patricio0312rev-ci-cd-secrets", "Проверь переменные окружения в CI и не допусти утечки секретов в логах.", ["patricio0312rev-ci-cd-secrets", "secrets-management"]),
 ("docker-build-strategies", "Docker-образ слишком большой и собирается долго, оптимизируй Dockerfile.", ["docker-build-strategies"]),
 ("docker-compose-patterns", "Свяжи в docker compose приложение с базой и healthcheck'ами.", ["docker-compose-patterns"]),
 ("docker-destructive-guardrails", "Почисти докер полностью: удали все контейнеры, образы и тома, начнём с нуля.", ["docker-destructive-guardrails"]),
 ("docker-project-foundations", "Докеризуй проект с нуля: Dockerfile, compose и .dockerignore.", ["docker-project-foundations"]),
 ("docker-agent-config", "Напиши agent.yaml для Docker Agent: модели и инструменты.", ["docker-agent-config"]),
 ("docker-agent-deploy", "Выставь Docker Agent как MCP-сервер или HTTP API.", ["docker-agent-deploy"]),
 ("docker-agent-run", "Запусти docker agent run и выбери режим одобрения команд.", ["docker-agent-run"]),
 ("docker-sandboxes-env", "Опиши окружение песочницы Docker в sbxenv.yaml.", ["docker-sandboxes-env"]),
 ("docker-sandboxes-kits", "Упакуй и подпиши kit для Docker Sandboxes.", ["docker-sandboxes-kits"]),
 ("docker-sandboxes-lifecycle", "Создай, останови и удали Docker Sandbox, покажи список песочниц.", ["docker-sandboxes-lifecycle"]),
 ("docker-sandboxes-network-credentials", "Ограничь сетевой доступ песочницы sbx и пробрось ей учётные данные.", ["docker-sandboxes-network-credentials"]),
 ("prometheus-configuration", "Настрой Prometheus: сбор метрик и алерты для моих сервисов.", ["prometheus-configuration"]),
 ("grafana-dashboards", "Нарисуй Grafana-дашборд для мониторинга API.", ["grafana-dashboards"]),
 ("slo-implementation", "Определи SLI и SLO с бюджетом ошибок и алертами.", ["slo-implementation"]),
 ("distributed-tracing", "Внедри трассировку запросов между микросервисами (Jaeger, Tempo).", ["distributed-tracing"]),
 ("incident-runbook-templates", "Напиши ранбук на случай падения платёжного сервиса.", ["incident-runbook-templates"]),
 ("postmortem-writing", "Помоги написать постмортем без поиска виноватых по вчерашнему инциденту.", ["postmortem-writing"]),
 ("on-call-handoff-patterns", "Составь передачу дежурства коллеге: активные инциденты и контекст.", ["on-call-handoff-patterns"]),
 ("bash-defensive-patterns", "Перепиши bash-скрипт бэкапа надёжнее: set -euo pipefail, ловушки, проверки.", ["bash-defensive-patterns"]),
 ("shellcheck-configuration", "Настрой ShellCheck в проекте и почини его предупреждения.", ["shellcheck-configuration"]),
 ("bats-testing-patterns", "Напиши автотесты для shell-скриптов на bats.", ["bats-testing-patterns"]),
 ("outline-vpn-basic", "Подними Outline VPN на VPS и выдай ключи пользователям.", ["outline-vpn-basic"]),
 ("v2raya-linux-basic", "Настрой v2rayA с TUN на Ubuntu.", ["v2raya-linux-basic"]),
 ("pinme", "Выложи статичный лендинг в интернет одной командой, без серверов.", ["pinme"]),
 ("connectivity-triage", "На маке пропадает DNS и таймаутятся API-запросы, найди где сбой.", ["connectivity-triage"]),
 ("tob-agentic-actions-auditor", "Проверь мои GitHub Actions workflow на уязвимости, связанные с ИИ-агентами.", ["tob-agentic-actions-auditor"]),
 ("tob-differential-review", "Сделай security-ревью диффа PR с оценкой радиуса поражения.", ["tob-differential-review"]),
 ("tob-fp-check", "Проверь: эта находка безопасности реальная или ложное срабатывание?", ["tob-fp-check"]),
 ("tob-insecure-defaults", "Найди небезопасные дефолты: зашитые секреты, слабая криптография, fail-open.", ["tob-insecure-defaults"]),
 ("tob-semgrep-rule-creator", "Напиши кастомное правило Semgrep для нашего антипаттерна.", ["tob-semgrep-rule-creator"]),
 ("tob-sharp-edges", "Какие API в этом коде опасны и провоцируют ошибки (footguns)?", ["tob-sharp-edges"]),
 ("tob-static-analysis", "Запусти Semgrep по репозиторию и дай отчёт.", ["tob-static-analysis"]),
 ("tob-supply-chain-risk-auditor", "Оцени риски зависимостей проекта: цепочка поставок.", ["tob-supply-chain-risk-auditor"]),
 ("security-threat-model", "Построй модель угроз для этого репозитория: границы доверия и векторы атаки.", ["security-threat-model"]),
 ("scientiacapital-security", "Проверь аутентификацию, RLS и валидацию ввода по OWASP Top 10.", ["scientiacapital-security"]),
 ("deepsource-platform", "Достань результаты DeepSource по ревью: проблемы и уязвимости.", ["deepsource-platform"]),
 ("deepsource-autofix-bot-api", "Прогони код через DeepSource и примени автофиксы.", ["deepsource-autofix-bot-api", "deepsource-platform"]),
 ("sast-configuration", "Подключи SAST в пайплайн и настрой инструменты статического анализа безопасности.", ["sast-configuration"]),
 ("git-secrets-precommit-scanner", "Просканируй git diff на утечки секретов перед коммитом (truffleHog).", ["git-secrets-precommit-scanner", "pr-prep-secret-guard"]),
 ("pr-prep-secret-guard", "Я собираюсь делать git push: убедись, что секретов в изменениях нет.", ["pr-prep-secret-guard", "git-secrets-precommit-scanner"]),
 ("patricio0312rev-env-secrets-manager", "Как безопасно хранить переменные окружения и секреты с шифрованием?", ["patricio0312rev-env-secrets-manager", "secrets-management"]),
 ("patricio0312rev-secrets-scanner", "Найди в коде утёкшие API-ключи, токены и пароли.", ["patricio0312rev-secrets-scanner", "git-secrets-precommit-scanner"]),
 ("secrets-management", "Внедри Vault для секретов в CI/CD и ротацию.", ["secrets-management"]),
 ("gitx", "Преврати мои незакоммиченные изменения в аккуратные коммиты с понятными сообщениями.", ["gitx", "scientiacapital-git-workflow"]),
 ("yeet", "Закоммить, запушь и открой pull request одной командой.", ["yeet", "gitx"]),
 ("resolving-merge-conflicts", "Я посреди rebase: помоги разрешить конфликты слияния.", ["resolving-merge-conflicts"]),
 ("using-git-worktrees", "Хочу работать над фичей изолированно, не трогая текущую ветку: нужен worktree.", ["using-git-worktrees"]),
 ("scientiacapital-git-workflow", "Какие использовать conventional commits, имена веток и шаблон PR?", ["scientiacapital-git-workflow", "gitx"]),
 ("git-guardrails-claude-code", "Заблокируй опасные git-команды (push --force, reset --hard) хуками Claude Code.", ["git-guardrails-claude-code"]),
 ("pre-commit-setup", "Настрой pre-commit хуки: линтер, форматтер, проверка сложности кода.", ["pre-commit-setup", "setup-pre-commit"]),
 ("setup-pre-commit", "Настрой Husky pre-commit с lint-staged, Prettier и проверкой типов.", ["setup-pre-commit", "pre-commit-setup"]),
 ("systematic-debugging", "Тест падает необъяснимо: найди первопричину, а не симптом.", ["systematic-debugging", "diagnosing-bugs"]),
 ("diagnosing-bugs", "Сложная регрессия производительности: нужен цикл диагностики.", ["diagnosing-bugs", "systematic-debugging"]),
 ("live-runner", "Запусти сервер и тесты в фоне и следи за выводом в реальном времени.", ["live-runner"]),
 ("logging-helper", "Добавь нормальное логирование: уровни, формат, отладка edge-кейсов.", ["logging-helper"]),
 ("engineering-principles", "Спроектируй структуру нового сервиса и напиши код по SOLID, KISS, DRY.", ["engineering-principles"]),
 ("ponytail", "Нужно самое простое рабочее решение, без лишних абстракций.", ["ponytail", "engineering-principles"]),
 ("tdd", "Реализуй функцию через test-driven development: сначала тесты.", ["tdd"]),
 ("implement", "Реализуй работу по этой спецификации и набору тикетов.", ["implement"]),
 ("code-review", "Проверь изменения с прошлого коммита на ошибки.", ["code-review"]),
 ("codebase-design", "Как проектировать глубокие модули с простым интерфейсом?", ["codebase-design", "improve-codebase-architecture"]),
 ("improve-codebase-architecture", "Просканируй кодовую базу и найди, где можно улучшить архитектуру.", ["improve-codebase-architecture", "codebase-design"]),
 ("search-first", "Мне нужна библиотека для разбора cron-выражений: проверь, нет ли готовой, прежде чем писать своё.", ["search-first"]),
 ("dotnet-patterns", "Напиши идиоматичный C#: DI, async/await, конвенции .NET.", ["dotnet-patterns"]),
 ("migrate-to-shoehorn", "Замени приведения `as` в тестах на @total-typescript/shoehorn.", ["migrate-to-shoehorn"]),
 ("verification-loop", "Я закончил фичу: прогони сборку, типы, линтер, тесты и ревью диффа.", ["verification-loop"]),
 ("scaffold-exercises", "Создай структуру учебных упражнений с разделами и задачами.", ["scaffold-exercises"]),
 ("explain-complex-code", "Объясни простыми словами, как работает этот сложный код (eli5).", ["explain-complex-code"]),
 ("teach", "Научи меня новой концепции прямо в этом воркспейсе.", ["teach"]),
 ("brainstorming", "Хочу добавить новую фичу: давай сначала обсудим, что именно нужно.", ["brainstorming"]),
 ("writing-plans", "У меня есть требования к многошаговой задаче: составь пошаговый план реализации.", ["writing-plans"]),
 ("spec-mode", "Оформи работу как Requirements, Design и Tasks.", ["spec-mode", "kirospec-basic"]),
 ("kirospec-basic", "Создай .kiro-спецификации из локальных скриптов.", ["kirospec-basic", "spec-mode"]),
 ("to-spec", "Преврати наш разговор в спецификацию и опубликуй её в трекер.", ["to-spec"]),
 ("to-tickets", "Разбей этот план на набор тикетов.", ["to-tickets"]),
 ("wayfinder", "Спланируй огромный объём работы, который не поместится в одну сессию агента.", ["wayfinder"]),
 ("grill-me", "Безжалостно поинтервьюируй меня, чтобы отточить мой план.", ["grill-me", "grilling"]),
 ("grilling", "Допроси меня про это решение, пока не найдёшь слабые места.", ["grilling", "grill-me"]),
 ("grill-with-docs", "Поинтервьюируй меня про план и обнови документацию проекта по моим ответам.", ["grill-with-docs"]),
 ("prototype", "Сделай одноразовый прототип, чтобы ответить на дизайн-вопрос.", ["prototype"]),
 ("ask-matt", "Подскажи, какой из навыков или процессов подходит к моей ситуации.", ["ask-matt", "skills-discovery"]),
 ("triage", "Разгреби входящие issue и внешние PR по состояниям триажа.", ["triage"]),
 ("setup-matt-pocock-skills", "Настрой репозиторий под инженерные скиллы: трекер, лейблы, документы.", ["setup-matt-pocock-skills"]),
 ("domain-modeling", "Уточни доменную модель проекта и словарь терминов.", ["domain-modeling"]),
 ("frontend-design", "Сделай красивый, запоминающийся интерфейс для веб-приложения.", ["frontend-design", "design-taste-frontend"]),
 ("design-taste-frontend", "Сверстай лендинг-портфолио, чтобы не выглядел шаблонным ИИ-слопом.", ["design-taste-frontend", "frontend-design"]),
 ("redesign-existing-projects", "Подтяни существующий сайт до премиального качества, не ломая функциональность.", ["redesign-existing-projects"]),
 ("minimalist-ui", "Нужен чистый редакторский минимализм: тёплая монохромная палитра.", ["minimalist-ui"]),
 ("high-end-visual-design", "Сделай дизайн как у дорогого агентства: шрифты, тени, анимации.", ["high-end-visual-design"]),
 ("industrial-brutalist-ui", "Хочу брутальный индустриальный интерфейс дашборда в стиле терминала.", ["industrial-brutalist-ui"]),
 ("critique", "Оцени UX этого экрана: иерархия, персоны, оценка по баллам.", ["critique", "better-interface"]),
 ("better-accessibility", "Проверь доступность интерфейса: фокус, клавиатура, скринридеры.", ["better-accessibility"]),
 ("better-colors", "Подбери цвета в OKLCH и сконвертируй hex-палитру.", ["better-colors"]),
 ("better-interface", "Сделай междисциплинарное ревью интерфейса.", ["better-interface", "critique"]),
 ("better-layout", "Улучши компоновку веб-страницы: группировка и отступы.", ["better-layout"]),
 ("better-typography", "Подбери шрифты и настрой межстрочные интервалы и переносы.", ["better-typography"]),
 ("better-ui", "Что сделать, чтобы интерфейс ощущался отполированным?", ["better-ui", "better-interface"]),
 ("better-writing", "Улучши тексты интерфейса: подписи кнопок и тон голоса.", ["better-writing"]),
 ("beautify-github-readme", "Перепроектируй README проекта на GitHub, чтобы выглядел красиво.", ["beautify-github-readme"]),
 ("archify", "Нарисуй диаграмму архитектуры и потоков данных как HTML с экспортом в PNG.", ["archify", "diagram-design"]),
 ("diagram-design", "Сделай редакторскую диаграмму (Sankey, fishbone или ER) под стиль бренда.", ["diagram-design", "archify"]),
 ("json-canvas", "Создай .canvas файл с узлами и связями для Obsidian.", ["json-canvas"]),
 ("docx", "Подготовь Word-документ с таблицей и заголовками.", ["docx"]),
 ("pdf", "Извлеки текст и таблицы из PDF и объедини два PDF.", ["pdf"]),
 ("pptx", "Собери презентацию на 10 слайдов.", ["pptx"]),
 ("xlsx", "Почисти таблицу Excel и добавь формулы.", ["xlsx"]),
 ("knap", "Отрендери Markdown из шаблона и структурированных данных.", ["knap"]),
 ("obsidian-bases", "Создай .base файл Obsidian с видами и фильтрами.", ["obsidian-bases"]),
 ("obsidian-cli", "Прочитай и создай заметки в Obsidian vault через CLI.", ["obsidian-cli"]),
 ("obsidian-markdown", "Напиши заметку в разметке Obsidian с wikilinks и callouts.", ["obsidian-markdown"]),
 ("defuddle", "Достань чистый Markdown из HTML-страницы статьи.", ["defuddle"]),
 ("research", "Исследуй вопрос по первоисточникам и дай выводы с цитатами.", ["research", "content-research-writer"]),
 ("content-research-writer", "Помоги написать лонгрид: исследование, структура, черновики по разделам.", ["content-research-writer", "research"]),
 ("avoid-ai-writing", "Перепиши текст, убрав следы ИИ-стиля.", ["avoid-ai-writing"]),
 ("external-resources-catalog", "Найди каталог скиллов, MCP-серверов и UI-компонентов.", ["external-resources-catalog", "skills-discovery"]),
 ("context-budget", "Контекст раздувается: покажи, что именно его занимает.", ["context-budget"]),
 ("strategic-compact", "В какой момент этой задачи лучше сделать compact контекста?", ["strategic-compact", "context-budget"]),
 ("session-recall", "Восстанови и перескажи мои прошлые разговоры с Codex.", ["session-recall", "codex-cli-*"]),
 ("codex-cli", "Как проверить режим доступа Codex и продолжить прошлую сессию?", ["codex-cli-*", "session-recall"]),
 ("skill-creator", "Создай новый скилл и протестируй его.", ["skill-creator", "writing-great-skills"]),
 ("writing-great-skills", "Как правильно писать и редактировать скиллы: словарь и принципы?", ["writing-great-skills", "skill-creator"]),
 ("skill-file-structure", "Как организовать файлы скилла: SKILL.md и подпапки?", ["skill-file-structure", "writing-great-skills"]),
 ("zed-skill-yaml-format", "Zed пишет Invalid YAML frontmatter для моего SKILL.md.", ["zed-skill-yaml-format"]),
 ("subagent-creator-universal", "Создай кастомного субагента для Qwen Code и Codex.", ["subagent-creator-universal"]),
 ("project-bootstrap", "Инициализируй правила проекта: AGENTS.md, CLAUDE.md, .cursorrules.", ["project-bootstrap"]),
 ("skills-discovery", "Найди и установи агентский скилл, который умеет работать с PDF-формами в Zed.", ["skills-discovery", "external-resources-catalog"]),
 # cross-cutting and negatives
 ("X-code+tests", "Напиши на Python функцию парсинга логов и тесты к ней.", ["engineering-principles", "tdd"]),
 ("X-done+push", "Фича готова. Делаю коммит и пуш в main, проверь всё перед этим.", ["verification-loop", "pr-prep-secret-guard"]),
 ("X-bug", "Скрипт иногда падает с KeyError, не пойму почему.", ["systematic-debugging", "diagnosing-bugs"]),
 ("R-handoff", "Запиши документ передачи контекста, чтобы следующая сессия агента продолжила эту работу.", ["handoff"]),
 ("N-greeting", "Привет! Как дела?", []),
 ("N-math", "Сколько будет 17 умножить на 23?", []),
 ("N-translate", "Переведи на английский: «доброе утро».", []),
 ("N-capital", "Какая столица Австралии?", []),
]

REGISTERED_NOTE = "caveman, caveman-stats, handoff, half-clone, quarter-clone, skill-router stay registered and are not tested here."

RULE = """## Маршрутизация скиллов
Скиллы не загружены в контекст. Они лежат в библиотеке `{lib}/<имя>/SKILL.md`, индекс скиллов: `{idx}/INDEX.md`.
Перед нетривиальной задачей (код, инфраструктура, документы, дизайн, отладка, git, безопасность, моддинг, медиа):
1. Прочитай INDEX.md. Сначала раздел Cross-cutting: он относится почти к любой задаче.
2. Выбери до 2 тем, прочитай `{idx}/groups/<тема>.md`.
3. Выбери до 3 скиллов, прочитай их SKILL.md целиком и следуй им.
4. Одной строкой сообщи: `Скиллы: a, b`.
Простые вопросы и болтовня: индекс не читать, скиллы не нужны. Нет подходящей темы: работай без скиллов, не угадывай по памяти."""

PROMPT = """You are a fresh agent. You know nothing about any skills in advance. Your standing instructions (from AGENTS.md) are:

{rule}

TEST MODE (this is a routing test, not real work):
- Do NOT perform the tasks. For each task only do the routing described above and report your choice.
- The ONLY way to find skills is the index. Do not use the Skill tool. Do not list, find or grep the skill library or the home directory broadly; read only INDEX.md, group files and the SKILL.md files you pick.
- Test deviation: read only the FIRST 30 lines of each chosen SKILL.md (Read with limit 30), not the whole file.
- You have {n} tasks. Read INDEX.md once, then handle every task independently.
- For each task output one JSON object with: "id", "trivial" (true if no skills are needed), "topics" (group names you opened), "skills" (list of objects {{"name": ..., "proof": ...}}) where proof is the exact first non-empty line of the SKILL.md body AFTER the closing --- of the frontmatter, copied verbatim.
- Write all objects as a JSON array to this file with the Write tool: {out}
- Then reply with only: done, and the number of tasks written.

TASKS:
{tasks}
"""


def sandbox_paths(sb):
    sb = Path(sb)
    return sb / ".agents" / "skill-library", sb / ".agents" / "skill-index"


def cmd_batches(sb, out, n=12, only=None):
    lib, idx = sandbox_paths(sb)
    out = Path(out)
    (out / "prompts").mkdir(parents=True, exist_ok=True)
    (out / "results").mkdir(exist_ok=True)
    cases = [c for c in CASES if not only or any(fnmatch.fnmatch(c[0], o) for o in only)]
    random.Random(7).shuffle(cases)
    idmap = {}
    for k, c in enumerate(cases):
        idmap["T%03d" % (k + 1)] = c[0]
    (out / "idmap.json").write_text(json.dumps(idmap, indent=1), encoding="utf-8")
    rev = {v: k for k, v in idmap.items()}
    for i in range(n):
        part = cases[i::n]
        tasks = "\n".join("%s. %s" % (rev[c[0]], c[1]) for c in part)
        res = out / "results" / ("batch_%02d.json" % i)
        (out / "prompts" / ("batch_%02d.txt" % i)).write_text(
            PROMPT.format(rule=RULE.format(lib=lib, idx=idx), n=len(part), out=res, tasks=tasks), encoding="utf-8")
    print("wrote", n, "prompts for", len(cases), "cases to", out / "prompts")


def proof_line(skill_dir):
    t = (Path(skill_dir) / "SKILL.md").read_text(encoding="utf-8", errors="ignore")
    m = re.match(r"---\r?\n.*?\r?\n---\r?\n(.*)", t, re.S)
    for line in (m.group(1) if m else t).splitlines():
        if line.strip():
            return line.strip()
    return ""


def norm(s):
    return re.sub(r"\s+", " ", s).strip().lower()[:40]


def cmd_score(sb, out):
    lib, _ = sandbox_paths(sb)
    out = Path(out)
    got = {}
    idmap = json.loads((out / "idmap.json").read_text(encoding="utf-8"))
    for f in sorted((out / "results").glob("batch_*.json")):
        try:
            for o in json.loads(f.read_text(encoding="utf-8")):
                got[idmap.get(o["id"], o["id"])] = o
        except Exception as e:
            print("unreadable", f.name, e)
    lib_names = {p.name for p in lib.iterdir() if p.is_dir()} | {"caveman", "caveman-stats", "handoff", "half-clone", "quarter-clone", "skill-router"}
    rows, fails, hall, noproof = [], [], [], []
    idset = set(idmap.values())
    for cid, task, expected in CASES:
        if cid not in idset:
            continue
        o = got.get(cid)
        if o is None:
            fails.append((cid, "NO ANSWER", [], expected)); continue
        names = [s["name"] for s in o.get("skills", [])]
        for s in o.get("skills", []):
            if s["name"] not in lib_names:
                hall.append((cid, s["name"]))
            elif (lib / s["name"]).is_dir() and norm(proof_line(lib / s["name"])) != norm(s.get("proof", "")):
                noproof.append((cid, s["name"]))
        if not expected:
            ok = not names
        else:
            ok = any(fnmatch.fnmatch(n, e) for n in names for e in expected)
            if cid.startswith("X-"):
                ok = all(any(fnmatch.fnmatch(n, e) for n in names) for e in expected[:2]) or ok
        rows.append((cid, ok))
        if not ok:
            fails.append((cid, task, names, expected))
    total = len(rows) + sum(1 for f in fails if f[1] == "NO ANSWER")
    passed = sum(1 for _, ok in rows if ok)
    print(f"answered: {len(got)}/{total}   routed correctly: {passed}/{total} ({100*passed//total}%)")
    print(f"hallucinated skill names: {len(hall)} {hall[:5]}")
    print(f"proof mismatches (did not read the SKILL.md?): {len(noproof)} {noproof[:6]}")
    print("failures:")
    for cid, task, names, expected in fails:
        print(f"  {cid}: chose {names or 'nothing'}  expected one of {expected or 'nothing'}")


def cmd_report(sb, out, dest, title):
    lib, _ = sandbox_paths(sb)
    out = Path(out)
    idmap = json.loads((out / "idmap.json").read_text(encoding="utf-8"))
    got = {}
    for f in sorted((out / "results").glob("batch_*.json")):
        for o in json.loads(f.read_text(encoding="utf-8")):
            got[idmap.get(o["id"], o["id"])] = o
    rev = {v: k for k, v in idmap.items()}
    rows, ok_n = [], 0
    for cid, task, expected in CASES:
        if cid not in rev:
            continue
        o = got.get(cid, {})
        names = [x["name"] for x in o.get("skills", [])]
        ok = (not names) if not expected else any(fnmatch.fnmatch(n, e) for n in names for e in expected)
        ok_n += ok
        rows.append("| %s | %s | %s | %s | %s | %s |" % (rev[cid], "✅" if ok else "❌", task.replace("|", "/"),
                    ", ".join(expected) or "—", ", ".join(names) or "—", ", ".join(o.get("topics", [])) or "—"))
    head = ["# %s" % title, "", "Passed %d of %d. Cold subagents (Sonnet 5.5), 12 batches, sandbox with the full library." % (ok_n, len(rows)), "",
            "| id | ok | task | expected (any of) | chosen | topics opened |", "|---|---|---|---|---|---|"]
    Path(dest).parent.mkdir(parents=True, exist_ok=True)
    Path(dest).write_text("\n".join(head + rows) + "\n", encoding="utf-8")
    print("report:", dest, ok_n, "/", len(rows))


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "batches":
        cmd_batches(a[1], a[2], int(a[3]) if len(a) > 3 else 12, a[4].split(",") if len(a) > 4 else None)
    elif a and a[0] == "report":
        cmd_report(a[1], a[2], a[3], a[4] if len(a) > 4 else "Routing test")
    elif a and a[0] == "score":
        cmd_score(a[1], a[2])
    else:
        sys.exit(__doc__)
