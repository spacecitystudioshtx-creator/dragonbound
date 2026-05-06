#!/usr/bin/env python3
"""Queue ComfyUI background and tileset targets for Dragonbound."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUEUE_PATH = ROOT / "data" / "art_queue.json"


def upsert_asset(assets: list[dict], asset: dict) -> None:
    for idx, existing in enumerate(assets):
        if existing.get("id") == asset["id"]:
            keep = {
                key: existing[key]
                for key in ("status", "raw_output", "generated_at", "note")
                if key in existing and existing.get("status") == "done"
            }
            merged = asset | keep
            assets[idx] = merged
            return
    assets.append(asset)


def main() -> int:
    queue = json.loads(QUEUE_PATH.read_text())
    assets = queue.setdefault("assets", [])

    negative = (
        "pokemon, copyrighted map, copied game screenshot, logos, text, UI, "
        "characters, modern 3d render, isometric perspective, photorealistic, "
        "painterly, smooth vector art, high resolution illustration, blur, "
        "anti-aliased soft edges, noisy clutter, diagonal roads"
    )

    upsert_asset(
        assets,
        {
            "id": "kindra-town-style-benchmark-v1",
            "kind": "overworld_style_benchmark",
            "status": "pending",
            "workflow": "checkpoint",
            "checkpoint": "AziibPixelMix_Full.safetensors",
            "lora": "",
            "lora_strength": 0.0,
            "source_width": 768,
            "source_height": 512,
            "output": "art/generated/backgrounds/kindra_town_style_benchmark_v1.png",
            "size": "240x160",
            "prompt": (
                "masterpiece pixel art, top-down 2004 handheld creature RPG town "
                "screenshot, original Dragonbound starter town, exact 240x160 "
                "game-screen composition, 16x16 tile grid logic, pale sandy road "
                "running horizontally through the middle, mint green grass fields "
                "with tiny pixel speckles, large blue-roof shop building on the "
                "upper left with striped yellow awning, smaller blue-roof house on "
                "the upper right with large readable door, gray picket fence and "
                "hedge row along the lower third, small sign posts, clean hard "
                "pixel clusters, bright limited GBA color palette, no characters, "
                "no text, original buildings and props"
            ),
            "negative": negative,
        },
    )

    upsert_asset(
        assets,
        {
            "id": "kindra-town-tileset-reference-v1",
            "kind": "overworld_tileset_reference",
            "status": "pending",
            "workflow": "checkpoint",
            "checkpoint": "AziibPixelMix_Full.safetensors",
            "lora": "",
            "lora_strength": 0.0,
            "source_width": 768,
            "source_height": 768,
            "output": "art/generated/tilesets/kindra_town_tileset_reference_v1.png",
            "size": "256x256",
            "prompt": (
                "masterpiece pixel art, original 16x16 tileset reference sheet for "
                "a 2004 handheld top-down creature RPG town, arranged as a neat "
                "tile atlas on a 16 pixel grid, include mint grass tile, grass "
                "variant, pale sandy road tile, road edge tiles, tall grass, hedge, "
                "gray picket fence, sign post, blue roof tiles, gray wall tiles, "
                "large readable door tile, window tile, shop awning tile, water "
                "tile, small flowers, clean hard pixels, limited bright GBA palette, "
                "no labels, no characters, no text"
            ),
            "negative": negative,
        },
    )

    QUEUE_PATH.write_text(json.dumps(queue, indent=2) + "\n")
    print("Queued background pipeline assets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
