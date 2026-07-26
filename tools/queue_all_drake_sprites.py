#!/usr/bin/env python3
"""Queue one FLUX sprite asset for each Dragonbound drake."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUEUE_PATH = ROOT / "data" / "art_queue.json"

NEGATIVE = (
    "pokemon, charizard, copyrighted character, clone, human, person, humanoid, "
    "photorealistic, painterly, soft brush, smooth gradient, 3d render, complex "
    "background, blurry, cropped, text, watermark, minecraft, monochrome"
)

PROMPTS = {
    "ember": "original cute baby brass fire dragon, short chunky body, oversized head, tiny folded wings, curled tail with small blue flame, ember-gold scales, cream belly, black little horns, friendly confident face",
    "scornn": "original adolescent fire dragon, leaner sturdy body, swept black horns, larger folded wings, ember-orange scales, cream chest, smoky tail flame, fierce confident grin",
    "ashvane": "original mature ash fire dragon, powerful upright stance, charcoal horns, broad wings, deep orange and dark ash scales, cream armored belly, blazing blue-orange tail flame, noble battle glare",
    "ripple": "original small water leviathan hatchling, rounded blue body, pale cyan belly, fin ears, tiny whiskers, curled splash tail, bright curious eyes, cute aquatic monster silhouette",
    "undertow": "original young water leviathan, sleek blue serpentine body with small arms, pale belly, fin crest, side fins, curled wave tail, focused expression, compact battle pose",
    "tidewrath": "original mature water leviathan dragon, powerful coiled body, ocean-blue scales, white-cyan belly, crest fins, wave-shaped tail, strong aquatic silhouette, stern battle face",
    "sprig": "original small nature beast dragon, mossy green round body, cream muzzle and belly, leaf ears, twig horns, tiny paws, seedling tail, gentle curious face",
    "thicket": "original medium nature drake beast, leafy mane, bark-brown horns, sturdy green body, cream belly, branch-like tail, protective battle pose, calm determined face",
    "ironbark": "original mature forest armor drake, heavy bark-plated body, dark green moss accents, branch horns, broad cream chest, stout legs, ancient guardian expression",
    "flick": "original small fire fox drake, reddish-orange fur, cream chest, perky ears with dark tufts, three-tipped flame tail, tiny fangs, mischievous sitting battle pose",
    "tuft": "original small moss rabbit drake, round fluffy green moss body, leaf-shaped ears, short twig horns, cream face and belly, large black curious eyes, little paws",
    "gulp": "original small chubby pond drake, blue-green slick body, pale cyan belly, oversized round mouth, tiny webbed feet, water droplet forehead, surprised cute face",
}


def main() -> int:
    queue = json.loads(QUEUE_PATH.read_text())
    assets = queue.setdefault("assets", [])
    existing = {asset.get("id") for asset in assets}

    for drake_id, brief in PROMPTS.items():
        asset_id = f"drake-{drake_id}-front-v1-flux2"
        if asset_id in existing:
            continue
        assets.append(
            {
                "id": asset_id,
                "kind": "drake_front",
                "status": "pending",
                "output": f"art/drakes/{drake_id}_front.png",
                "size": "64x64",
                "prompt": (
                    "pixel art sprite, original creature battle RPG monster, "
                    "transparent background, crisp 16-bit handheld pixel art, "
                    "full body visible, front-facing battle pose, centered, "
                    "strong readable silhouette, dark pixel outline, clean cel "
                    f"shading, limited color palette, {brief}"
                ),
                "negative": NEGATIVE,
            }
        )

    QUEUE_PATH.write_text(json.dumps(queue, indent=2) + "\n")
    print(f"Queued {len(PROMPTS)} drake sprite entries.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
