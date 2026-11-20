#!/usr/bin/env bash
# deck-to-pdf.sh — export ONE .key / .pptx / .ppt to PDF with the app that owns
# the format, so fonts and layout come out exactly as the founder built them.
#
#   .key        -> Keynote (the only reliable reader of current Keynote files)
#   .pptx/.ppt  -> PowerPoint; falls back to Keynote if PowerPoint is missing
#
# Before exporting it lists embedded video and the largest media, so the agent
# can log what the PDF drops (a PDF keeps only a still frame of a video).
# Writes <name>.pdf beside the input; never touches the input. Run
# pdf-compress.sh on the result next.
#
# Usage:
#   deck-to-pdf.sh <deck> [--app keynote|powerpoint] [--out <path>]
#
# macOS only. The first run may ask permission to control Keynote or
# PowerPoint, and PowerPoint's sandbox may ask to grant access to the folder.

set -euo pipefail

die() { echo "error: $*" >&2; exit 2; }
IN=""; APP=""; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) APP="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) [[ -z "$IN" ]] && IN="$1" || die "one file at a time" ;;
  esac
  shift
done
[[ -e "$IN" ]] || die "not found: $IN"
IN="$(cd "$(dirname "$IN")" && pwd)/$(basename "$IN")"
ext="$(echo "${IN##*.}" | tr '[:upper:]' '[:lower:]')"
[[ -z "$OUT" ]] && OUT="${IN%.*}.pdf"
[[ -e "$OUT" ]] && die "output exists, refusing to overwrite: $OUT"
OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"

if [[ -z "$APP" ]]; then
  case "$ext" in
    key) APP=keynote ;;
    pptx|ppt) [[ -d "/Applications/Microsoft PowerPoint.app" ]] && APP=powerpoint || APP=keynote ;;
    *) die "not a deck: $ext" ;;
  esac
fi

# What's inside: video and the heaviest media (.pptx and file-form .key are zips).
if [[ -f "$IN" ]] && unzip -tq "$IN" >/dev/null 2>&1; then
  echo "media inside $(basename "$IN"):"
  LC_ALL=C unzip -l "$IN" | awk 'NR>3 && $4 ~ /(media|Data)\// {printf "  %7.1fMB  %s\n", $1/1048576, $4}' | sort -rn | head -5
  LC_ALL=C unzip -l "$IN" | awk 'tolower($4) ~ /\.(mov|mp4|m4v|avi|wmv)$/ {printf "  VIDEO (dropped by PDF): %s %.1fMB\n", $4, $1/1048576}'
fi

case "$APP" in
  keynote)
    osascript - "$IN" "$OUT" <<'APPLESCRIPT'
on run argv
  set inFile to POSIX file (item 1 of argv)
  set outFile to POSIX file (item 2 of argv)
  tell application "Keynote"
    set d to open inFile
    export d to outFile as PDF with properties {PDF image quality:Better}
    close d saving no
  end tell
end run
APPLESCRIPT
    ;;
  powerpoint)
    osascript - "$IN" "$OUT" <<'APPLESCRIPT'
on run argv
  set inFile to POSIX file (item 1 of argv)
  set outFile to (item 2 of argv)
  tell application "Microsoft PowerPoint"
    open inFile
    save active presentation in outFile as save as PDF
    close active presentation saving no
  end tell
end run
APPLESCRIPT
    ;;
  *) die "unknown app: $APP" ;;
esac

[[ -f "$OUT" ]] || { echo "export produced no file (check app permissions)" >&2; exit 4; }
printf 'OK  %s -> %s  %s\n' \
  "$(du -h "$IN" | cut -f1)" "$(du -h "$OUT" | cut -f1)" "$OUT"
echo "next: pdf-compress.sh \"$OUT\""
