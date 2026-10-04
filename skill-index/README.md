# skill-index: skills out of the context, found through an index

Problem: every registered skill adds its name and description to every session (Zed: all of
`~/.agents/skills`, Claude Code: `~/.claude/skills`). With 150 skills that is ~12k tokens, and the agent still
misses skills because the list is a wall of text. Skills the installer never linked into `~/.claude/skills`
were not registered in Claude Code at all.

Solution: skills live in a **library** that no agent scans. Only a tiny router is registered. The agent finds
skills through a two-level index.

```
task -> AGENTS.md rule / skill-router -> INDEX.md (topics + cross-cutting rules)
     -> groups/<topic>.md (one line per skill) -> <skill>/SKILL.md (read and follow)
```

## Layout on a device
- `~/.agents/skill-library/<skill>/`: all skills, flat (updates and `npx` stay simple).
- `~/.agents/skill-index/INDEX.md`, `groups/*.md`: generated. `skill_index.py`, `groups.json`: runtime copy.
- Registered (visible to agents): `skill-router`, `caveman`, `caveman-stats`, `handoff`, `half-clone`,
  `quarter-clone` (set in `groups.json` → `registered`). They are also linked into `~/.claude/skills`.

## Source in this repo
- `groups.json`: topics, which skills belong to each (glob patterns), cross-cutting rules, registered list,
  one-line overrides for important skills.
- `skill_index.py`: `status`, `sync [--apply]`, `build`, `check`, `install`, `revert`. Stdlib only.
- `skill-router/SKILL.md`, `skill-manager/SKILL.md`: the bundled skills that stay registered.
- `route_hook.py` (UserPromptSubmit) and `post_hook.py` (PostToolUse): Claude Code hooks, registered by `install`.

## Use
```bash
python skill_index.py status          # what is registered now vs after, pending moves
python skill_index.py sync            # dry-run: shows what would move
python skill_index.py install         # router + sync --apply + build (installers call this)
python skill_index.py check           # skills without a group
python skill_index.py revert          # undo the last sync exactly (journal in ~/.agents/skill-index)
```
After `npx skills add ...` or `npx skills update`: `python ~/.agents/skill-index/skill_index.py sync --apply`
then `build`. A fresh copy of an existing skill replaces the library copy; the old one is kept in
`~/.agents/skill-index/duplicates/`. Same-named copies in other scanned dirs go there too, never deleted.
New skills without a group show up under `unsorted`: add them to `groups.json`, rebuild.

## Adding, updating, removing skills
- Ask the agent to install a skill: the registered `skill-manager` skill reviews the source, installs it with
  `npx skills add`, files it into a topic and records it in the repo.
- Safety net (Claude Code): a PostToolUse hook on Bash notices `skills add/update/remove`, moves new skills into
  the library, rebuilds the index and reminds the agent about skills without a topic.
- `python skill_index.py assign <skill>` shows the best-matching topics; `assign <skill> <topic>` files it;
  `new-group <id> "<about>" "<kw1,kw2>"` adds a topic. Both write the repo manifest (path stored in
  `~/.agents/skill-index/config.json` by `install`) and copy it to the device.

## Measured on the author's Mac (chars/4, approximate)
| | before | after |
|---|---|---|
| Zed, name+description of all registered skills | ~12.5k tokens | ~0.3k |
| Claude Code | ~7.0k | ~0.3k |
| Per task when routing is used | | INDEX ~0.8k + one group file + the skills read |

Most of the saving is cache-read tokens (0.1x), so the money saved is smaller than the raw numbers; the main gain
is reliable routing and room to keep hundreds of skills.

## Limits
- The Skill tool and `/name` invocation only work for registered skills; library skills are read as files.
- Plugin and marketplace skills (Claude desktop app, `/plugin`) are not covered: disable unused plugins separately.
- Routing depends on the AGENTS.md rule and the router description. Verify it on real tasks.
