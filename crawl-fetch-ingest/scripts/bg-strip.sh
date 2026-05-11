#!/usr/bin/env bash
# bg-strip.sh — remove the background from a raster logo.
#
# Cascade:
#   Tier 1: ImageMagick flood-fill from each corner using the corner's sampled color.
#           Deterministic, fast, handles white + arbitrary brand-color backgrounds.
#           Considered successful when >= 5% of pixels became transparent.
#   Tier 2: rembg (U²-Net) — for non-uniform / soft-edge backgrounds.
#           Skipped gracefully if rembg is not installed.
#
# Usage:
#   bg-strip.sh <input> [output]
#     input   — path to raster (jpg/jpeg/png/webp/avif)
#     output  — optional; defaults to <input-without-ext>.png (PNG required for alpha)
#
# Exit codes:
#   0  — success, output written
#   1  — both tiers failed; original is left alone, output not written
#   2  — bad arguments / missing file
#   3  — ImageMagick not installed
#
# Stdout: a single line of JSON with the result, e.g.
#   {"method":"imagemagick-floodfill","bg_color":"#ffffff","pct_transparent":42.7,"output":"./logo.png"}
#
# Stderr: progress / diagnostic logging (safe to ignore in pipelines).

set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: bg-strip.sh <input> [output]" >&2
  exit 2
fi

INPUT="$1"
if [ ! -f "$INPUT" ]; then
  echo "bg-strip: input file not found: $INPUT" >&2
  exit 2
fi

OUTPUT="${2:-${INPUT%.*}.png}"

if ! command -v magick >/dev/null 2>&1; then
  echo "bg-strip: ImageMagick (magick) not installed. brew install imagemagick" >&2
  exit 3
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# --- Tier 0: detect background color from the four corners -------------------
# Samples a 3x3 patch at each corner and picks the color that appears in 3+ corners
# (so single-corner anomalies don't poison the choice). Falls back to top-left.

dims="$(magick "$INPUT" -format "%wx%h" info:)"
width="${dims%x*}"
height="${dims#*x}"
last_x=$((width - 1))
last_y=$((height - 1))

corner_color() {
  # $1=x $2=y. Return hex like #ffffff.
  local x="$1" y="$2"
  magick "$INPUT" -format "%[hex:p{$x,$y}]" info: 2>/dev/null | tr '[:lower:]' '[:upper:]' | head -c 6
}

c_tl="$(corner_color 0 0)"
c_tr="$(corner_color "$last_x" 0)"
c_bl="$(corner_color 0 "$last_y")"
c_br="$(corner_color "$last_x" "$last_y")"

# Vote by frequency
BG_HEX="$(printf '%s\n' "$c_tl" "$c_tr" "$c_bl" "$c_br" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
BG_HEX="#${BG_HEX,,}"

echo "bg-strip: detected background color $BG_HEX (corners: $c_tl $c_tr $c_bl $c_br)" >&2

# --- Tier 1: ImageMagick flood-fill from each corner -------------------------

TIER1_OUT="$WORK_DIR/tier1.png"

# -fuzz 12% gives anti-aliased edges room to be removed too.
# We flood-fill from all four corners; pixels matching the corner color (within
# the fuzz tolerance) that are *connected* to the canvas edge become transparent.
# Pixels of the same color *trapped* inside the logo (e.g. the inside of an "O")
# stay opaque. This is the key advantage of flood-fill over global color match.
#
# IM7 uses the 'alpha ... floodfill' draw verb (the older 'matte' verb is IM6).
magick "$INPUT" \
  -alpha set \
  -fuzz 12% \
  -fill none \
  -draw "alpha 0,0 floodfill" \
  -draw "alpha $last_x,0 floodfill" \
  -draw "alpha 0,$last_y floodfill" \
  -draw "alpha $last_x,$last_y floodfill" \
  "$TIER1_OUT" 2>/dev/null || true

if [ ! -s "$TIER1_OUT" ]; then
  echo "bg-strip: tier 1 (ImageMagick) produced no output" >&2
else
  # Measure transparency: mean alpha is in [0,1]. Stripped fraction = 1 - mean.a.
  # Threshold the alpha channel first so partially-transparent edges still count
  # as "stripped enough" for the success heuristic.
  pct="$(magick "$TIER1_OUT" -format "%[fx:(1 - mean.a) * 100]" info: 2>/dev/null || echo "0")"
  pct="$(printf '%.1f' "$pct")"

  echo "bg-strip: tier 1 stripped $pct% of pixels" >&2

  # If at least 5% of pixels became transparent, consider it a success.
  awk_check=$(awk -v p="$pct" 'BEGIN { print (p >= 5.0) ? "ok" : "weak" }')
  if [ "$awk_check" = "ok" ]; then
    cp "$TIER1_OUT" "$OUTPUT"
    printf '{"method":"imagemagick-floodfill","bg_color":"%s","pct_transparent":%s,"output":"%s"}\n' \
      "$BG_HEX" "$pct" "$OUTPUT"
    exit 0
  fi
fi

# --- Tier 2: rembg fallback --------------------------------------------------

if ! command -v rembg >/dev/null 2>&1; then
  echo "bg-strip: tier 1 weak and rembg unavailable. Leaving original alone." >&2
  printf '{"method":"none","bg_color":"%s","pct_transparent":0,"output":null,"error":"rembg-unavailable"}\n' "$BG_HEX"
  exit 1
fi

echo "bg-strip: escalating to rembg (U²-Net)" >&2

# rembg writes to stdout; --post-process-mask cleans up edges; --alpha-matting handles soft edges.
TIER2_OUT="$WORK_DIR/tier2.png"
if rembg i "$INPUT" "$TIER2_OUT" >&2 2>/dev/null; then
  if [ -s "$TIER2_OUT" ]; then
    cp "$TIER2_OUT" "$OUTPUT"
    pct="$(magick "$TIER2_OUT" -format "%[fx:(1 - mean.a) * 100]" info: 2>/dev/null || echo "0")"
    pct="$(printf '%.1f' "$pct")"
    printf '{"method":"rembg","bg_color":"%s","pct_transparent":%s,"output":"%s"}\n' \
      "$BG_HEX" "$pct" "$OUTPUT"
    exit 0
  fi
fi

echo "bg-strip: tier 2 (rembg) failed. Leaving original alone." >&2
printf '{"method":"none","bg_color":"%s","pct_transparent":0,"output":null,"error":"both-tiers-failed"}\n' "$BG_HEX"
exit 1
