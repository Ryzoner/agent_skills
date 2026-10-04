# Resume: skill-index routing test (not yet run)

State on 2026-10-04: skill-index built and committed locally (not applied to the real ~/.agents). Subagents failed
because ~/.claude/settings.json pointed model aliases at invalid IDs; fixed to claude-sonnet-5-5 /
claude-haiku-4-5-20251001, needs a session restart to take effect.

Next steps:
1. Check: `env | grep CLAUDE_CODE_SUBAGENT_MODEL` should print claude-sonnet-5-5.
2. Sandbox with 165 skills: /private/tmp/claude-501/-Users-vadimmikerin-Library-Application-Support-Claude-scratch-workspaces-e8e782a6-b8bb-4cf5-81b3-8f1dc94ec99c-9ad05c0d-4ddd-4377-bd41-4592d5b70066-scratch-2026-09-15-7d0961/6eaea7bf-7654-4a41-9512-4f181c8fe2d8/scratchpad/sandbox_test (index paths already absolute).
3. Prompts: /private/tmp/claude-501/-Users-vadimmikerin-Library-Application-Support-Claude-scratch-workspaces-e8e782a6-b8bb-4cf5-81b3-8f1dc94ec99c-9ad05c0d-4ddd-4377-bd41-4592d5b70066-scratch-2026-09-15-7d0961/6eaea7bf-7654-4a41-9512-4f181c8fe2d8/scratchpad/routing_run/prompts/batch_00..11.txt, results go to routing_run/results/.
   If /tmp was cleaned, rebuild: copy skills into a temp HOME, `SKILL_INDEX_HOME=<tmp> python3 ../skill_index.py install`,
   sed '~/.agents/' to absolute paths in INDEX.md and groups/*.md, then `python3 routing_test.py batches <tmp> <run> 12`.
4. Launch 12 subagents (general-purpose, no model param) with: "Read <prompt file> and follow it exactly".
5. Score: `python3 routing_test.py score <sandbox> <run>`. Show the user the full per-task results.
6. Only after the user approves: apply on the real Mac (install + AGENTS.md routing section), then push.
