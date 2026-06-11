#!/usr/bin/env bash
#
# regen-filemap.sh — regenerate FILEMAP.md at the repo root.
#
# Reads the current FILEMAP.md, replaces the content between
# <!-- TREE-START --> and <!-- TREE-END --> with a fresh `tree -L 3`
# output (with curated ignores), writes back, reports git diff status.
#
# If FILEMAP.md does not exist or lacks the sentinel markers, the
# script bootstraps a minimal one with a placeholder curator preface
# (the human edits the preface; the script keeps the tree current).
#
# Usage:
#   bash context-v/loops/maintain-filemap/scripts/regen-filemap.sh
#
# Discipline: see ../SKILL.md and ../../README.md.

set -euo pipefail

# ─── locate repo root + cd there ─────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "✗ Not inside a git repo. Run from anywhere inside a repo." >&2
  exit 1
fi
cd "$REPO_ROOT"

# ─── check tree CLI is available ─────────────────────────────────────
if ! command -v tree >/dev/null 2>&1; then
  echo "✗ tree CLI not found. Install via: brew install tree" >&2
  exit 1
fi

# ─── curated ignore pattern ──────────────────────────────────────────
# Edit only when a new "noise" dir consistently appears across repos.
IGNORE_PATTERN='node_modules|.git|.astro|dist|.vercel|.output|cache|*.lock|.DS_Store|.next|.turbo|target|build|coverage|tmp|.cache|*.tsbuildinfo'

# ─── generate the tree ───────────────────────────────────────────────
TREE_OUTPUT="$(tree -L 3 -I "$IGNORE_PATTERN" --noreport --dirsfirst .)"

# ─── if FILEMAP.md is missing or lacks markers, bootstrap one ────────
if [[ ! -f FILEMAP.md ]] || ! grep -q '<!-- TREE-START -->' FILEMAP.md; then
  REPO_NAME="$(basename "$REPO_ROOT")"
  cat > FILEMAP.md <<EOF
# Filemap · ${REPO_NAME}

> **What is this file?** A living snapshot of this repo's directory shape — top-level dirs annotated for purpose, plus an auto-generated tree to depth 3. Maintained by the [\`maintain-filemap\`](./context-v/loops/maintain-filemap/SKILL.md) loop. Regenerate via:
>
> \`\`\`bash
> bash context-v/loops/maintain-filemap/scripts/regen-filemap.sh
> \`\`\`

## Top-level directories

| Path | What it is |
|---|---|
| _(fill in by hand — what does each top-level dir contain and why?)_ | |

## Tree (depth 3, auto-generated)

<!-- TREE-START -->
\`\`\`
${TREE_OUTPUT}
\`\`\`
<!-- TREE-END -->

## See also

- [\`context-v/loops/maintain-filemap/SKILL.md\`](./context-v/loops/maintain-filemap/SKILL.md) — what governs this file's update cadence
- Per-submodule \`FILEMAP.md\` files (when submodules are present) for deeper trees
EOF
  echo "✓ Bootstrapped FILEMAP.md (you'll want to hand-edit the 'Top-level directories' table)"
else
  # ─── splice the new tree into the existing FILEMAP.md ────────────
  awk -v tree="$TREE_OUTPUT" '
    /<!-- TREE-START -->/ {
      print
      print ""
      print "```"
      print tree
      print "```"
      print ""
      skip = 1
      next
    }
    /<!-- TREE-END -->/ {
      print
      skip = 0
      next
    }
    !skip
  ' FILEMAP.md > FILEMAP.md.new
  mv FILEMAP.md.new FILEMAP.md
  echo "✓ Regenerated FILEMAP.md"
fi

# ─── report drift vs committed copy ──────────────────────────────────
if git diff --quiet -- FILEMAP.md 2>/dev/null; then
  echo "  No change vs committed copy — filemap was already current."
else
  echo "  ⚠ Drift detected — FILEMAP.md differs from committed copy."
  echo "  Review with: git diff FILEMAP.md"
  echo "  Stage with:  git add FILEMAP.md"
fi
