# ComfyUI templates for game assets (local, free)

ComfyUI Desktop ships these as built-in templates: open **Templates**, pick the name below, press Download in
the "Missing models" dialog. No files are stored here on purpose (templates track the installed ComfyUI
version). Tested box: RTX 3060 12 GB, 32 GB RAM, ComfyUI 0.38 at `192.168.169.145:8000` (`--listen 0.0.0.0`).

| Need | Template name | Models (download size) | Notes |
|---|---|---|---|
| 3D from an image (shape only, GLB) | `HY 3D 2.0` (`3d_hunyuan3d_image_to_model`) | hunyuan3d-dit-v2_fp16 (4.9 GB) | Safest on 12 GB. No texture |
| 3D, newer shape model | `HY 3D 2.1` | hunyuan_3d_v2.1 (7.4 GB) | Still shape only |
| 3D with texture bake | `Pixal3D & TRELLIS.2: Image to Model` | 7 files, about 15 GB | Heavy; fit on 12 GB not verified |
| Music | `ACE-Step 1.5 Music Generation Workflow` (split) | 4 files, about 10 GB | Turbo model |
| Sound effects | `Stable Audio 1.0: Text to Audio` | checkpoint 4.9 GB + t5-base 0.9 GB | Check the Stability licence for commercial use |

## Do not use
Templates and nodes with the `api_` prefix or from ElevenLabs, Kling, Meshy, Rodin, Tripo, Flux3, ByteDance,
MiniMax, Fish Audio, HeyGen: they spend paid Comfy credits.

## Driving it from an agent
The HTTP API is enough: `GET /object_info` (what is installed), `POST /prompt` (API-format graph),
`GET /history/<id>`, `GET /view`. Z-Image Turbo 1024x1024 took 66-98 s on this card (cold start included).
