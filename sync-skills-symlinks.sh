#!/usr/bin/env bash
# Sync every skill in this dir into ~/.claude/skills so Claude Code discovers it.
#
# Why this exists: Claude Code discovers skills one level deep only
# (~/.claude/skills/<name>/SKILL.md). The `lossless-skills` symlink that points
# at this whole directory does NOT expose the skills nested inside it — each
# skill must be its OWN direct child of ~/.claude/skills. So every skill here
# needs an individual symlink, and new skills silently fail to load until one
# is created. This script makes that idempotent: run it after adding a skill.
#
# Safe to re-run. Only touches symlinks it would itself create; never deletes
# real dirs and never clobbers a non-symlink entry in ~/.claude/skills.
set -euo pipefail

SKILLS_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

linked=0
skipped=0
# A "skill" is any dir (at any depth here) with a top-level SKILL.md.
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  target="$DEST/$name"

  if [ -L "$target" ]; then
    skipped=$((skipped + 1)); continue          # already linked
  fi
  if [ -e "$target" ]; then
    echo "SKIP  $name — a non-symlink already exists at $target" >&2
    skipped=$((skipped + 1)); continue
  fi
  ln -s "$dir" "$target"
  echo "linked $name -> $dir"
  linked=$((linked + 1))
done < <(find "$SKILLS_SRC" -maxdepth 4 -name SKILL.md)

echo "done: $linked new, $skipped already present/skipped"
