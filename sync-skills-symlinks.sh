#!/usr/bin/env bash
# Sync every Lossless skill in the tree into ~/.claude/skills so Claude Code
# discovers it.
#
# Why this exists: Claude Code discovers skills one level deep only
# (~/.claude/skills/<name>/SKILL.md). A symlink that points at a whole PARENT
# dir does NOT expose the skills nested inside it — each skill must be its OWN
# direct child of ~/.claude/skills. New skills silently fail to load until an
# individual symlink is created. This script makes that idempotent.
#
# Two source layouts are accepted, ANYWHERE in the tree (mid-migration state):
#     <repo>/context-v/skills/<name>/SKILL.md          (legacy)
#     <repo>/context-v/agent-skills/<name>/SKILL.md    (current — being moved to)
# When the SAME skill name exists in both, the agent-skills copy WINS, and an
# existing link that still points at the legacy skills/ copy is REPOINTED to it
# (that's the migration). Dangling links are healed the same way.
#
# Safe to re-run. Never clobbers a real (non-symlink) entry in ~/.claude/skills,
# and never repoints a symlink that points somewhere outside this migration
# (i.e. an agent-skills link is never dragged back to a skills/ copy).
set -euo pipefail

# This script lives at <mono-root>/context-v/skills/ ; the tree to scan is the
# monorepo root two levels up.
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONO_ROOT="$(cd "$SELF_DIR/../.." && pwd)"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

# Emit skill dirs (dirs with a top-level SKILL.md) found directly under any
# context-v/agent-skills or context-v/skills in the tree. agent-skills is
# emitted FIRST so it takes precedence for duplicate names. node_modules/.git
# are pruned for speed; the path filter keeps us to real skill locations.
list_candidates() {
  local flavor
  for flavor in agent-skills skills; do
    find "$MONO_ROOT" \
        -type d \( -name node_modules -o -name .git \) -prune -o \
        -type f -name SKILL.md -print 2>/dev/null \
      | grep -E "/context-v/${flavor}/[^/]+/SKILL.md$" || true
  done
}

linked=0
repointed=0
skipped=0
while IFS= read -r skill_md; do
  [ -n "$skill_md" ] || continue
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  target="$DEST/$name"

  if [ -L "$target" ]; then
    cur="$(readlink "$target")"
    if [ "$cur" = "$dir" ]; then
      skipped=$((skipped + 1)); continue          # already correct
    fi
    # Repoint ONLY to support the skills/ -> agent-skills/ migration:
    #   - the existing link dangles (its target is gone), OR
    #   - it points at a legacy context-v/skills/ copy (and, because
    #     agent-skills is scanned first, `dir` here is the agent-skills winner).
    if [ ! -e "$target" ] || printf '%s' "$cur" | grep -q '/context-v/skills/'; then
      ln -sfn "$dir" "$target"
      echo "repointed $name -> $dir"
      repointed=$((repointed + 1)); continue
    fi
    # Points at some other live location (e.g. already the agent-skills copy
    # while we're now looking at the legacy duplicate) — leave it alone.
    skipped=$((skipped + 1)); continue
  fi
  if [ -e "$target" ]; then
    echo "SKIP  $name — a non-symlink already exists at $target" >&2
    skipped=$((skipped + 1)); continue
  fi
  ln -s "$dir" "$target"
  echo "linked $name -> $dir"
  linked=$((linked + 1))
done < <(list_candidates)

echo "done: $linked new, $repointed repointed, $skipped already present/skipped"
