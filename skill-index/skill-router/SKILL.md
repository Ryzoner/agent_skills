---
name: skill-router
description: "MANDATORY before any task or question about code, DevOps, infrastructure, documents, design, debugging, git or security, even if you know the answer: find skills via ~/.agents/skill-index/INDEX.md."
---

# Skill router

Skills are kept out of the context on purpose. Only this router and a few user commands are registered.
Everything else sits in `~/.agents/skill-library/<name>/SKILL.md` and is found through the index.

## When
Every task AND every question on a topic from the index: code, DevOps and infrastructure, documents, design,
debugging, git, security, game modding, media. The form does not matter: "write", "what should I check",
"how is it better", "is it ok to" are all tasks. Knowing the topic is not a reason to skip: the skill holds a
tested procedure your answer from memory does not have.
Skip ONLY for: translation, definitions and general facts, arithmetic, small talk.

## Steps
1. If a hook already suggested topics, start with them. Otherwise read `~/.agents/skill-index/INDEX.md`
   (Cross-cutting rules first, they apply to almost every task).
2. Pick at most two topics. Read `~/.agents/skill-index/groups/<topic>.md`.
3. Pick at most three skills whose "use when" fits. Read each `SKILL.md` fully (and the files it points to,
   paths are relative to the skill folder) and follow it.
4. Tell the user in one line: `Скиллы: a, b (ещё подходят: c)`. List cut candidates without reading them.
5. No topic fits: work without skills. Do not guess a skill from memory.

## If the index is missing or stale
Run `python ~/.agents/skill-index/skill_index.py build`. New skills installed with `npx skills add` land in
`~/.agents/skills`: run `python ~/.agents/skill-index/skill_index.py sync --apply` and then `build`.
Unassigned skills show up under `unsorted`: add them to `groups.json` and rebuild.
