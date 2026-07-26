#!/bin/bash
# Process a DiffusionBee/ComfyUI raw PNG into a crisp Dragonbound game asset.
#
# Usage:
#   tools/process_pixel_asset.sh <raw_png> <output_png> <size>
#
# Examples:
#   tools/process_pixel_asset.sh ~/Downloads/ember-front-refresh_raw.png art/drakes/ember_front.png 64x64
#   tools/process_pixel_asset.sh ~/Downloads/kindra-tree-tile_raw.png art/generated/tiles/kindra_tree_16.png 16x16

set -euo pipefail

RAW="${1:?raw PNG path required}"
OUT="${2:?output PNG path required}"
SIZE="${3:?size required, like 64x64 or 16x16}"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required. Install with: brew install imagemagick" >&2
  exit 1
fi

if [ ! -f "$RAW" ]; then
  echo "Missing raw image: $RAW" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

# The pipeline intentionally forces hard pixels:
# - peel off plain/near-plain background from corners
# - trim and square sprite subjects
# - nearest-neighbor resize
# - reduce colors to reinforce the retro indexed look
if [ "${PIXEL_ASSET_SQUARE:-auto}" = "0" ] || [ "${SIZE%x*}" != "${SIZE#*x}" ] && [ "${SIZE%x*}" != "${SIZE#*x}" ]; then
  WIDTH="${SIZE%x*}"
  HEIGHT="${SIZE#*x}"
else
  WIDTH=""
  HEIGHT=""
fi

if [ -n "${WIDTH:-}" ] && [ "$WIDTH" != "$HEIGHT" ]; then
  magick "$RAW" \
    -alpha set \
    -filter point -resize "$SIZE^" \
    -gravity center -extent "$SIZE" \
    -colors 32 \
    PNG32:"$OUT"
else
  magick "$RAW" \
    -alpha set \
    -fuzz 18% -fill none -floodfill +0+0 'srgb(255,255,255)' \
    -fuzz 18% -fill none -floodfill +%[fx:w-1]+0 'srgb(255,255,255)' \
    -fuzz 18% -fill none -floodfill +0+%[fx:h-1] 'srgb(255,255,255)' \
    -fuzz 18% -fill none -floodfill +%[fx:w-1]+%[fx:h-1] 'srgb(255,255,255)' \
    -trim +repage \
    -background none -gravity center -extent "%[fx:max(w,h)]x%[fx:max(w,h)]" \
    -filter point -resize "$SIZE" \
    -colors 16 \
    PNG32:"$OUT"

  CLEAN_PY="${PIXEL_CLEAN_PYTHON:-}"
  if [ -z "$CLEAN_PY" ] && [ -x "$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3" ]; then
    CLEAN_PY="$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
  fi
  if [ -z "$CLEAN_PY" ]; then
    CLEAN_PY="python3"
  fi
  "$CLEAN_PY" "$(dirname "$0")/clean_sprite_alpha.py" "$OUT"
fi

# Force Godot to reimport this asset next run.
rm -f "${OUT}.import"
if [ -d ".godot/imported" ]; then
  base="$(basename "$OUT")"
  rm -f ".godot/imported/${base}"*
fi

echo "Processed $RAW -> $OUT ($SIZE)"
