#!/usr/bin/env bash
# logo-hunt.sh — try the SVG-first cascade for a domain and print the best logo URL found.
#
# This is a minimal, no-paid-API helper for tiers 1–3 of the cascade documented in SKILL.md.
# It does NOT call Brandfetch, Tavily, or Google CSE — those are higher tiers and the caller
# is expected to invoke them directly when this script returns no SVG (exit 2).
#
# Usage:
#   logo-hunt.sh <domain-or-url>
#     example: logo-hunt.sh stripe.com
#              logo-hunt.sh https://www.stripe.com/
#
# Exit codes:
#   0  — found a candidate; URL printed to stdout
#   2  — exhausted tiers 1–3 with no SVG candidate; caller should escalate to Brandfetch / Tavily
#   3  — bad arguments
#
# Stdout (on success): one line of JSON, e.g.
#   {"tier":"site-inline-svg","url":"data:image/svg+xml;base64,..."}
#   {"tier":"site-svg-path","url":"https://stripe.com/img/logo.svg"}
#   {"tier":"site-press-page","url":"https://stripe.com/files/brand/Stripe_logo.svg","page":"https://stripe.com/brand"}
#
# Stderr: progress logging.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: logo-hunt.sh <domain-or-url>" >&2
  exit 3
fi

INPUT="$1"

# Normalize to a homepage URL
if [[ "$INPUT" =~ ^https?:// ]]; then
  HOMEPAGE="$INPUT"
else
  HOMEPAGE="https://$INPUT"
fi

# Strip trailing slash and pull out base
BASE="${HOMEPAGE%/}"
DOMAIN="$(echo "$BASE" | sed -E 's|^https?://||; s|/.*$||')"

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0"

# Helper: HEAD-check a URL exists and is SVG-like (or at least an image)
url_is_svg() {
  local url="$1"
  local ct
  ct="$(curl -sI -L --max-time 8 -A "$UA" "$url" 2>/dev/null | awk -F': *' 'tolower($1)=="content-type" {print tolower($2)}' | tr -d '\r' | tail -1)"
  case "$ct" in
    *svg*) return 0 ;;
    *) return 1 ;;
  esac
}

# Helper: download URL to temp, sniff first bytes for "<svg"
url_body_is_svg() {
  local url="$1"
  local first
  first="$(curl -s -L --max-time 8 -A "$UA" "$url" 2>/dev/null | head -c 1024 | tr -d '\0')"
  if echo "$first" | grep -qiE '<\?xml|<svg'; then
    return 0
  fi
  return 1
}

# --- Tier 1: inline <svg> in the homepage's nav/header -----------------------
# Heuristic: pull the homepage HTML, isolate the first <svg>...</svg> block that
# appears within or near a <header>/<nav>/[class*="logo"] element. We're not
# trying to be perfect here — just trying to find SOMETHING usable.

echo "logo-hunt: tier 1 — inline <svg> scrape on $HOMEPAGE" >&2
HTML="$(curl -s -L --max-time 10 -A "$UA" "$HOMEPAGE" 2>/dev/null || true)"

if [ -n "$HTML" ]; then
  # Find any <svg ...>...</svg> block inside a <header> or <nav>. This is fuzzy
  # by design — strict HTML parsing in bash is a tar pit.
  inline_svg="$(echo "$HTML" | tr '\n' ' ' | grep -oE '<(header|nav)[^>]*>.*?</(header|nav)>' | head -1 | grep -oE '<svg[^>]*>.*?</svg>' | head -1 || true)"
  if [ -n "$inline_svg" ] && [ "${#inline_svg}" -gt 200 ]; then
    # Encode as data URL so the caller can either save it or render it.
    b64="$(printf '%s' "$inline_svg" | base64 | tr -d '\n')"
    printf '{"tier":"site-inline-svg","url":"data:image/svg+xml;base64,%s","bytes":%s}\n' "$b64" "${#inline_svg}"
    exit 0
  fi
fi

# --- Tier 2: common site SVG paths -------------------------------------------

echo "logo-hunt: tier 2 — common SVG paths on $BASE" >&2

CANDIDATES=(
  "$BASE/logo.svg"
  "$BASE/assets/logo.svg"
  "$BASE/img/logo.svg"
  "$BASE/images/logo.svg"
  "$BASE/static/logo.svg"
  "$BASE/static/img/logo.svg"
  "$BASE/static/images/logo.svg"
  "$BASE/brand/logo.svg"
  "$BASE/brand-assets/logo.svg"
  "$BASE/favicon.svg"
  "$BASE/apple-touch-icon.svg"
)

# Also: scrape any .svg URL referenced from the homepage HTML (often CDN-hosted).
if [ -n "$HTML" ]; then
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    CANDIDATES+=("$url")
  done < <(echo "$HTML" | grep -oE 'https?://[^"'"'"' ]+\.svg' | sort -u | head -10)

  # Plus relative .svg references — resolve to the base
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    case "$rel" in
      /*) CANDIDATES+=("$BASE$rel") ;;
       *) CANDIDATES+=("$BASE/$rel") ;;
    esac
  done < <(echo "$HTML" | grep -oE '(src|href)="[^"]+\.svg"' | sed -E 's/.*="([^"]+)".*/\1/' | grep -v '^https\?://' | sort -u | head -10)
fi

# Deduplicate
mapfile -t UNIQ < <(printf '%s\n' "${CANDIDATES[@]}" | awk '!seen[$0]++')

for cand in "${UNIQ[@]}"; do
  if url_body_is_svg "$cand"; then
    printf '{"tier":"site-svg-path","url":"%s"}\n' "$cand"
    exit 0
  fi
done

# --- Tier 3: brand / press / media pages -------------------------------------

echo "logo-hunt: tier 3 — brand/press/media pages" >&2

BRAND_PAGES=(
  "$BASE/brand"
  "$BASE/press"
  "$BASE/media"
  "$BASE/kit"
  "$BASE/brand-assets"
  "$BASE/about/press"
  "$BASE/about/brand"
  "$BASE/company/brand"
  "$BASE/legal/brand"
)

for page in "${BRAND_PAGES[@]}"; do
  body="$(curl -s -L --max-time 8 -A "$UA" "$page" 2>/dev/null || true)"
  [ -z "$body" ] && continue
  # First .svg URL referenced from the page (absolute or relative)
  svg_url="$(echo "$body" | grep -oE 'https?://[^"'"'"' ]+\.svg' | head -1 || true)"
  if [ -z "$svg_url" ]; then
    rel="$(echo "$body" | grep -oE '(src|href)="[^"]+\.svg"' | sed -E 's/.*="([^"]+)".*/\1/' | head -1 || true)"
    if [ -n "$rel" ]; then
      case "$rel" in
        /*) svg_url="$BASE$rel" ;;
        http*) svg_url="$rel" ;;
        *) svg_url="$page/$rel" ;;
      esac
    fi
  fi
  if [ -n "$svg_url" ] && url_body_is_svg "$svg_url"; then
    printf '{"tier":"site-press-page","url":"%s","page":"%s"}\n' "$svg_url" "$page"
    exit 0
  fi
done

echo "logo-hunt: exhausted tiers 1–3 with no SVG. Caller should escalate to Brandfetch / Tavily / Google CSE." >&2
exit 2
