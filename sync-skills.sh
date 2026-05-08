#!/usr/bin/env bash
#
# sync-skills.sh — Make every skill in lossless-skills discoverable to
# Claude Code and Pi.
#
# Background. Both Claude Code (~/.claude/skills/) and Pi (~/.pi/skills/)
# discover skills only at the TOP LEVEL of their skill directory — they
# do not recurse. Per Claude Code's official docs:
#   ~/.claude/skills/<skill-name>/SKILL.md
# So an umbrella symlink (e.g. ~/.claude/skills/lossless-skills -> repo)
# does NOT surface skills nested inside; each skill needs its own
# top-level entry. Pi follows the same convention.
#
# This script ensures one symlink per skill in each target directory.
# Idempotent: re-running creates only what's missing, surfaces drift.
#
# Two skill sources in lossless-skills:
#   1. REGULAR skills — top-level dirs containing a SKILL.md directly.
#      Auto-discovered by walking the repo root.
#   2. NESTED skills — skills inside a submodule that keeps its own
#      <repo>/skills/<name>/SKILL.md layout (e.g. chroma-agent-skills).
#      Listed explicitly below; add new ones as we add new such submodules.
#
# Usage:
#   bash sync-skills.sh           # apply
#   bash sync-skills.sh --dry-run # show what would change, change nothing
#

set -euo pipefail

# ─────────────────── config ──────────────────────────────────────────────

# Targets — directories that should contain one symlink per skill. Each
# is checked for existence; missing targets are skipped with a warning,
# never auto-created (we don't want to materialize agent config dirs the
# user hasn't installed).
TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.pi/skills"
)

# Nested-skill collections. Format: "<source-path-relative-to-repo>:<symlink-name>"
# Add an entry whenever a new submodule ships skills under <repo>/skills/.
NESTED_SKILLS=(
  "chroma-agent-skills/skills/chroma-local:chroma-local"
  "chroma-agent-skills/skills/chroma-cloud:chroma-cloud"
)

# Top-level entries that are *not* skills (avoid trying to symlink them).
NON_SKILL_TOPLEVEL=(
  "changelog"
  "node_modules"
  ".git"
  ".github"
  "scripts"
  "src"
)

# ─────────────────── runtime ─────────────────────────────────────────────

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then DRY_RUN=1; fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

is_non_skill_toplevel() {
  local name="$1"
  for n in "${NON_SKILL_TOPLEVEL[@]}"; do
    [[ "$name" == "$n" ]] && return 0
  done
  return 1
}

# Discover regular top-level skills: dirs containing SKILL.md directly.
declare -a REGULAR_SKILLS=()
for dir in "$REPO_ROOT"/*/; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"
  if is_non_skill_toplevel "$name"; then continue; fi
  if [[ -f "$dir/SKILL.md" ]]; then
    REGULAR_SKILLS+=("$name")
  fi
done

# Canonicalize a path — resolve every symlink and ".." in the chain.
# Pure bash + cd/pwd -P; works on macOS and Linux.
canonical_path() {
  local p="$1"
  [[ -e "$p" ]] || { echo ""; return 1; }
  if [[ -d "$p" ]]; then
    ( cd "$p" && pwd -P )
  else
    local dir
    dir="$( cd "$(dirname "$p")" && pwd -P )"
    echo "$dir/$(basename "$p")"
  fi
}

ensure_symlink() {
  local link="$1" src="$2"
  local link_short="${link/#$HOME/~}"

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    echo "    skip (source missing): $src"
    return 0
  fi

  if [[ -L "$link" ]]; then
    local link_target src_target
    link_target="$(canonical_path "$link" 2>/dev/null || true)"
    src_target="$(canonical_path "$src" 2>/dev/null || true)"
    if [[ -n "$link_target" && "$link_target" == "$src_target" ]]; then
      echo "    ok: $link_short"
      return 0
    fi
    echo "    warn: $link_short → $(readlink "$link")  (expected target: $src_target). Not touching."
    return 0
  fi

  if [[ -e "$link" ]]; then
    echo "    warn: $link_short exists but is not a symlink. Not touching."
    return 0
  fi

  if (( DRY_RUN )); then
    echo "    would add: $link_short → $src"
  else
    ln -s "$src" "$link"
    echo "    added: $link_short → $src"
  fi
}

surface_orphans() {
  local target="$1"
  echo "  scanning for orphans in $target …"
  shopt -s nullglob
  for entry in "$target"/*; do
    [[ -L "$entry" ]] || continue
    local name; name="$(basename "$entry")"
    local actual; actual="$(readlink "$entry")"
    # Only flag entries pointing into our repo
    [[ "$actual" == "$REPO_ROOT"/* ]] || continue
    # Did we expect this name?
    local expected=0
    for s in "${REGULAR_SKILLS[@]}"; do [[ "$s" == "$name" ]] && expected=1 && break; done
    if (( ! expected )); then
      for entry2 in "${NESTED_SKILLS[@]}"; do
        local mapped="${entry2#*:}"
        [[ "$mapped" == "$name" ]] && expected=1 && break
      done
    fi
    if (( ! expected )); then
      echo "    orphan: $name → $actual (no longer declared; consider removing)"
    fi
  done
  shopt -u nullglob
}

main() {
  echo "lossless-skills repo: $REPO_ROOT"
  echo "regular skills (${#REGULAR_SKILLS[@]}): ${REGULAR_SKILLS[*]:-(none)}"
  echo "nested skills (${#NESTED_SKILLS[@]}): ${NESTED_SKILLS[*]:-(none)}"
  if (( DRY_RUN )); then echo "(dry-run mode — no changes will be made)"; fi
  echo

  for target in "${TARGETS[@]}"; do
    if [[ ! -d "$target" ]]; then
      echo "skipping target (does not exist): $target"
      continue
    fi
    echo "syncing → $target"

    for name in "${REGULAR_SKILLS[@]}"; do
      ensure_symlink "$target/$name" "$REPO_ROOT/$name"
    done

    for entry in "${NESTED_SKILLS[@]}"; do
      local src_rel="${entry%:*}"
      local name="${entry#*:}"
      ensure_symlink "$target/$name" "$REPO_ROOT/$src_rel"
    done

    surface_orphans "$target"
    echo
  done

  echo "done."
}

main "$@"
