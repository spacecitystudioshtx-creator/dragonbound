#!/usr/bin/env python3
"""Diagnose the local ComfyUI Desktop setup used by Dragonbound."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

APP_CONFIG = Path("/Users/spacecity/Library/Application Support/ComfyUI/config.json")
LOG_DIR = Path("/Users/spacecity/Library/Logs/ComfyUI")
PROJECT_CONFIG = Path(__file__).resolve().parents[1] / "config" / "comfyui.json"


def can_connect(url: str) -> bool:
    try:
        with urllib.request.urlopen(url.rstrip("/") + "/system_stats", timeout=1.5) as resp:
            resp.read(1)
        return True
    except Exception:
        return False


def main() -> int:
    project_url = "http://127.0.0.1:8000"
    if PROJECT_CONFIG.exists():
        project_url = json.loads(PROJECT_CONFIG.read_text()).get("url", project_url)

    print(f"Dragonbound ComfyUI URL: {project_url}")
    print(f"API reachable: {'yes' if can_connect(project_url) else 'no'}")

    if APP_CONFIG.exists():
        app_config = json.loads(APP_CONFIG.read_text())
        base_path = Path(app_config.get("basePath", ""))
        print(f"ComfyUI Desktop basePath: {base_path}")
        print(f"basePath exists: {'yes' if base_path.exists() else 'no'}")
        for child in ["models", "input", "output", "user"]:
            path = base_path / child
            print(f"{child}/ exists: {'yes' if path.exists() else 'no'}")
    else:
        print("ComfyUI Desktop config not found.")

    main_log = LOG_DIR / "main.log"
    if main_log.exists():
        print()
        print("Recent ComfyUI Desktop log:")
        lines = main_log.read_text(errors="replace").splitlines()[-12:]
        for line in lines:
            print(line)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
