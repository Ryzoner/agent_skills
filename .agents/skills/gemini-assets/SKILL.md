---
name: gemini-assets
description: "2D game art made by hand in the Gemini app (Google Pro, no API cost), then processed with um sprite. Triggers: нужен спрайт, сгенерируй картинку, game art, sprite, texture, icon."
---

# Game art with the Gemini app (no API, no extra cost)

The Gemini **API** has no free tier for image models; the Google Pro **subscription** covers image
generation only inside the Gemini app. So the split is:

- **Agent:** studies the game, writes the prompts, checks and post-processes the results.
- **User:** pastes each prompt into the Gemini app (gemini.google.com, image mode), downloads the PNG,
  saves it to the agreed path.

Never try to automate the Gemini web UI or ask for the user's Google credentials.

## Setup (once)
- Post-processing needs the `um` CLI: `uv tool install git+https://github.com/rehan-remade/universal-modder`
  (needs Python 3.10+). `um sprite --help` should work. The `um fal` commands are not used here: they need a
  paid fal key. Everything else in `um` works without it.
- Working folder: `assets/gen/` for raw Gemini output, `assets/final/` for engine-ready files.

## Workflow
1. **Study the game's own assets:** pixel size, outline, palette, perspective, facing, frame layout. Turn
   it into one reusable style suffix.
2. **Write a prompt pack** `assets/gen/PROMPTS.md`: a table of `file name | prompt | background | notes`.
   Max about 8 prompts per round, so the user is not buried in copy-paste.
3. **Hand over:** say exactly which prompts to run and which filenames to save as. Wait.
4. **Check what arrived:** list `assets/gen/`, open each image (Read), judge it against the style. Report
   which ones to redo and why, with an improved prompt.
5. **Process:** cut out, fit, pixelate, palette, sheet with `um sprite ...` (see the asset-pipeline skill).
6. **Variants:** the user uploads the hero image to Gemini together with an edit prompt ("same robot, now
   firing, muzzle flash"). One hero, many edits. Never ask for a whole sprite sheet in one prompt: the grid
   comes out uneven.

## Backgrounds and transparency
The Gemini app does not return real alpha. Ask for a **flat solid background in a colour not present in the
subject** (pure white, or magenta #FF00FF for light subjects), no gradient, no ground shadow, no scenery.
Then `um sprite cutout in.png`. If a soft shadow sneaks in, use `--grey` / `--keep-top` in cutout.

## Prompting game art that fits the game
- **Style suffix from the game itself.** For Terraria: "16-bit pixel art game sprite in the style of
  Terraria, crisp dark outline, limited palette, centered, plain flat white background, no shadow, no text".
- **State view and orientation explicitly:** "perfectly horizontal side view with the muzzle pointing
  right" for held weapons, "seen from the side facing left" for enemies, "pointing straight down" for a
  falling bomb. Engines have conventions (Terraria items point right, NPCs face left); fixing orientation
  afterwards costs quality.
- **Pixel art:** models do not produce true pixel grids. Generate, then `um sprite pixelate` / `fit` to the
  exact frame size (nearest-neighbour).
- **Player / team colour:** ask for "bright saturated blue accents" on the parts that take the player's
  colour, then `um sprite team-mask --hue blue`.
- **Seamless textures:** ask for "seamless tileable <material>, top-down, flat lighting", then check with
  `um sprite tile-preview` and fix seams with `um sprite seamless`.
- **No text or logos** unless wanted: models love to add them.

## What this setup does NOT generate: use ready-made free assets
Audio, music, voice, video, 3D models, rigs and PBR maps are not generated here (the generators are paid).
Take ready-made assets instead. **Always check the licence per asset** (CC0 = no credit needed; CC-BY = credit
required; "free" on stock sites often forbids redistributing the raw file, which matters for mods) and log
source + licence in `assets/CREDITS.md`.

| Need | Source | Typical licence |
|---|---|---|
| 2D sprites, tiles, UI, icons, SFX packs | kenney.nl, opengameart.org, itch.io/game-assets/free | CC0 (Kenney); mixed on OpenGameArt and itch |
| Sound effects | freesound.org (filter by licence), sfxr.me (generate retro SFX in the browser) | CC0 / CC-BY, varies per sound |
| Music | freepd.com, OpenGameArt, Kenney audio packs | CC0 / public domain, varies |
| 3D models | quaternius.com, kenney.nl (3D packs), Poly Haven (polyhaven.com/models) | CC0 |
| Textures and PBR maps | ambientcg.com, polyhaven.com/textures | CC0 |
| Stock video clips | pexels.com/videos, pixabay.com/videos, mixkit.co | site licence, not CC0: read it |

- **Video from code instead:** motion graphics, explainers, trailers and title cards can be rendered locally
  for free with the HyperFrames skills (`hyperframes` skill, Node 22+). It is HTML-to-video, not photoreal
  AI video.
- **Many angles of one unit:** without 3D, generate each heading separately as an edit of the hero image
  and check consistency by eye. Say upfront that 8/16 consistent headings are not realistic this way. With a
  CC0 GLB model you can render any heading via `um render3d`.
- **Simple geometric 3D:** model it in Blender, or skip to a CC0 pack.
- Pexels and Pixabay block automated fetching: the user downloads, the agent only picks and records.

## Audio conversion for engines (for sounds you did get)
- `ffmpeg -i x.mp3 -ar 44100 x.wav` (XNA/tModLoader, most engines).
- `ffmpeg -i x.mp3 -c:a libvorbis -q:a 5 x.ogg` (Minecraft, Godot, Unity).
- Normalize loudness: `-af loudnorm=I=-16`.

## Records and credits
- Keep `assets/gen/PROMPTS.md` next to the assets: it is the manifest (prompt, file, date).
- In the mod's README, credit that art was generated with Gemini (Google) and check the current terms for
  commercial use of generated images. List third-party assets from `assets/CREDITS.md` there too.
