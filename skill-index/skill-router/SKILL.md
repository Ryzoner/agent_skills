---
name: skill-router
description: "Use before any non-trivial task: find the right skills through the index at ~/.agents/skill-index/INDEX.md. Skills are not registered, they live in a library."
---

# Skill router

Skills are kept out of the context on purpose. Only this router is registered. Everything else sits in
`~/.agents/skill-library/<name>/SKILL.md` and is found through the index.

## When
Any task that is more than a quick question or chat: code, infrastructure, documents, design, debugging,
git, security, game modding, media. Skip for trivial answers.

## Steps
1. Read `~/.agents/skill-index/INDEX.md`. Check the **Cross-cutting** rules first, they apply to almost every task.
2. Pick at most two topics that match the task. Read `~/.agents/skill-index/groups/<topic>.md`.
3. Pick at most three skills whose "use when" fits. Read each `SKILL.md` fully (and the files it points to,
   paths are relative to the skill folder) and follow it.
4. Tell the user in one line which skills you applied: `Скиллы: a, b`.
5. No topic fits: work without skills. Do not guess a skill from memory.

## If the index is missing or stale
Run `python ~/.agents/skill-index/skill_index.py build`. New skills installed with `npx skills add` land in
`~/.agents/skills`: run `python ~/.agents/skill-index/skill_index.py sync --apply` and then `build`.
Unassigned skills show up under `unsorted`: add them to `groups.json` and rebuild.
