# External skills (install from source, not bundled)

These skills are not copied into this repo: their licences forbid redistribution, or they update too fast.
An agent setting up a new device should run the commands below after `scripts/install.sh`.
`-g` installs to `~/.agents/skills` (read by Zed and others) and links Claude Code.

## ykdojo/claude-code-tips (All Rights Reserved: personal use only)
Context-saving helpers: `handoff`, `half-clone`, `quarter-clone` (Claude Code only).
```bash
npx -y skills add ykdojo/claude-code-tips -g -y -s handoff -s half-clone -s quarter-clone
mkdir -p ~/.claude/scripts && curl -fsSL https://raw.githubusercontent.com/ykdojo/claude-code-tips/HEAD/scripts/half-clone-conversation.sh -o ~/.claude/scripts/half-clone-conversation.sh && chmod +x ~/.claude/scripts/half-clone-conversation.sh
```
The script is not part of the skill folder; `half-clone` looks for it under `~/.claude`.

## heygen-com/hyperframes (Apache-2.0): free local video from HTML
Needs Node 22+. Motion graphics, explainers, trailers. Not photoreal AI video. `media-use` can fall back to
generative TTS/music/image models when its catalog misses: check for paid keys before using that path.
```bash
npx -y skills add heygen-com/hyperframes -g -y -s hyperframes -s hyperframes-core -s hyperframes-cli -s hyperframes-creative -s media-use -s motion-graphics
```
The `hyperframes` router installs further workflows on demand (`npx hyperframes skills update`).

## flowful-ai/cad-skill (PolyForm Noncommercial): parametric 3D printing
CadQuery to STL/3MF. Needs Python 3.10-3.12. Its own description says not for game assets.
```bash
npx -y skills add flowful-ai/cad-skill -g -y
```

## mandrille/pixelart (no licence: personal use only): pixel art from text grids
No image model: the agent writes a sprite as a character grid plus a hex palette, the tool renders PNG,
spritesheet or GIF. Skill folder installs as `pixel-art`.
```bash
npx -y skills add mandrille/pixelart -g -y
uv tool install git+https://github.com/mandrille/pixelart
```

## sprite-forge CLI (the skill itself is bundled in this repo, MIT)
```bash
uv tool install git+https://github.com/isabellagreco1997/sprite-forge
```
`spriteforge snap` auto-detection of the pixel grid can miss on clean synthetic input: pass `--cell <size>`.

## affaan-m/ECC (MIT): only five standalone skills, not the whole harness
ECC is a large bundle (293 skills, 68 agents, 94 commands, rules, hooks). Installing it whole bloats the context
of every session, so take just these:
```bash
npx -y skills add affaan-m/ECC -g -y -s context-budget -s strategic-compact -s search-first -s verification-loop -s dotnet-patterns
```

## Leonxlnx/taste-skill (MIT): frontend design style skills
The CLI selects by the `name` field, not the folder name. The image-generation variants (`imagegen-*`,
`image-to-code`, `brandkit`) need an image generator and are skipped.
```bash
npx -y skills add Leonxlnx/taste-skill -g -y -s design-taste-frontend -s redesign-existing-projects -s minimalist-ui -s high-end-visual-design -s industrial-brutalist-ui
```

## cathrynlavery/diagram-design (MIT): editorial diagrams as HTML/SVG
```bash
npx -y skills add cathrynlavery/diagram-design -g -y
```

## rtk-ai/rtk (Apache-2.0): compresses Bash output before the agent reads it
Binary plus a PreToolUse hook on Bash. Telemetry is off by default. Hook only, no CLAUDE.md edits:
```bash
brew install rtk
rtk init -g --hook-only --auto-patch
```
Windows: `winget install rtk-ai.rtk`, then `rtk init -g --hook-only --auto-patch`. Restart Claude Code afterwards.

## DevOps skills: Terraform, Kubernetes, GitLab CI, Prometheus
Selected by `name`, not folder. Skills only: the agents and commands of these plugins are not installed.

hashicorp/agent-skills (MPL-2.0), official Terraform skills:
```bash
npx -y skills add hashicorp/agent-skills -g -y -s terraform-style-guide -s terraform-test -s refactor-module -s terraform-stacks -s terraform-search-import -s terraform-policy
```
wshobson/agents (MIT), 20 skills out of 184:
```bash
npx -y skills add wshobson/agents -g -y -s gitlab-ci-patterns -s secrets-management -s deployment-pipeline-design -s helm-chart-scaffolding -s gitops-workflow -s k8s-manifest-generator -s k8s-security-policies -s prometheus-configuration -s grafana-dashboards -s slo-implementation -s distributed-tracing -s incident-runbook-templates -s postmortem-writing -s on-call-handoff-patterns -s connectivity-triage -s sast-configuration -s bash-defensive-patterns -s shellcheck-configuration -s bats-testing-patterns -s terraform-module-library
```
LukasNiessen/kubernetes-skill (MIT), fewer Kubernetes hallucinations:
```bash
npx -y skills add LukasNiessen/kubernetes-skill -g -y
```
Notes: `connectivity-triage` is macOS-specific. `gitops-workflow` shows `curl ... | sudo bash` for Flux: read before running.

## docker/skills (Apache-2.0, official): Docker core skills
Also bundled in `.agents/skills/docker-*` of this repo (installer copies them), so the command is needed only for updates.
The other seven (`docker-agent-*`, `docker-sandboxes-*`) cover Docker Agent and Docker Sandboxes products, not installed by default.
```bash
npx -y skills add docker/skills -g -y -s docker-build-strategies -s docker-compose-patterns -s docker-destructive-guardrails -s docker-project-foundations
```

## Free alternatives to fal.ai (candidates, not installed)
| Repo | What | Catch |
|---|---|---|
| artokun/comfyui-mcp (MIT) | Drives a local ComfyUI: images, video, audio | Needs ComfyUI and local models; heavy on 16 GB RAM |
| yoav0gal/agent-voice (MIT) | Local text-to-speech (Kokoro-82M), no API key | Voice only |
| arjun988/blender-skills (MIT) | Blender through the BlenderMCP add-on | Modelling by hand/script, not image-to-3D |
| guaardvark/guaardvark (MIT) | Self-hosted studio: image, video, music, voice | Whole app, heavy |

Skipped: scenario-labs/skills (Scenario.com credits), BlenderXAlpha-3DGenSkill (Alpha3D/Tripo/Meshy credits).
