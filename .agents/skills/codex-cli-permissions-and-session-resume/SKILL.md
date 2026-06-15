---
name: codex-cli-permissions-and-session-resume
description: Use when the user asks how to check Codex access mode, continue the previous dialog instantly, use `codex resume`, or recover the latest session id from local Codex session files without rereading old chats.
---

# codex-cli-permissions-and-session-resume

Use this skill when:

- the user asks whether Codex currently has full access
- the user mentions `/permissions`, `FullAccess`, or similar access-mode wording
- the user wants to continue a previous Codex dialog immediately
- the user asks how to use `codex resume`
- the user asks how `codex fork` differs from `codex resume`
- the user wants the latest session id from local Codex session files

## Scope

This is a global Codex workflow, not a project-local one.
It belongs in `${CODEX_HOME:-$HOME/.codex}/skills/` because the commands and session layout are reusable across repos.

## Access-mode reminders

- In the interactive Codex UI, `/permissions` is the fast check for the current access mode.
- In the CLI help, the explicit full-open flag is `--dangerously-bypass-approvals-and-sandbox`.
- `--full-auto` is not the same thing. It still uses `workspace-write`.
- `resume` and `fork` accept the same global execution flags as a normal interactive launch.
- Prefer documented flags from `codex --help` over undocumented aliases.

## Fast resume commands

Prefer these:

```bash
codex resume <SESSION_UUID>
codex resume --last
codex fork <SESSION_UUID>
codex fork --last
codex resume --dangerously-bypass-approvals-and-sandbox <SESSION_UUID>
codex resume --dangerously-bypass-approvals-and-sandbox --last
```

Important:

- `codex resume` officially accepts a session UUID or thread name
- `codex fork` officially accepts a session UUID and creates a new branch of that prior session
- `codex resume` also accepts the same global execution flags such as `--dangerously-bypass-approvals-and-sandbox`
- prefer the UUID, not the `.jsonl` filename
- if the filename is `rollout-2026-03-21T22-54-32-019d122d-9c09-7572-addf-ee59fab48e1b.jsonl`, the preferred resume command is:

```bash
codex resume 019d122d-9c09-7572-addf-ee59fab48e1b
```

If you want the resumed session to stay in full-open style, use:

```bash
codex resume --dangerously-bypass-approvals-and-sandbox 019d122d-9c09-7572-addf-ee59fab48e1b
```

If you want a new branch of thought instead of continuing the same storyline, use:

```bash
codex fork 019d122d-9c09-7572-addf-ee59fab48e1b
codex fork --last
```

## Session-file layout

Codex session transcripts live under:

```bash
${CODEX_HOME:-$HOME/.codex}/sessions/YYYY/MM/DD/*.jsonl
```

Example:

```text
${CODEX_HOME:-$HOME/.codex}/sessions/2026/03/21/rollout-2026-03-21T22-54-32-019d122d-9c09-7572-addf-ee59fab48e1b.jsonl
```

## Fastest way to find the latest session

Do not manually descend year -> month -> day unless needed.
Prefer timestamp sorting:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ls -1t "$CODEX_HOME_DIR"/sessions/*/*/*/*.jsonl 2>/dev/null | head -1
```

To list several recent sessions:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
ls -1t "$CODEX_HOME_DIR"/sessions/*/*/*/*.jsonl 2>/dev/null | head -10
```

## How to extract the UUID fast

From the latest path, take the trailing UUID before `.jsonl`.

Example:

```text
rollout-2026-03-21T22-54-32-019d122d-9c09-7572-addf-ee59fab48e1b.jsonl
```

UUID:

```text
019d122d-9c09-7572-addf-ee59fab48e1b
```

Then resume with:

```bash
codex resume 019d122d-9c09-7572-addf-ee59fab48e1b
```

## Practical rule

When the user wants to restore context in one second:

1. check `/permissions` if access mode matters
2. prefer `codex resume --last` for the newest prior session
3. if a specific session file is known, strip it down to the UUID and run `codex resume <UUID>`
4. use `${CODEX_HOME:-$HOME/.codex}/sessions/*/*/*/*.jsonl` only to discover or confirm the UUID, not to reread the whole transcript unless resume is impossible

## When to read the session file directly

Reading the `.jsonl` itself is valid and useful when:

- you want the prior context without switching the live interactive session yet
- you want to summarize, search, or verify what happened before resuming
- you only know the filesystem path and want to recover the session UUID
- you need the last user or assistant turns immediately from disk

Preferred rule:

- fastest continuation of the same dialog -> `codex resume <UUID>` or `codex resume --last`
- clean branch of the same prior dialog for alternative exploration -> `codex fork <UUID>` or `codex fork --last`
- same continuation but explicitly in full-open mode -> `codex resume --dangerously-bypass-approvals-and-sandbox <UUID>` or `codex resume --dangerously-bypass-approvals-and-sandbox --last`
- fastest inspection of the previous context from disk -> open the latest `sessions/.../*.jsonl`

## Resume vs fork vs parallelism

Use:

- `resume` to continue the same session and storyline
- `fork` to branch that session into a new line of work

Do not treat two simultaneous `resume` runs of the same session as a clean multi-owner workflow.
If you need true parallel exploration, prefer:

- `fork` for alternative approaches
- Codex subagents for bounded parallel analysis
- separate Codex processes in different branches or worktrees for parallel write-heavy implementation

## Practical combined workflow

For the newest prior conversation:

```bash
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
latest=$(ls -1t "$CODEX_HOME_DIR"/sessions/*/*/*/*.jsonl 2>/dev/null | head -1)
printf '%s\n' "$latest"
```

If you want to inspect the file first:

```bash
tail -n 80 "$latest"
```

If you want to continue it directly:

```bash
codex resume --last
```

If you want to continue it directly in full-open mode:

```bash
codex resume --dangerously-bypass-approvals-and-sandbox --last
```

If you need the UUID from the filename:

```bash
basename "$latest" .jsonl | grep -oE '[0-9a-f]{8,}-[0-9a-f-]+$'
```
