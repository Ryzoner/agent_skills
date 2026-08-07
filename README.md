# Ryzoner/agent_skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-76-blue.svg)](.agents/skills)
[![Examples](https://img.shields.io/badge/examples-14-green.svg)](.agents/ExampleSubagents)

**Global library of skills and example subagents for AI agents (Codex, Claude Code, Qwen Code, Cursor, OpenCode, Windsurf, Factory Droid, Gemini CLI).**

Everything from your local `~/.agents/skills/` is bundled here. Install on any device in **one command**.

---

## Quick install

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/Ryzoner/agent_skills/main/scripts/install.sh | bash
```

### Windows (PowerShell 5.1+)

```powershell
irm https://raw.githubusercontent.com/Ryzoner/agent_skills/main/scripts/install.ps1 | iex
```

The script:

1. Downloads the repo archive into a temp folder
2. Creates `~/.agents/skills/`, `~/.agents/ExampleSubagents/`, `~/.myskills/skills/`, `~/.notes/INBOX/`
3. Copies all 76 skills (no `node_modules`) and 14 example subagents
4. Runs `npm install` for skills with `package.json` (only `archify` at the moment)
5. Idempotent: safe to re-run for updates

After install, open your AI agent - it will pick up the skills automatically.

### Manual install

```bash
git clone https://github.com/Ryzoner/agent_skills.git
cd agent_skills
bash scripts/install.sh
# or on Windows:
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

### Install a single skill

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/Ryzoner/agent_skills.git
cd agent_skills
git sparse-checkout set .agents/skills/archify
cp -r .agents/skills/archify ~/.agents/skills/
```

---

## Repository structure

```
agent_skills/
├── .agents/
│   ├── skills/                    # 76 skills (global base)
│   │   ├── archify/               #   Diagrams: arch/workflow/seq/dataflow/lifecycle
│   │   ├── caveman/               #   Compressed communication (~75% token savings)
│   │   ├── engineering-principles/
│   │   ├── explain-complex-code/
│   │   └── ... (74 more)
│   └── ExampleSubagents/          # 14 example subagents (inspiration)
│       ├── code-reviewer.md
│       ├── security-auditor.md
│       └── meta/                  #   3 meta-agents
├── scripts/
│   ├── install.sh                 # Linux/macOS installer
│   └── install.ps1                # Windows installer
├── LICENSE                        # MIT
└── README.md                      # This file
```

---

## Skill categories

### Core and productivity

| Skill | Purpose |
|-------|---------|
| `caveman/` | Compressed communication, ~75% token savings. Default mode |
| `explain-complex-code/` | Code explanation in 3 modes: ELI5, Feynman, Gradual |
| `engineering-principles/` | SOLID, KISS, DRY, YAGNI in balance. Load before coding |
| `live-runner/` | Run scripts/servers/tests in real-time with monitoring |
| `logging-helper/` | Logging strategy for debugging and edge-case hunting |
| `skill-file-structure/` | Skill file organization pattern: SKILL.md + subfolders |
| `zed-skill-yaml-format/` | Strict YAML frontmatter rules for Zed Agent Skills |

### Architecture, design, documentation

| Skill | Purpose |
|-------|---------|
| `archify/` | arch/workflow/sequence/dataflow/lifecycle diagrams as self-contained HTML with theme + PNG/JPEG/WebP/SVG export |
| `critique/` | UX critique with quantitative scoring and personas |
| `avoid-ai-writing/` | Remove AI-patterns from text (AI-isms) |
| `project-bootstrap/` | Init project rules (AGENTS.md / CLAUDE.md / .cursorrules) |
| `external-resources-catalog/` | Catalog of skills, MCP servers, UI components |

### Specifications and workflow

| Skill | Purpose |
|-------|---------|
| `spec-mode/` | Structure work as Requirements / Design / Tasks |
| `kirospec-basic/` | KIRO-compatible specs from local scripts |
| `subagent-creator-universal/` | Create agents for 6+ CLIs (Qwen, Codex, Claude, OpenCode, Factory, Gemini) |

### Meta-orchestration (in `meta/`)

| Skill | Purpose |
|-------|---------|
| `meta/orchestration/spawn/` | Which subagents, when, how many to spawn |
| `meta/orchestration/synthesis/` | Collect results: dedupe, prioritize |
| `meta/orchestration/recovery/` | Handle failures: timeouts, fallback |
| `meta/orchestration/multi-session-worker/` | tmux workers, IPC via files |

### Security and secrets

| Skill | Purpose |
|-------|---------|
| `pr-prep-secret-guard/` | Mandatory secret scan before commit/push |
| `git-secrets-precommit-scanner/` | Pre-commit secret scanner (truffleHog + regex) |
| `patricio0312rev-secrets-scanner/` | Detector for API keys and tokens in code |
| `patricio0312rev-env-secrets-manager/` | Protect env-vars and secrets in CI/CD |
| `patricio0312rev-ci-cd-secrets/` | Manage secrets in pipelines |
| `scientiacapital-security/` | OWASP Top 10, auth patterns, RLS, input validation |
| `tob-agentic-actions-auditor/` | AI-agent security audit in CI/CD |
| `tob-insecure-defaults/` | Detect fail-open insecure defaults |
| `tob-sharp-edges/` | Detect error-prone APIs and footgun designs |
| `tob-supply-chain-risk-auditor/` | Dependency supply-chain risk audit |
| `tob-fp-check/` | Bug verification, false-positive elimination |
| `git-guardrails-claude-code/` | Block dangerous git commands via Claude Code hooks |

### Code audit and analysis

| Skill | Purpose |
|-------|---------|
| `tob-differential-review/` | Adversarial review of PR/commits/diffs with blast radius |
| `tob-static-analysis/` | Semgrep scan with parallel workers |
| `tob-semgrep-rule-creator/` | Create custom Semgrep rules |
| `deepsource-platform/` | DeepSource integration for code analysis |
| `deepsource-autofix-bot-api/` | DeepSource auto-fix API |
| `scientiacapital-git-workflow/` | Conventional commits, PR templates, branching |
| `pre-commit-setup/` | Pre-commit hooks: linter, formatter, complexity check |
| `setup-pre-commit/` | Husky + lint-staged pre-commit hooks (Prettier, tsc, tests) |
| `codex-cli-permissions-and-session-resume/` | Codex CLI permissions and session resume |
| `session-recall/` | Recover past Codex session context |

### Utilities and infrastructure

| Skill | Purpose |
|-------|---------|
| `agent-scraper-mcp/` | MCP server: web scraping with rate-limit + x402 middleware |
| `outline-vpn-basic/` | KISS Outline VPN operations on VPS |
| `v2raya-linux-basic/` | v2rayA on Linux (TUN, DNS, RoutingA) |
| `aa-install-module/` | Install/setup helper for AA modules |

### Engineering workflow (Matt Pocock)

| Skill | Purpose |
|-------|---------|
| `ask-matt/` | Router: which skill or flow fits your situation |
| `setup-matt-pocock-skills/` | One-time setup: issue tracker, labels, domain docs |
| `code-review/` | Review a branch on Standards + Spec axes (parallel) |
| `codebase-design/` | Deep-module vocabulary for designing interfaces |
| `domain-modeling/` | Pin down ubiquitous language, record ADRs |
| `diagnosing-bugs/` | Diagnosis loop for hard bugs and perf regressions |
| `grill-me/` | Relentless interview to sharpen a plan/design |
| `grill-with-docs/` | Grilling that also writes ADRs + glossary |
| `grilling/` | Stress-test a plan, decision, or idea |
| `handoff/` | Compact current conversation into a handoff doc |
| `implement/` | Implement work from a spec or set of tickets |
| `improve-codebase-architecture/` | Scan for deepening opportunities, grill the pick |
| `prototype/` | Throwaway prototype to answer a design question |
| `research/` | Investigate a question against primary sources |
| `resolving-merge-conflicts/` | Resolve in-progress git merge/rebase conflicts |
| `scaffold-exercises/` | Exercise directory structure that passes linting |
| `tdd/` | Test-driven development, red-green-refactor |
| `teach/` | Teach the user a new skill or concept |
| `to-spec/` | Turn the current conversation into a spec + publish |
| `to-tickets/` | Break a plan into tracer-bullet tickets with edges |
| `triage/` | Move issues/PRs through a triage state machine |
| `wayfinder/` | Plan huge work as a map of decision tickets |
| `writing-great-skills/` | Reference for writing and editing skills well |
| `migrate-to-shoehorn/` | Migrate test `as` assertions to @total-typescript/shoehorn |

### Interface and design (better-* series)

| Skill | Purpose |
|-------|---------|
| `better-interface/` | Holistic cross-discipline UI review (quick + full) |
| `better-accessibility/` | A11y: focus, keyboard, ARIA, forms, screen readers |
| `better-colors/` | OKLCH color space, palettes, contrast, theme tokens |
| `better-layout/` | Grouping, alignment, reading order, breakpoints |
| `better-typography/` | Fonts, type scale, wrapping, heading hierarchy |
| `better-ui/` | UI polish: animations, hover, shadows, micro-interactions |
| `better-writing/` | UX writing: button labels, errors, empty states |
| `beautify-github-readme/` | Redesign README homepages, SVG/PNG/GIF assets |
| `critique/` | UX critique with quantitative scoring and personas |

### Catalogs (inspiration, not active)

| Skill | Purpose |
|-------|---------|
| `awesome-agent-skills-catalog/` | Curated skills from various sources |
| `awesome-agent-skills-junmin/` | Domain-organized catalog (business, data, dev, ...) |

---

## Example subagents (`.agents/ExampleSubagents/`)

Unstructured examples, ready to be customized via `subagent-creator-universal`:

- `code-reviewer.md` - code review
- `complex-bug-debugger.md` - complex bug debugging
- `debugger.md` - quick debug
- `dependency-manager.md` - dependency management
- `docs-writer.md` - documentation writing
- `git-doctor.md` - git issue repair
- `onboarding-scout.md` - new codebase exploration
- `playwright-e2e-auditor.md` - E2E test audit
- `refactor-architect.md` - safe refactoring
- `release-manager.md` - release preparation
- `security-auditor.md` - security audit
- `test-architect.md` - test design

Meta-agents in `ExampleSubagents/meta/`:

- `agent-organizer.md`
- `onboarding-scout.md`
- `release-manager.md`

---

## Installation target

After running `install.sh` / `install.ps1`:

```
~/.agents/
├── skills/                          # 76 skills
│   ├── archify/
│   ├── caveman/
│   └── ... (74 more)
└── ExampleSubagents/                # 14 examples
    ├── code-reviewer.md
    └── meta/

~/.myskills/skills/                  # For your own skills (created later)
~/.notes/INBOX/                      # Global INBOX for notes
```

**Important:**

- `.agents/skills/` - only external/downloaded skills (this repo)
- `.myskills/skills/` - only your own skills (AI creates here on your request)
- `~/.notes/INBOX/` - drop raw `.md` files here, AI will sort by topic

---

## How AI uses these skills

Each skill contains `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: When to use, which phrases trigger it
license: MIT
---
```

When you say a phrase matching the `description` (or explicit triggers in the Triggers section), the agent loads `SKILL.md` via the `skill` tool and follows its rules.

Example triggers:

- "explain", "break it down" → `explain-complex-code/`
- "write code", "refactor", "design" → `engineering-principles/`
- "draw a diagram", "architecture" → `archify/`
- "check secrets before commit" → `pr-prep-secret-guard/`
- "create a subagent for Claude Code" → `subagent-creator-universal/`

---

## Updating

To update all skills to the latest version - just re-run the installer. It overwrites existing skill folders with fresh copies from the repo.

```bash
# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/Ryzoner/agent_skills/main/scripts/install.sh | bash

# Windows
irm https://raw.githubusercontent.com/Ryzoner/agent_skills/main/scripts/install.ps1 | iex
```

If you modified `.agents/skills/<name>/` locally - **save a copy** before updating, otherwise it will be overwritten.

---

## Adding a new skill

1. Create a folder in `.agents/skills/<name>/` with `SKILL.md` (valid YAML frontmatter, see `zed-skill-yaml-format/`)
2. Add a row to the table in this README
3. Commit & push - done, all users get the update on next install run

Template:

```bash
mkdir -p .agents/skills/my-new-skill
```

```markdown
---
name: my-new-skill
description: Short description with triggers in English
license: MIT
---

# My New Skill

Detailed description...
```

---

## License

MIT - do what you want, keep the copyright notice.

Skills inside the repo may have their own licenses (check `LICENSE` in each folder). Most are MIT, some are Apache-2.0.

---

## Credits

- `caveman` - original by JuliusBrussee
- `subagent-creator-universal` - concept by smartcaveman1
- Trail of Bits - `tob-*` security skills
- tt-a1i - `archify` for diagrams

---

## Repository

https://github.com/Ryzoner/agent_skills
