#!/usr/bin/env python3
"""Print the next pending art prompt for DiffusionBee or ComfyUI."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUEUE = ROOT / "data" / "art_queue.json"


def main() -> int:
    data = json.loads(QUEUE.read_text())
    for asset in data.get("assets", []):
        if asset.get("status") != "pending":
            continue
        print(f"ID: {asset['id']}")
        print(f"Kind: {asset['kind']}")
        print(f"Target size: {asset['size']}")
        print(f"Save raw image as: ~/Downloads/{asset['id']}_raw.png")
        print(f"Final output: {asset['output']}")
        print()
        print("PROMPT")
        print(asset["prompt"])
        print()
        print("NEGATIVE")
        print(asset.get("negative", ""))
        return 0
    print("No pending art assets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
