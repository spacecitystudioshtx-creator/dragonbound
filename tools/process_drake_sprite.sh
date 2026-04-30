#!/bin/bash
# Drake sprite processor: takes a 512x512 DiffusionBee output and produces a
# clean 64x64 game sprite with transparent background.
#
# Usage:
#   ./process_drake_sprite.sh <drake_id>
#   (expects ~/Downloads/<drake_id>_raw.png from DiffusionBee Save Image As)
#
# Pipeline:
#   1. Floodfill from 4 corners + 4 edge midpoints with 25% fuzz to peel off
#      whatever background SD inserted (clouds, grass, ground, fades, etc.)
#   2. Trim transparent edges
#   3. Center in a square canvas
#   4. Nearest-neighbor downscale to 64x64

set -e

DRAKE="${1:?usage: $0 <drake_id>}"
RAW="$HOME/Downloads/${DRAKE}_raw.png"
OUT="$HOME/Documents/DragonBound/art/drakes/${DRAKE}_front.png"

if [ ! -f "$RAW" ]; then
    echo "Missing source: $RAW" >&2
    exit 1
fi

magick "$RAW" \
    -alpha set -fuzz 25% -fill none \
    -floodfill +0+0 'srgb(0,0,0)' \
    -fuzz 25% -floodfill +511+0 'srgb(0,0,0)' \
    -fuzz 25% -floodfill +0+511 'srgb(0,0,0)' \
    -fuzz 25% -floodfill +511+511 'srgb(0,0,0)' \
    -fuzz 25% -floodfill +255+0 'srgb(0,0,0)' \
    -fuzz 25% -floodfill +0+255 'srgb(0,0,0)' \
    -fuzz 25% -floodfill +511+255 'srgb(0,0,0)' \
    -fuzz 25% -floodfill +255+511 'srgb(0,0,0)' \
    -trim +repage \
    -background none -gravity center -extent "%[fx:max(w,h)]x%[fx:max(w,h)]" \
    -filter point -resize 64x64 \
    "$OUT"

# Force Godot to reimport
rm -f "${OUT}.import" "$HOME/Documents/DragonBound/.godot/imported/${DRAKE}_front"*

echo "$DRAKE -> $OUT"
