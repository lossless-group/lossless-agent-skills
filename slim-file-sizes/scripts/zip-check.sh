#!/usr/bin/env bash
# zip-check.sh — report whether every file inside ONE zip already exists
# unpacked somewhere under a root folder (same file name, same byte size).
# Reports only. Deletes nothing.
#
# Matching is by name + size, not path, because founders' zips get unpacked
# and then reorganized. macOS junk (__MACOSX, ._*, .DS_Store) is ignored.
# Names are compared byte-wise, and a miss is re-checked by size alone in the
# same folder name, since curly quotes often decode differently in zips.
#
# Usage:
#   zip-check.sh <file.zip> [--root <dir>]
#     --root defaults to the folder above a _zip-originals/ folder, else the
#     zip's own folder.
#
# Exit codes: 0 every file found (safe to remove the zip), 1 some missing,
#             2 bad args.

set -euo pipefail
export LC_ALL=C

die() { echo "error: $*" >&2; exit 2; }
Z=""; ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) [[ -z "$Z" ]] && Z="$1" || die "one zip at a time" ;;
  esac
  shift
done
[[ -f "$Z" ]] || die "not a file: $Z"
if [[ -z "$ROOT" ]]; then
  case "$Z" in */_zip-originals/*) ROOT="${Z%%/_zip-originals/*}" ;; *) ROOT="$(dirname "$Z")" ;; esac
fi

idx="$(mktemp)"; want="$(mktemp)"; trap 'rm -f "$idx" "$want"' EXIT
find "$ROOT" -type f ! -iname '*.zip' -print0 \
  | xargs -0 stat -f '%z	%N' | awk -F'\t' '{n=$2; sub(/.*\//,"",n); print $1"\t"n}' | sort -u > "$idx"
unzip -Z -l "$Z" | awk '$1 ~ /^-/ {sz=$4; name=$0; sub(/^([^ ]+ +){9}/,"",name);
  if (name ~ /__MACOSX\//) next; n=name; sub(/.*\//,"",n);
  if (n=="" || n ~ /^\._/ || n==".DS_Store") next; print sz"\t"n}' > "$want"

total=$(wc -l < "$want" | tr -d ' '); missing=0
while IFS=$'\t' read -r sz nm; do
  grep -qxF "$sz	$nm" "$idx" && continue
  # Fallback: same size and a name that matches once spaces and non-ASCII
  # bytes are ignored ("Profile Health’s" vs "Profile Health???s", "CEO. pdf").
  stem="$(printf '%s' "$nm" | tr -cd '[:alnum:]._-')"
  if awk -F'\t' -v s="$sz" -v t="$stem" '$1==s { n=$2; gsub(/[^[:alnum:]._-]/,"",n); if (n==t) f=1 } END{exit !f}' "$idx"; then
    continue
  fi
  missing=$((missing + 1)); echo "  missing: $nm ($sz bytes)"
done < "$want"

size="$(du -h "$Z" | cut -f1)"
if (( missing == 0 )); then
  echo "SAFE  $total/$total files found unpacked  $size  $Z"; exit 0
fi
echo "CHECK $((total - missing))/$total files found unpacked  $size  $Z"
echo "      (if nothing was ever unpacked, unzip it; the zip may be the only copy)"
exit 1
