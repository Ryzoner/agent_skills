---
name: skill-manager
description: "Use when the user asks to install, add, update or remove an agent skill: reviews it, installs it and files it into the skill index."
---

# Skill manager

Skills live in the library `~/.agents/skill-library` and are found through the index `~/.agents/skill-index`.
A skill that is installed but not filed into a topic is effectively invisible. Below, `si` means
`python ~/.agents/skill-index/skill_index.py`.

## Install or add
1. **Review the source** before installing: licence; every script and what it runs (network, sudo, rm, eval);
   frontmatter valid for Zed (description in double quotes, one line). Done when you can name the licence and
   each script's effect. Anything risky: stop and report it to the user.
2. **Install**: `npx -y skills add <owner/repo> -g -y -s <name>`. `-s` takes the frontmatter `name`, not the
   folder name; one `-s` per skill.
3. **File it**: `si sync --apply`, then `si assign <name>` lists the best-matching topics. Run
   `si assign <name> <topic>`. No topic fits: `si new-group <id> "<what it covers>" "<kw1,kw2,...>"` (regex
   keywords, Russian and English, the words a user would type), then assign. Done when `si check` prints
   `unassigned: none`.
4. **Record it in the repo** `~/agent_skills`: permissive licence (MIT, Apache, MPL) may be bundled in
   `.agents/skills/`; anything else gets its install command in `EXTERNAL_SKILLS.md`. `assign` already wrote
   `skill-index/groups.json`. Commit; push only when the user asks.
5. **Report**: skill, topic, how it gets triggered, anything skipped.

## Update
`npx skills update` (or `add` again), then `si sync --apply` and `si build`. The fresh copy replaces the
library one; the old copy stays in `~/.agents/skill-index/duplicates/`.

## Remove
Show what will be deleted and get the user's yes. Delete `~/.agents/skill-library/<name>`, remove the name from
`~/agent_skills/skill-index/groups.json`, run `si install` from the repo, remove its `EXTERNAL_SKILLS.md`
entry if present.

## Registered skills
Only routers and user commands stay registered (`registered` in `groups.json`, visible to the agent by their
description). Every other skill belongs in the library.
