#!/usr/bin/env bash
# og-image-hunt.sh — find the og:image (or twitter:image) for a domain.
#
# Returns a URL only — by design we don't download. The og:image is typically a
# 1200×630 marketing-quality social card; useful for hero images, portfolio
# detail pages, deck banners. Caller decides if/when to download.
#
# Cascade (stops at first success):
#   Tier 1: <meta property="og:image"> from homepage HTML
#   Tier 2: <meta property="og:image:url">
#   Tier 3: <meta name="twitter:image">
#   Tier 4: <meta name="twitter:image:src">
#
# Usage:
#   og-image-hunt.sh <domain-or-url>
#
# Exit codes:
#   0  — found, JSON to stdout
#   2  — none of the four meta tags present
#   3  — bad arguments

set -uo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: og-image-hunt.sh <domain-or-url>" >&2
  exit 3
fi

INPUT="$1"
if [[ "$INPUT" =~ ^https?:// ]]; then
  HOMEPAGE="$INPUT"
else
  HOMEPAGE="https://$INPUT"
fi
BASE="${HOMEPAGE%/}"

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0"

resolve_url() {
  local url="$1"
  case "$url" in
    http://*|https://*) printf '%s' "$url" ;;
    //*) printf 'https:%s' "$url" ;;
    /*) printf '%s%s' "$BASE" "$url" ;;
    *) printf '%s/%s' "$BASE" "$url" ;;
  esac
}

# Try to extract a meta-tag content value matching a property/name pattern.
# Handles both attribute orders ("content" first or "property" first), since
# different sites + Webflow + various CMSs alternate.
extract_meta() {
  local html="$1"
  local pattern="$2"
  # Pattern A: <meta property="og:image" content="..."> (or name="...")
  local hit
  hit="$(printf '%s' "$html" | grep -oE "<meta[^>]*(property|name)=\"$pattern\"[^>]*content=\"[^\"]+\"" 2>/dev/null | head -1 | grep -oE 'content="[^"]+"' 2>/dev/null | sed -E 's/content="([^"]+)"/\1/' || true)"
  if [ -n "${hit:-}" ]; then
    printf '%s' "$hit"
    return 0
  fi
  # Pattern B: <meta content="..." property="og:image"> (Webflow does this)
  hit="$(printf '%s' "$html" | grep -oE "<meta[^>]*content=\"[^\"]+\"[^>]*(property|name)=\"$pattern\"" 2>/dev/null | head -1 | grep -oE 'content="[^"]+"' 2>/dev/null | sed -E 's/content="([^"]+)"/\1/' || true)"
  if [ -n "${hit:-}" ]; then
    printf '%s' "$hit"
    return 0
  fi
  return 1
}

HTML="$(curl -s -L --max-time 10 -A "$UA" "$HOMEPAGE" 2>/dev/null || true)"
if [ -z "$HTML" ]; then
  echo "og-image-hunt: empty response from $HOMEPAGE" >&2
  exit 2
fi

# Try the four meta-tag variants in order
for spec in "og:image" "og:image:url" "twitter:image" "twitter:image:src"; do
  raw="$(extract_meta "$HTML" "$spec" || true)"
  if [ -n "${raw:-}" ]; then
    url="$(resolve_url "$raw")"
    case "$spec" in
      og:image*) tier="og-image" ;;
      twitter:image*) tier="twitter-image" ;;
    esac
    # Decode common HTML entities in the URL (&amp; → &)
    url="${url//&amp;/&}"
    printf '{"tier":"%s","property":"%s","url":"%s"}\n' "$tier" "$spec" "$url"
    exit 0
  fi
done

echo "og-image-hunt: no og:image or twitter:image meta tag found on $HOMEPAGE" >&2
exit 2
