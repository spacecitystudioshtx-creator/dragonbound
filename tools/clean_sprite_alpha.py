#!/usr/bin/env python3
"""Remove tiny loose opaque fragments from a processed sprite PNG."""

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image


def neighbors(x: int, y: int, width: int, height: int):
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            nx = x + dx
            ny = y + dy
            if 0 <= nx < width and 0 <= ny < height:
                yield nx, ny


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: clean_sprite_alpha.py <png>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    img = Image.open(path).convert("RGBA")
    width, height = img.size
    pixels = img.load()
    seen = [[False for _ in range(width)] for _ in range(height)]
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            if seen[y][x] or pixels[x, y][3] == 0:
                continue
            queue = deque([(x, y)])
            seen[y][x] = True
            comp: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                comp.append((px, py))
                for nx, ny in neighbors(px, py, width, height):
                    if not seen[ny][nx] and pixels[nx, ny][3] > 0:
                        seen[ny][nx] = True
                        queue.append((nx, ny))
            components.append(comp)

    if not components:
        img.save(path)
        return 0

    largest = max(len(comp) for comp in components)
    keep_threshold = max(24, int(largest * 0.015))
    keep = set()
    for comp in components:
        if len(comp) >= keep_threshold or len(comp) == largest:
            keep.update(comp)

    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] > 0 and (x, y) not in keep:
                r, g, b, _ = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)

    img.save(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
