#!/usr/bin/env bash
# video-720p.sh — re-encode ONE video to an H.264 MP4 that plays everywhere
# and still looks right: 720p for people talking and slides, 1080p for screen
# recordings (small UI text blurs at 720p). Never upscales.
#
# Writes <name>.<height>p.mp4 beside the input; never touches the input.
#
# Usage:
#   video-720p.sh <video> [--height 720|1080] [--crf 26] [--audio 96k]
#
# Exit codes: 0 ok, 3 result not smaller (nothing written), 2 bad args.

set -euo pipefail

die() { echo "error: $*" >&2; exit 2; }
command -v ffmpeg >/dev/null || die "ffmpeg not installed: brew install ffmpeg"
IN=""; H=720; CRF=26; AB=96k
while [[ $# -gt 0 ]]; do
  case "$1" in
    --height) H="$2"; shift ;;
    --crf) CRF="$2"; shift ;;
    --audio) AB="$2"; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) [[ -z "$IN" ]] && IN="$1" || die "one file at a time" ;;
  esac
  shift
done
[[ -f "$IN" ]] || die "not a file: $IN"
OUT="${IN%.*}.${H}p.mp4"
[[ -e "$OUT" ]] && die "output exists, refusing to overwrite: $OUT"

TMP="$(mktemp -t slim-video).mp4"
trap 'rm -f "$TMP"' EXIT

# min(ih,H) keeps small videos at their own size; -2 keeps width even.
ffmpeg -nostdin -loglevel error -y -i "$IN" \
  -vf "scale=-2:'min(ih,$H)'" -c:v libx264 -preset slow -crf "$CRF" -pix_fmt yuv420p \
  -c:a aac -b:a "$AB" -movflags +faststart "$TMP"

before=$(stat -f %z "$IN"); after=$(stat -f %z "$TMP")
mb() { awk -v b="$1" 'BEGIN{printf "%.1fMB", b/1048576}'; }
if (( after >= before )); then
  echo "NOT-SMALLER  $(mb "$before") -> $(mb "$after")  $IN"; exit 3
fi
mv "$TMP" "$OUT"
echo "OK  $(mb "$before") -> $(mb "$after")  $OUT"
