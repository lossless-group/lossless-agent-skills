#!/usr/bin/env bash
# pdf-compress.sh — shrink ONE PDF without losing its text or its legibility.
#
# Text and fonts stay vector (sharp at any zoom). Only embedded images are
# downsampled, to 200 dpi by default: a slide shown full screen on a retina
# laptop needs about that much. Writes <name>.slim.pdf beside the input and
# never touches the input. Deleting the original is the agent's call, after
# it has looked at the result.
#
# Usage:
#   pdf-compress.sh <file.pdf> [--dpi 200] [--quality 80] [--out <path>]
#
# Exit codes:
#   0  wrote a smaller PDF whose text survived
#   3  result was not smaller; nothing written (keep the original)
#   4  text check failed; nothing written (try `ocrmypdf --skip-text -O2`)
#   5  a page looks different (blanked slide, lost image, broken transparency)
#      or the page count changed; nothing written (keep the original)
#   2  bad arguments or missing tool
#
# The page check renders every page of both PDFs small and in gray and
# compares them. It catches what the text check can't: image-heavy decks with
# almost no text, where a lost picture or a blacked-out slide still passes.

set -euo pipefail

die() { echo "error: $*" >&2; exit 2; }
command -v gs >/dev/null || die "ghostscript (gs) not installed: brew install ghostscript"
command -v pdftotext >/dev/null || die "pdftotext not installed: brew install poppler"
command -v pdfinfo >/dev/null || die "pdfinfo not installed: brew install poppler"
command -v magick >/dev/null || die "ImageMagick (magick) not installed: brew install imagemagick"

IN=""; DPI=200; Q=80; OUT=""; MAXDIFF=0.06
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dpi) DPI="$2"; shift ;;
    --quality) Q="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    --max-diff) MAXDIFF="$2"; shift ;;
    -h|--help) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) [[ -z "$IN" ]] && IN="$1" || die "one file at a time" ;;
  esac
  shift
done
[[ -f "$IN" ]] || die "not a file: $IN"
[[ -z "$OUT" ]] && OUT="${IN%.*}.slim.pdf"
[[ -e "$OUT" ]] && die "output exists, refusing to overwrite: $OUT"

TMP="$(mktemp -t slim-pdf).pdf"
RENDER="$(mktemp -d -t slim-pages)"
trap 'rm -rf "$TMP" "$RENDER"' EXIT

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.6 -dNOPAUSE -dBATCH -dQUIET \
  -dDownsampleColorImages=true -dColorImageResolution="$DPI" -dColorImageDownsampleType=/Bicubic \
  -dDownsampleGrayImages=true  -dGrayImageResolution="$DPI"  -dGrayImageDownsampleType=/Bicubic \
  -dDownsampleMonoImages=true  -dMonoImageResolution=$((DPI * 2)) \
  -dAutoFilterColorImages=false -dColorImageFilter=/DCTEncode \
  -dAutoFilterGrayImages=false  -dGrayImageFilter=/DCTEncode \
  -dJPEGQ="$Q" -dDetectDuplicateImages=true -dSubsetFonts=true -dCompressFonts=true \
  -sOutputFile="$TMP" "$IN" 2>/dev/null || { echo "gs failed on $IN" >&2; exit 4; }

before=$(stat -f %z "$IN"); after=$(stat -f %z "$TMP")
chars_in=$(pdftotext -q "$IN" - 2>/dev/null | wc -m | tr -d ' ')
chars_out=$(pdftotext -q "$TMP" - 2>/dev/null | wc -m | tr -d ' ')

report() { printf '%s  %s -> %s  text %s -> %s chars  %s\n' "$1" \
  "$(awk -v b="$before" 'BEGIN{printf "%.1fMB", b/1048576}')" \
  "$(awk -v a="$after" 'BEGIN{printf "%.1fMB", a/1048576}')" \
  "$chars_in" "$chars_out" "$2"; }

# Text check: allow 2% drift (ligatures and whitespace extract differently).
if (( chars_in > 200 )) && (( chars_out * 100 < chars_in * 98 )); then
  report "TEXT-LOST" "$IN"; exit 4
fi
if (( after >= before )); then
  report "NOT-SMALLER" "$IN"; exit 3
fi

# Page check: same page count, and every page looks the same at thumbnail size.
pages_in=$(pdfinfo "$IN" 2>/dev/null | awk '/^Pages:/{print $2}')
pages_out=$(pdfinfo "$TMP" 2>/dev/null | awk '/^Pages:/{print $2}')
if [[ "$pages_in" != "$pages_out" ]]; then
  report "PAGES-CHANGED" "$IN (page count $pages_in -> $pages_out)"; exit 5
fi
mkdir -p "$RENDER/a" "$RENDER/b"
gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -r36 -o "$RENDER/a/p-%04d.png" "$IN" 2>/dev/null
gs -q -dNOPAUSE -dBATCH -sDEVICE=pnggray -r36 -o "$RENDER/b/p-%04d.png" "$TMP" 2>/dev/null
changed=""
for a in "$RENDER"/a/p-*.png; do
  b="$RENDER/b/$(basename "$a")"
  [[ -f "$b" ]] || { changed+=" $(basename "$a" .png)"; continue; }
  # compare exits 1 when images differ at all; the number is what matters
  diff=$( { magick compare -metric RMSE "$a" "$b" null: 2>&1 || true; } | sed -E 's/.*\(([0-9.e-]+)\).*/\1/')
  if awk -v d="$diff" -v m="$MAXDIFF" 'BEGIN{exit !(d > m)}'; then
    n=$(basename "$a" .png); changed+=" ${n#p-}($diff)"
  fi
done
if [[ -n "$changed" ]]; then
  report "PAGES-CHANGED" "$IN (pages that look different:$changed)"; exit 5
fi
mv "$TMP" "$OUT"
(( chars_in <= 200 )) && note="(little or no text: image-only PDF, consider ocrmypdf)" || note=""
report "OK" "$OUT $note"
