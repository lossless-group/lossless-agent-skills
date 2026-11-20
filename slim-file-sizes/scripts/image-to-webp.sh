#!/usr/bin/env bash
# image-to-webp.sh — convert ONE image (JPEG, PNG, HEIC, TIFF, BMP) to WebP at a
# size that still reads on a retina laptop. Orientation is baked in and
# metadata stripped. Never upscales.
#
#   photos       --max 2000 --quality 80  (default)
#   screenshots  --max 2400 --quality 85  (text needs the pixels; never JPEG)
#
# Not for images headed to ImageKit or an og:image: those stay JPEG (see the
# prep-images-for-embed skill). Writes <name>.webp beside the input; never
# touches the input.
#
# Usage:
#   image-to-webp.sh <image> [--max 2000] [--quality 80]
#
# Exit codes: 0 ok, 3 result not smaller (nothing written), 2 bad args.

set -euo pipefail

die() { echo "error: $*" >&2; exit 2; }
command -v magick >/dev/null || die "ImageMagick not installed: brew install imagemagick"
IN=""; MAX=2000; Q=80
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max) MAX="$2"; shift ;;
    --quality) Q="$2"; shift ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) [[ -z "$IN" ]] && IN="$1" || die "one file at a time" ;;
  esac
  shift
done
[[ -f "$IN" ]] || die "not a file: $IN"
OUT="${IN%.*}.webp"
[[ -e "$OUT" ]] && die "output exists, refusing to overwrite: $OUT"

TMP="$(mktemp -t slim-image).webp"
trap 'rm -f "$TMP"' EXIT

# [0] takes the first frame only: animated GIFs belong to video-720p.sh.
magick "${IN}[0]" -auto-orient -strip -resize "${MAX}x${MAX}>" -quality "$Q" "$TMP"

before=$(stat -f %z "$IN"); after=$(stat -f %z "$TMP")
mb() { awk -v b="$1" 'BEGIN{printf "%.2fMB", b/1048576}'; }
if (( after >= before )); then
  echo "NOT-SMALLER  $(mb "$before") -> $(mb "$after")  $IN"; exit 3
fi
mv "$TMP" "$OUT"
echo "OK  $(mb "$before") -> $(mb "$after")  $(magick identify -format '%wx%h' "$OUT")  $OUT"
