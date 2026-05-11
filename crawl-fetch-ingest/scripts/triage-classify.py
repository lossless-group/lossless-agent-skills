#!/usr/bin/env python3
"""
triage-classify.py — auto-classify the brand assets in a firm directory.

Sibling of the `routines/triage-brand-assets.md` subroutine. Reads each
`portfolio/{co-slug}.md`, examines the referenced logo file, applies the rubric
documented in the routine, and emits a JSON report. **Does not persist
anything** — the agent + user decide what to write back to the frontmatter
during the conversational walk-through.

Usage:
  triage-classify.py <firm-dir>
    firm-dir — e.g. data/firms/calm-storm-ventures

  triage-classify.py <firm-dir> --skip-reviewed
    Suppress entries whose review_status is already set to anything other than
    `pending` or unset.

Output (stdout): a JSON object with shape:

  {
    "firm_dir": "...",
    "count_total": 27,
    "count_by_suggestion": {"good-to-go": 14, "not-urgent-passable": 8, ...},
    "entries": [
      {
        "slug": "visible",
        "name": "Visible",
        "logo_path": "portfolio/trademark__Visible.png",
        "logo_abs": "/Users/.../trademark__Visible.png",
        "homepage": "https://www.makevisible.com/",
        "deck_name": "Visible",
        "existing_status": "pending",
        "signals": {
          "exists": true,
          "format": "png",
          "size_kb": 12.4,
          "width": 800,
          "height": 800,
          "pct_transparent": 14.1,
          "mean_fg_luminance": 234.1,
          "bg_color_detected": "#000000",
          "bg_strip_method": "imagemagick-floodfill"
        },
        "axes": {
          "existence": "good-to-go",
          "format": "not-urgent-passable",
          "bg_strip": "urgent-rework",
          "foreground": "good-to-go",
          "resolution": "good-to-go",
          "file_size": "good-to-go",
          "flagged": "good-to-go"
        },
        "suggested": "urgent-rework",
        "rationale": "bg-strip removed only 14% of pixels — strip likely got the bg wrong.",
        "source": "og-image-stripped"
      },
      ...
    ]
  }

Dependencies: Pillow (for image inspection). If not installed, prints a friendly
hint and exits 3.
"""

import json
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("triage-classify: install Pillow first: pip3 install Pillow", file=sys.stderr)
    sys.exit(3)


def parse_frontmatter(md_path: Path) -> dict:
    """Cheap YAML parser — just enough for our flat frontmatter. Avoids adding a yaml dep."""
    text = md_path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return {}
    raw = m.group(1)
    out = {}
    for line in raw.splitlines():
        if not line or line.startswith("#"):
            continue
        # Skip nested keys (we don't need them for triage)
        if line.startswith(" ") or line.startswith("\t") or line.startswith("-"):
            continue
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        key = key.strip()
        val = val.strip()
        # Strip quotes
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        elif val.startswith("'") and val.endswith("'"):
            val = val[1:-1]
        # Cheap type coercion
        if val == "true":
            val = True
        elif val == "false":
            val = False
        elif val == "null":
            val = None
        out[key] = val
    return out


def analyze_image(path: Path) -> dict:
    """Inspect a raster image and return signals."""
    out = {
        "exists": path.exists(),
        "format": path.suffix.lstrip(".").lower(),
        "size_kb": round(path.stat().st_size / 1024, 1) if path.exists() else 0,
        "size_bytes": path.stat().st_size if path.exists() else 0,
        "width": None,
        "height": None,
        "pct_transparent": None,
        "mean_fg_luminance": None,
    }
    if not path.exists() or out["format"] == "svg":
        return out
    try:
        img = Image.open(path)
        out["width"] = img.width
        out["height"] = img.height
        img = img.convert("RGBA")
        opaque = 0
        total_lum = 0.0
        total = img.width * img.height
        for r, g, b, a in img.getdata():
            if a < 32:
                continue
            opaque += 1
            # Rec.709 luminance
            total_lum += 0.2126 * r + 0.7152 * g + 0.0722 * b
        if total > 0:
            out["pct_transparent"] = round((total - opaque) / total * 100, 1)
        if opaque > 0:
            out["mean_fg_luminance"] = round(total_lum / opaque, 1)
    except Exception as e:
        out["pil_error"] = str(e)
    return out


def worst(a: str, b: str) -> str:
    """Return the worse of two classifications."""
    order = ["good-to-go", "not-urgent-passable", "urgent-rework"]
    return a if order.index(a) > order.index(b) else b


def classify(frontmatter: dict, signals: dict, deck_frame_bg: str | None) -> tuple[str, dict, str]:
    """Apply rubric. Returns (suggested_bucket, axes, rationale)."""
    rationale_parts = []
    axes = {}

    # Existence
    if not signals["exists"]:
        axes["existence"] = "urgent-rework"
        rationale_parts.append(f"logo file missing at {frontmatter.get('logo','?')}")
    else:
        axes["existence"] = "good-to-go"

    # Flagged
    status = (frontmatter.get("status") or "").lower()
    if status in ("unresolved", "flagged"):
        axes["flagged"] = "urgent-rework"
        rationale_parts.append(f"company status is `{status}` in frontmatter")
    else:
        axes["flagged"] = "good-to-go"

    # Format — triage cares about "renders correctly today," not "is this our ideal
    # source format." PNG/WebP with alpha is fine. SVG is fine. Only flag JPEG
    # (no alpha → bg shows through) as a current rendering concern.
    fmt = signals["format"]
    if fmt in ("svg", "png", "webp"):
        axes["format"] = "good-to-go"
    elif fmt in ("jpg", "jpeg"):
        axes["format"] = "not-urgent-passable"
        rationale_parts.append("logo is JPEG — no alpha, bg will show through on non-white frames")
    else:
        axes["format"] = "good-to-go"

    # bg-strip success
    pct = signals.get("pct_transparent")
    bg_stripped = frontmatter.get("logo_bg_stripped")
    if fmt == "svg" or bg_stripped is False or pct is None:
        axes["bg_strip"] = "good-to-go"
    elif pct < 5:
        axes["bg_strip"] = "urgent-rework"
        rationale_parts.append(f"bg-strip removed only {pct}% of pixels — likely failed")
    elif pct < 30:
        axes["bg_strip"] = "urgent-rework"
        rationale_parts.append(f"bg-strip only {pct}% — suspicious")
    elif pct < 60:
        axes["bg_strip"] = "not-urgent-passable"
        rationale_parts.append(f"bg-strip {pct}% — partial, possibly missed some edges")
    else:
        axes["bg_strip"] = "good-to-go"

    # Foreground luminance vs deck frame
    lum = signals.get("mean_fg_luminance")
    if lum is None or fmt == "svg":
        axes["foreground"] = "good-to-go"
    else:
        # Default frame is white. Anything dark on it works. If a bgColor (deck_frame_bg)
        # is set, light glyphs work too.
        if deck_frame_bg:
            # Frame is dark-ish — light glyphs render. Just sanity-check there's enough contrast.
            try:
                # crude: parse #rrggbb, compute lum
                frame_hex = deck_frame_bg.lstrip("#")
                fr, fg, fb = int(frame_hex[0:2], 16), int(frame_hex[2:4], 16), int(frame_hex[4:6], 16)
                frame_lum = 0.2126 * fr + 0.7152 * fg + 0.0722 * fb
                contrast = abs(lum - frame_lum)
                if contrast < 60:
                    axes["foreground"] = "urgent-rework"
                    rationale_parts.append(f"foreground lum {lum} too close to frame lum {frame_lum:.0f} — low contrast")
                elif contrast < 120:
                    axes["foreground"] = "not-urgent-passable"
                    rationale_parts.append(f"foreground/frame contrast moderate ({contrast:.0f})")
                else:
                    axes["foreground"] = "good-to-go"
            except Exception:
                axes["foreground"] = "good-to-go"
        else:
            # Frame is default white (lum ~255). Light glyphs invisible.
            if lum > 200:
                axes["foreground"] = "urgent-rework"
                rationale_parts.append(f"foreground lum {lum} too light for white chip frame (set bgColor)")
            elif lum > 160:
                axes["foreground"] = "not-urgent-passable"
                rationale_parts.append(f"foreground lum {lum} borderline against white frame")
            else:
                axes["foreground"] = "good-to-go"

    # Resolution
    w = signals.get("width") or 0
    h = signals.get("height") or 0
    longest = max(w, h)
    if fmt == "svg":
        axes["resolution"] = "good-to-go"
    elif longest < 80:
        axes["resolution"] = "urgent-rework"
        rationale_parts.append(f"only {w}×{h}px — will pixelate")
    elif longest < 200:
        axes["resolution"] = "not-urgent-passable"
        rationale_parts.append(f"low-res {w}×{h}px — fine at 22px chip, not at scale")
    else:
        axes["resolution"] = "good-to-go"

    # File size
    bytes_ = signals.get("size_bytes") or 0
    if not signals["exists"]:
        axes["file_size"] = "urgent-rework"
    elif bytes_ < 500:
        axes["file_size"] = "urgent-rework"
        rationale_parts.append(f"file is only {bytes_} B — probably broken")
    elif bytes_ > 4_000_000:
        axes["file_size"] = "not-urgent-passable"
        rationale_parts.append(f"file is {bytes_/1_000_000:.1f} MB — inefficient")
    else:
        axes["file_size"] = "good-to-go"

    # Combine — worst of all axes
    overall = "good-to-go"
    for v in axes.values():
        overall = worst(overall, v)

    rationale = "; ".join(rationale_parts) if rationale_parts else "all axes clean"
    return overall, axes, rationale


def discover_deck_bg_colors(firm_dir: Path) -> dict[str, str]:
    """
    Best-effort: look for a sibling deck-data file that maps slug → bgColor.
    Currently a no-op stub — the agent passes this in via env var if available.
    Searches `<repo>/src/data/portfolio-snapshot.ts` upward from the firm dir
    and grabs slug + bgColor pairs by regex.
    """
    result = {}
    # Walk upward looking for a portfolio-snapshot.ts
    for parent in [firm_dir] + list(firm_dir.parents):
        cand = parent / "src" / "data" / "portfolio-snapshot.ts"
        if cand.exists():
            text = cand.read_text(encoding="utf-8")
            for m in re.finditer(r'slug:\s*"([^"]+)".*?bgColor:\s*"([^"]+)"', text):
                result[m.group(1)] = m.group(2)
            break
    return result


def main():
    args = sys.argv[1:]
    if not args:
        print("Usage: triage-classify.py <firm-dir> [--skip-reviewed]", file=sys.stderr)
        sys.exit(2)
    firm_dir = Path(args[0]).resolve()
    skip_reviewed = "--skip-reviewed" in args
    if not firm_dir.is_dir():
        print(f"triage-classify: not a directory: {firm_dir}", file=sys.stderr)
        sys.exit(2)
    port_dir = firm_dir / "portfolio"
    if not port_dir.is_dir():
        print(f"triage-classify: no portfolio/ subdir in {firm_dir}", file=sys.stderr)
        sys.exit(2)

    deck_bg = discover_deck_bg_colors(firm_dir)

    entries = []
    for md in sorted(port_dir.glob("*.md")):
        # Skip CEO files (they're person assets, not brand)
        if md.stem.endswith("-ceo"):
            continue
        # Skip FLAGGED stub files — they have no logo
        if md.stem.endswith("-FLAGGED"):
            fm = parse_frontmatter(md)
            entries.append({
                "slug": fm.get("slug") or md.stem,
                "name": fm.get("name") or md.stem,
                "logo_path": None,
                "logo_abs": None,
                "homepage": fm.get("homepage"),
                "deck_name": fm.get("deck_name"),
                "existing_status": fm.get("review_status") or "pending",
                "signals": {"exists": False, "format": None, "size_kb": 0, "width": None, "height": None,
                            "pct_transparent": None, "mean_fg_luminance": None, "size_bytes": 0},
                "axes": {"existence": "urgent-rework", "flagged": "urgent-rework"},
                "suggested": "urgent-rework",
                "rationale": "flagged unresolved — no logo to assess",
                "source": fm.get("logo_asset_strategy") or "none",
            })
            continue

        fm = parse_frontmatter(md)
        if skip_reviewed and fm.get("review_status") and fm["review_status"] != "pending":
            continue

        logo_rel = fm.get("logo")
        if not logo_rel or logo_rel in ("null", "None"):
            entries.append({
                "slug": fm.get("slug") or md.stem,
                "name": fm.get("name") or md.stem,
                "logo_path": None,
                "logo_abs": None,
                "homepage": fm.get("homepage"),
                "deck_name": fm.get("deck_name"),
                "existing_status": fm.get("review_status") or "pending",
                "signals": {"exists": False, "format": None},
                "axes": {"existence": "urgent-rework"},
                "suggested": "urgent-rework",
                "rationale": "no logo: field in frontmatter",
                "source": "none",
            })
            continue

        logo_path = (md.parent / logo_rel).resolve()
        signals = analyze_image(logo_path)
        slug = fm.get("slug") or md.stem
        deck_frame_bg = deck_bg.get(slug)
        suggested, axes, rationale = classify(fm, signals, deck_frame_bg)

        entries.append({
            "slug": slug,
            "name": fm.get("name") or slug,
            "logo_path": logo_rel,
            "logo_abs": str(logo_path),
            "homepage": fm.get("homepage"),
            "deck_name": fm.get("deck_name"),
            "deck_frame_bg": deck_frame_bg,
            "existing_status": fm.get("review_status") or "pending",
            "signals": signals,
            "axes": axes,
            "suggested": suggested,
            "rationale": rationale,
            "source": fm.get("logo_asset_strategy") or "?",
        })

    count_by = {}
    for e in entries:
        count_by[e["suggested"]] = count_by.get(e["suggested"], 0) + 1

    out = {
        "firm_dir": str(firm_dir),
        "count_total": len(entries),
        "count_by_suggestion": count_by,
        "entries": entries,
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
