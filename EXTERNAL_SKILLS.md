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

## Free alternatives to fal.ai (candidates, not installed)
| Repo | What | Catch |
|---|---|---|
| artokun/comfyui-mcp (MIT) | Drives a local ComfyUI: images, video, audio | Needs ComfyUI and local models; heavy on 16 GB RAM |
| yoav0gal/agent-voice (MIT) | Local text-to-speech (Kokoro-82M), no API key | Voice only |
| arjun988/blender-skills (MIT) | Blender through the BlenderMCP add-on | Modelling by hand/script, not image-to-3D |
| guaardvark/guaardvark (MIT) | Self-hosted studio: image, video, music, voice | Whole app, heavy |

Skipped: scenario-labs/skills (Scenario.com credits), BlenderXAlpha-3DGenSkill (Alpha3D/Tripo/Meshy credits).
