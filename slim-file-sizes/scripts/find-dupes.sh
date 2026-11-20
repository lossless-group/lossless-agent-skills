#!/usr/bin/env bash
# find-dupes.sh — list byte-identical files under ONE folder, largest waste
# first. Reports only. Deletes nothing: which copy to keep is a judgment call
# (the one in the dataroom folder, usually, not the one in _zip-originals/).
#
# Usage:
#   find-dupes.sh <dir> [--min-kb 100]
#
# Exit code: 0 always (it's a report).

set -euo pipefail
export LC_ALL=C

die() { echo "error: $*" >&2; exit 2; }
DIR=""; MIN=100
while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-kb) MIN="$2"; shift ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) [[ -z "$DIR" ]] && DIR="$1" || die "one folder at a time" ;;
  esac
  shift
done
[[ -d "$DIR" ]] || die "not a folder: $DIR"

sums="$(mktemp)"; trap 'rm -f "$sums"' EXIT
find "$DIR" -type f -size +"${MIN}k" ! -name '.DS_Store' -print0 \
  | xargs -0 shasum -a 256 | sort > "$sums"

awk '{h=$1; sub(/^[^ ]+ +/,""); print h"\t"$0}' "$sums" | while IFS=$'\t' read -r h p; do
  printf '%s\t%s\t%s\n' "$h" "$(stat -f %z "$p")" "$p"
done | awk -F'\t' '
  { c[$1]++; s[$1]=$2; f[$1]=f[$1] "\x1f    " $3 }
  END {
    for (h in c) if (c[h] > 1) { w = s[h] * (c[h] - 1); total += w;
      printf "%d\t%.1fMB wasted  (%d copies of %.1fMB)%s\n", w, w/1048576, c[h], s[h]/1048576, f[h] }
    printf "%d\tTOTAL %.1fMB in extra copies\n", -1, total/1048576
  }' | sort -t$'\t' -k1,1 -rn | cut -f2- | tr '\037' '\n'
