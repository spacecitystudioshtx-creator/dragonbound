#!/usr/bin/env python3
"""
Validate the JSON data files under res://data/.

Checks performed:
  - drakes.json: every base_moves id exists in moves.json
  - drakes.json: every evolution.to id exists in drakes.json
  - drakes.json: types are in the allowed set
  - drakes.json: classes are in the allowed set
  - moves.json:  effects are in the allowed set
  - types.json:  chart keys match the types list
  - synergies.json: combo type pairs reference known types

Exits 0 on success, 1 on any validation failure. Prints a report either way.

Usage (from project root):
    python3 tools/validate_data.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"

ALLOWED_DRAKE_TYPES = {"fire", "water", "nature"}
ALLOWED_DRAKE_CLASSES = {"true_dragon", "leviathan", "beast"}
ALLOWED_MOVE_TYPES = {"fire", "water", "nature", "normal"}
ALLOWED_EFFECTS = {
    "none",
    "lower_accuracy",
    "raise_defense",
    "reflect_damage",
    "raise_evasion",
    "burn_dot",
    "trap",
    "block_bench",
    "heal_self",
    "heal_team",
    "ignore_def_buffs",
    "self_damage",
    "fortify",
    "flood",
}


def load(path: Path) -> dict:
    with path.open() as f:
        return json.load(f)


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    drakes = load(DATA / "drakes.json").get("drakes", {})
    moves = load(DATA / "moves.json").get("moves", {})
    types_doc = load(DATA / "types.json")
    types = set(types_doc.get("types", []))
    chart = types_doc.get("chart", {})
    synergies = load(DATA / "synergies.json").get("combos", {})

    # ── Moves ────────────────────────────────────────────────────────────────
    for mid, mv in moves.items():
        if mv.get("type") not in ALLOWED_MOVE_TYPES:
            errors.append(f"moves['{mid}'] has invalid type '{mv.get('type')}'")
        eff = mv.get("effect", "none")
        if eff not in ALLOWED_EFFECTS:
            errors.append(f"moves['{mid}'] has invalid effect '{eff}'")
        if not isinstance(mv.get("power", 0), int):
            errors.append(f"moves['{mid}'].power must be int")
        if not isinstance(mv.get("accuracy", 100), int):
            errors.append(f"moves['{mid}'].accuracy must be int")

    # ── Drakes ───────────────────────────────────────────────────────────────
    for did, dk in drakes.items():
        if dk.get("type") not in ALLOWED_DRAKE_TYPES:
            errors.append(f"drakes['{did}'].type '{dk.get('type')}' not in {ALLOWED_DRAKE_TYPES}")
        if dk.get("class") not in ALLOWED_DRAKE_CLASSES:
            errors.append(
                f"drakes['{did}'].class '{dk.get('class')}' not in {ALLOWED_DRAKE_CLASSES}"
            )
        bs = dk.get("base_stats", {})
        for key in ("hp", "atk", "def", "spd"):
            if key not in bs:
                errors.append(f"drakes['{did}'].base_stats missing '{key}'")
        total = sum(bs.get(k, 0) for k in ("hp", "atk", "def", "spd"))
        if total > 320:
            warnings.append(f"drakes['{did}'] stat total {total} is legendary-tier (>320)")
        for mid in dk.get("base_moves", []):
            if mid not in moves:
                errors.append(
                    f"drakes['{did}'].base_moves references unknown move '{mid}'"
                )
        evo = dk.get("evolution")
        if evo:
            to = evo.get("to")
            if to not in drakes:
                errors.append(
                    f"drakes['{did}'].evolution.to references unknown drake '{to}'"
                )
            if not isinstance(evo.get("level", 0), int):
                errors.append(f"drakes['{did}'].evolution.level must be int")

    # ── Types ────────────────────────────────────────────────────────────────
    for att, row in chart.items():
        if att not in types:
            errors.append(f"types.chart has attacker '{att}' not in types list")
        for defender in row:
            if defender not in types:
                errors.append(
                    f"types.chart['{att}'] has defender '{defender}' not in types list"
                )

    # ── Synergies ────────────────────────────────────────────────────────────
    for combo_key, mv in synergies.items():
        parts = combo_key.split("+")
        if len(parts) != 2:
            errors.append(f"synergies['{combo_key}']: key must be 'type+type'")
            continue
        for t in parts:
            if t not in ALLOWED_MOVE_TYPES:
                errors.append(f"synergies['{combo_key}']: type '{t}' unknown")
        if mv.get("effect", "none") not in ALLOWED_EFFECTS:
            errors.append(f"synergies['{combo_key}'].effect unknown: {mv.get('effect')}")

    # ── Dialog ───────────────────────────────────────────────────────────────
    dialog_dir = DATA / "dialog"
    if dialog_dir.exists():
        for df in dialog_dir.glob("*.json"):
            try:
                doc = load(df)
            except json.JSONDecodeError as e:
                errors.append(f"dialog/{df.name}: invalid JSON — {e}")
                continue
            npcs = doc.get("npcs", {})
            if not isinstance(npcs, dict):
                errors.append(f"dialog/{df.name}: 'npcs' must be an object")

    # ── Report ───────────────────────────────────────────────────────────────
    print(f"validate_data: {len(drakes)} drakes, {len(moves)} moves, "
          f"{len(synergies)} synergies checked.")
    for w in warnings:
        print(f"  ⚠ {w}")
    for e in errors:
        print(f"  ✗ {e}")
    if errors:
        print(f"FAIL — {len(errors)} error(s)")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
