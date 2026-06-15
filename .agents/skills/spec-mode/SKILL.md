---
name: spec-mode
description: Use when the user asks to structure work as specifications, requirements, design docs, team task lists, or a `.spec/<slug>/TASK.md + Requirements.md + Design.md` workflow in Russian. Use this skill to scaffold and maintain spec packs with traceability between subtasks and requirements.
---

# Spec Mode

Use this skill when the task is about:
- specifications
- requirements
- design docs
- team task lists
- decomposition of work into independent zones
- `.spec/<slug>/TASK.md`, `Requirements.md`, `Design.md`

## Workflow

1. Start from discovery first if the user is still understanding the project.
2. If the user asks things like:
   - how to improve the dashboard
   - how to improve Telegram Web logic
   - what problems exist
   - what to fix first
   then do analysis first and do not create `.spec/` yet.
3. Only create spec files after the user explicitly asks to:
   - make a spec
   - formalize the plan
   - create requirements/design/tasks
4. Once the user asks for a spec:
   - treat each top-level workstream as an independent spec pack
   - store it in `.spec/<slug>/`
   - use `TASK.md`, `Requirements.md`, `Design.md`
5. If you need scaffolding, use:
   - `scripts/init_spec_pack.sh`

## What to load

- TASK rules:
  - [references/task-format.md](references/task-format.md)
- Requirements rules:
  - [references/requirements-format.md](references/requirements-format.md)
- Design rules:
  - [references/design-format.md](references/design-format.md)

## Important

- Keep `SKILL.md` lean; read references only as needed.
- Use two phases:
  - Phase 0: discovery and improvement analysis
  - Phase 1: spec formalization
- Always preserve traceability:
  - `Task -> Requirements -> Design`
- For subtask traceability use:
  - `_Requirements: 1.1, 2.3_`
- Every top-level task in `TASK.md` must have its own responsibility block:
  - `owner`
- For every top-level task, the responsible side must be chosen explicitly.
- Keep it simple:
  - one task -> one explicit responsibility block
- all subtasks under that task belong to the same responsibility block by default
- `owner` may be:
  - one person
  - one AI model
  - one named executor group if the team uses group ownership
- `owner` may also contain several explicit executors if the owner of the plan wants shared execution.
- The number of executors is not tied to the number of tasks.
- Three executors may split tasks evenly, unevenly, or one executor may take several tasks while others take fewer.
- The workload split is defined by the plan owner, not by the template.
- Different tasks may have different owners.
- The same owner may also appear in many tasks.
- If the user explicitly asks for split execution with several executors or agents, spawn separate independent agents for those top-level tasks during execution when the toolset allows it.
- Keep the split aligned with the chosen `owner` blocks in `TASK.md`.
- In split execution there is also a coordinating reviewer/integrator role.
- This reviewer does not have to be fixed in `TASK.md`.
- The important part is that this role exists.
- The reviewer waits until the executors finish, then:
  - collects results from all agents
  - checks whether changes conflict
  - integrates everything together
  - updates the single shared `TASK.md`
  - runs final verification
  - closes the spec by fact, not by assumption
- Reuse templates from:
  - `templates/TASK.template.md`
  - `templates/Requirements.template.md`
  - `templates/Design.template.md`
