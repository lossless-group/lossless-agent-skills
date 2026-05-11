#!/usr/bin/env bash
# favicon-hunt.sh — find the best favicon-style square asset for a domain.
#
# Sibling of logo-hunt.sh. Where logo-hunt looks for the company's WORDMARK
# (typically wide, used in headers), this script looks for the SQUARE icon
# variant — designed for small-tile rendering (favicons, app icons, OG image
# squares).
#
# Cascade (stops at first success):
#   Tier 1: <link rel="apple-touch-icon" href="..."> from homepage HTML
#           (180×180 typical, square, polished — usually the BEST tile asset)
#   Tier 2: <link rel="icon" href="..."> from homepage HTML
#   Tier 3: Common paths: /apple-touch-icon.png, /apple-touch-icon-precomposed.png
#   Tier 4: /favicon.svg, /favicon.png, /favicon.ico (in that order)
#   Tier 5: PWA manifest at <link rel="manifest"> — read its `icons[]` array
#   Tier 6: Google's S2 favicon service (always returns *something*):
#           https://www.google.com/s2/favicons?domain={d}&sz=128
#
# Usage:
#   favicon-hunt.sh <domain-or-url>
#     example: favicon-hunt.sh stripe.com
#
# Exit codes:
#   0  — found a candidate; JSON printed to stdout
#   2  — exhausted all tiers (extremely rare since tier 6 is a fallback that
#        always returns something for resolvable domains)
#   3  — bad arguments
#
# Stdout (on success):
#   {"tier":"site-apple-touch-icon","url":"https://stripe.com/img/v3/touch-icon.png","format":"png"}

# NB: deliberately NOT using `set -e` — many tiers contain grep-or-curl pipelines
# where "no match" is a normal outcome that should fall through to the next tier.
# We use `set -uo pipefail` for unset-var safety + pipefail-on-real-failures, and
# guard risky pipelines with `|| true`.
set -uo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: favicon-hunt.sh <domain-or-url>" >&2
  exit 3
fi

INPUT="$1"
if [[ "$INPUT" =~ ^https?:// ]]; then
  HOMEPAGE="$INPUT"
else
  HOMEPAGE="https://$INPUT"
fi
BASE="${HOMEPAGE%/}"
DOMAIN="$(echo "$BASE" | sed -E 's|^https?://||; s|/.*$||')"

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0"

# Resolve a relative URL against the homepage origin
resolve_url() {
  local url="$1"
  case "$url" in
    http://*|https://*) printf '%s' "$url" ;;
    //*) printf 'https:%s' "$url" ;;
    /*) printf '%s%s' "$BASE" "$url" ;;
    *) printf '%s/%s' "$BASE" "$url" ;;
  esac
}

# Verify a URL returns a real image (status 200, content-type: image/*, body > 100 bytes)
url_is_image() {
  local url="$1"
  local headers
  headers="$(curl -sI -L --max-time 8 -A "$UA" "$url" 2>/dev/null)"
  local status
  status="$(echo "$headers" | head -1 | awk '{print $2}')"
  if [ "$status" != "200" ]; then return 1; fi
  local ct
  ct="$(echo "$headers" | awk -F': *' 'tolower($1)=="content-type" {print tolower($2)}' | tr -d '\r' | tail -1)"
  case "$ct" in
    image/*) ;;
    *) return 1 ;;
  esac
  # Body size sanity check
  local size
  size="$(curl -sLo /dev/null -w '%{size_download}' --max-time 8 -A "$UA" "$url" 2>/dev/null || echo 0)"
  [ "$size" -ge 100 ] || return 1
  return 0
}

# Detect format from URL or HEAD response
infer_format() {
  local url="$1"
  case "$url" in
    *.svg|*.svg\?*) printf 'svg' ;;
    *.png|*.png\?*) printf 'png' ;;
    *.jpg|*.jpg\?*|*.jpeg|*.jpeg\?*) printf 'jpg' ;;
    *.ico|*.ico\?*) printf 'ico' ;;
    *.webp|*.webp\?*) printf 'webp' ;;
    *)
      local ct
      ct="$(curl -sI -L --max-time 5 -A "$UA" "$url" 2>/dev/null | awk -F': *' 'tolower($1)=="content-type" {print tolower($2)}' | tr -d '\r' | tail -1)"
      case "$ct" in
        image/svg*) printf 'svg' ;;
        image/png*) printf 'png' ;;
        image/jp*) printf 'jpg' ;;
        image/x-icon*|image/vnd.microsoft.icon*) printf 'ico' ;;
        image/webp*) printf 'webp' ;;
        *) printf 'png' ;;  # safest default
      esac
      ;;
  esac
}

# Download the homepage HTML once for tiers 1, 2, and 5
HTML="$(curl -s -L --max-time 10 -A "$UA" "$HOMEPAGE" 2>/dev/null || true)"

# --- Tier 1: <link rel="apple-touch-icon"> ----------------------------------

if [ -n "$HTML" ]; then
  href="$(printf '%s' "$HTML" | grep -oE '<link[^>]*rel="[^"]*apple-touch-icon[^"]*"[^>]*>' 2>/dev/null | grep -oE 'href="[^"]+"' 2>/dev/null | head -1 | sed -E 's/href="([^"]+)"/\1/' || true)"
  if [ -z "${href:-}" ]; then
    href="$(printf '%s' "$HTML" | grep -oE '<link[^>]*href="[^"]+"[^>]*rel="[^"]*apple-touch-icon[^"]*"' 2>/dev/null | grep -oE 'href="[^"]+"' 2>/dev/null | head -1 | sed -E 's/href="([^"]+)"/\1/' || true)"
  fi
  if [ -n "${href:-}" ]; then
    url="$(resolve_url "$href")"
    if url_is_image "$url"; then
      printf '{"tier":"site-apple-touch-icon","url":"%s","format":"%s"}\n' "$url" "$(infer_format "$url")"
      exit 0
    fi
  fi
fi

# --- Tier 2: <link rel="icon"> (any size, prefer largest) -------------------

if [ -n "$HTML" ]; then
  # Match all rel="icon" links and grab the href + sizes attribute
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    href="$(printf '%s' "$line" | grep -oE 'href="[^"]+"' 2>/dev/null | head -1 | sed -E 's/href="([^"]+)"/\1/' || true)"
    [ -z "${href:-}" ] && continue
    url="$(resolve_url "$href")"
    if url_is_image "$url"; then
      printf '{"tier":"site-link-icon","url":"%s","format":"%s"}\n' "$url" "$(infer_format "$url")"
      exit 0
    fi
  done < <(printf '%s' "$HTML" | grep -oE '<link[^>]*rel="[^"]*icon[^"]*"[^>]*>' 2>/dev/null || true)
fi

# --- Tier 3: Common apple-touch-icon paths ----------------------------------

for path in apple-touch-icon.png apple-touch-icon-precomposed.png apple-touch-icon-180x180.png apple-touch-icon-152x152.png; do
  url="$BASE/$path"
  if url_is_image "$url"; then
    printf '{"tier":"site-common-apple-touch","url":"%s","format":"png"}\n' "$url"
    exit 0
  fi
done

# --- Tier 4: Common favicon paths -------------------------------------------

for path in favicon.svg favicon-32x32.png favicon-96x96.png favicon.png favicon.ico; do
  url="$BASE/$path"
  if url_is_image "$url"; then
    printf '{"tier":"site-common-favicon","url":"%s","format":"%s"}\n' "$url" "$(infer_format "$url")"
    exit 0
  fi
done

# --- Tier 5: PWA manifest icons ---------------------------------------------

if [ -n "$HTML" ]; then
  manifest_href="$(printf '%s' "$HTML" | grep -oE '<link[^>]*rel="manifest"[^>]*>' 2>/dev/null | grep -oE 'href="[^"]+"' 2>/dev/null | head -1 | sed -E 's/href="([^"]+)"/\1/' || true)"
  if [ -n "${manifest_href:-}" ]; then
    manifest_url="$(resolve_url "$manifest_href")"
    manifest_body="$(curl -s -L --max-time 8 -A "$UA" "$manifest_url" 2>/dev/null || true)"
    if [ -n "$manifest_body" ]; then
      icon_src="$(printf '%s' "$manifest_body" | grep -oE '"src"[^"]*"[^"]+"' 2>/dev/null | head -1 | sed -E 's/.*"src"[^"]*"([^"]+)"/\1/' || true)"
      if [ -n "${icon_src:-}" ]; then
        url="$(resolve_url "$icon_src")"
        if url_is_image "$url"; then
          printf '{"tier":"site-pwa-manifest","url":"%s","format":"%s"}\n' "$url" "$(infer_format "$url")"
          exit 0
        fi
      fi
    fi
  fi
fi

# --- Tier 6: Google S2 favicon service (always returns something) -----------
# Free, no auth, returns a 128px PNG. Useful when the company's own site has
# nothing parseable. The result is a small PNG with whatever Google has cached.

google_url="https://www.google.com/s2/favicons?domain=${DOMAIN}&sz=128"
# Don't url_is_image-check this — Google returns a default globe icon if it has
# nothing for the domain, but that's still better than no chip at all. Always
# treat as success but mark the tier so caller knows it was a fallback.
printf '{"tier":"google-s2-fallback","url":"%s","format":"png"}\n' "$google_url"
exit 0
