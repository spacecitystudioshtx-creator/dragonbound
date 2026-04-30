# Drake Sprite Generation Pipeline

Proven workflow as of 2026-04-30. Default DiffusionBee SD model (`Default_SDB_0.1`) — no custom LoRA needed for usable pixel-art results.

## One-time setup
- DiffusionBee installed, default model downloaded
- ImageMagick installed (`brew install imagemagick`) — used for nearest-neighbor downscaling

## Per-drake workflow

### 1. Generate in DiffusionBee
Open DiffusionBee → Text to image. Use this prompt template (filled in with the drake's species-specific details):

```
pixel art sprite of a small <CREATURE>, gba pokemon firered style, 16-bit,
front-facing combat pose, <COLORS + DETAILS>, crisp pixel outlines,
limited 16-color palette, plain white background, no shading gradients,
single sprite centered
```

Settings:
- Model: `Default_SDB_0.1`
- Aspect Ratio: Square
- Number of images: 1 (or more for variants to choose from)
- Seed: -1

Click Generate. ~90 seconds per image on M-series Mac Mini.

### 2. Save the result
Right-click the image → Save Image As → name it `<drake_id>_raw.png` → save to `~/Downloads`.

### 3. Downscale + install in project
```bash
DRAKE=ember   # change per drake
magick ~/Downloads/${DRAKE}_raw.png -filter point -resize 64x64 \
    ~/Documents/DragonBound/art/drakes/${DRAKE}_front.png
rm -f ~/Documents/DragonBound/art/drakes/${DRAKE}_front.png.import \
      ~/Documents/DragonBound/.godot/imported/${DRAKE}_front*
```

The `-filter point` is critical — that's nearest-neighbor, which keeps the pixels crisp. Without it the sprite blurs.

### 4. Verify
```bash
godot --headless --quit 2>&1 | grep ERROR
```
Should be silent. Then F5 in Godot to see in-game.

## Drakes status

| Drake | Type / Class | Status |
|---|---|---|
| **ember** | fire / true_dragon | ✅ generated 2026-04-30 |
| **flick** | fire / beast (fodder) | ✅ generated 2026-04-30 |
| **tuft** | nature / beast (fodder) | ✅ generated 2026-04-30 |
| **gulp** | water / beast (fodder) | ✅ generated 2026-04-30 — green bg bleed, may regenerate |
| scornn | fire / true_dragon (mid evo of ember) | stub PNG |
| ashvane | fire / true_dragon (final evo) | stub PNG |
| ripple | water / leviathan (starter alt) | stub PNG |
| undertow | water / leviathan (mid) | stub PNG |
| tidewrath | water / leviathan (final) | stub PNG |
| sprig | nature / beast (starter alt) | stub PNG |
| thicket | nature / beast (mid) | stub PNG |
| ironbark | nature / beast (final) | stub PNG |

The 4 ✅ ones are everything the player encounters in the **starter area** (Kindra + Dustway). The other 8 are mid/late evolutions or alternate starters; queue them when you're closer to needing them.

## Prompt fragments by drake (edit + paste)

Use these in place of `<CREATURE>` and `<COLORS + DETAILS>`:

- **scornn**: medium armored fire dragon, deep red scaled body with cream belly, two curving horns, fierce eyes, small dark wings, armored ridge on back, two stubby horns on snout, flame on tail, warm fire palette
- **ashvane**: massive volcanic dragon, charcoal-grey body with glowing orange lava cracks, large wings outstretched, two upward-curving horns, glowing yellow eyes, ash-and-fire palette
- **ripple**: small serpentine water creature, pale blue body with white belly, fin-shaped ears, tail fin, tiny flippers, big cute eyes, water droplet motif on forehead, blue-cyan palette
- **undertow**: medium sea serpent, deeper blue body with cyan belly, flowing crest fin, side fins, fanged smile, scale ripples on body, dark navy palette
- **tidewrath**: massive deep-sea leviathan, navy-blue body with teal belly, gaping toothy maw, glowing red eyes, tidal-energy aura around body, dark blue palette
- **sprig**: small leafy creature, green body with cream belly, twig antlers, single leaf on head, big cute eyes, leafy green palette with brown twig accents
- **thicket**: medium bark-armored beast, mossy green body with bark-plate armor, vine-whip arms, amber eyes, leaf details on head, dark green and brown palette
- **ironbark**: massive tree-golem, dark wooden body with bark texture, moss patches, glowing amber eyes, crown of leaves, root legs, deep brown and green palette

## Quality troubleshooting

- **Got a face/head only, no body** → add "full body, head and torso visible, standing pose"
- **Background bled through** (Gulp issue) → add "isolated subject, plain pure white background only" and a stronger negative; if still bad, mask in Preview.app post-generation
- **Too painterly, not pixel-art enough** → emphasize "16-bit, crisp blocky pixels, gba sprite, low resolution" and add negative "anti-aliased, smooth gradients, painterly, illustration"
- **Wrong color palette** → name 2-3 specific colors at the start of details ("deep red orange with cream belly")
