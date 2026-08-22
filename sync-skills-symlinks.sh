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
# Two source layouts are accepted, ANYWHERE in the tree:
#     <repo>/context-v/agent-skills/<name>/SKILL.md    (canonical)
#     <repo>/context-v/skills/<name>/SKILL.md          (legacy)
#
# PRECEDENCE — when the same skill name exists in more than one place:
#   **The most recently updated folder wins.** "Updated" is the newest mtime of
#   any file inside the skill dir, so a change to references/ counts, not just
#   SKILL.md. The practice is to edit at the relevant parent pseudomonorepo and
#   propagate down, but that isn't always done — so recency, not location, is
#   what decides.
#
#   Ties break deterministically: agent-skills/ over legacy skills/, then the
#   anchor monorepo's own copy over a child repo's.
#
#   CAVEAT: git sets mtime at checkout time, not commit time. A fresh clone or a
#   `git submodule update` rewrites mtimes wholesale, so on a newly-cloned
#   machine recency reflects checkout order, not authorship. Re-run the script
#   after editing a skill and it self-corrects; just don't trust it to be
#   meaningful immediately after a mass checkout.
#
# Safe to re-run. Never clobbers a real (non-symlink) entry in ~/.claude/skills.
# Pass --dry-run to see what would change without touching anything.
set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# This script lives at <mono-root>/context-v/agent-skills/ ; the tree to scan is
# the monorepo root two levels up. (The anchor's own skills dir was renamed from
# skills/ to agent-skills/ on 2026-08-22; MONO_ROOT is still ../.. either way.)
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONO_ROOT="$(cd "$SELF_DIR/../.." && pwd)"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"

# Newest mtime of any file in a directory. BSD stat (macOS) and GNU stat differ;
# support both. Prints 0 if the dir is somehow empty.
dir_mtime() {
  local d="$1" newest
  newest=$(find "$d" -type f -exec stat -f '%m' {} + 2>/dev/null \
           || find "$d" -type f -exec stat -c '%Y' {} + 2>/dev/null \
           || true)
  printf '%s' "$newest" | sort -rn | head -1 | grep -E '^[0-9]+$' || printf '0'
}

# Emit one row per candidate skill dir:
#   name <TAB> mtime <TAB> flavor_rank <TAB> anchor_rank <TAB> dir
# flavor_rank / anchor_rank are tie-breakers only; mtime is the primary key.
list_candidates() {
  local flavor flavor_rank skill_md dir name anchor_rank
  for flavor in agent-skills skills; do
    [ "$flavor" = "agent-skills" ] && flavor_rank=0 || flavor_rank=1
    while IFS= read -r skill_md; do
      [ -n "$skill_md" ] || continue
      dir="$(dirname "$skill_md")"
      name="$(basename "$dir")"
      case "$dir" in
        "$MONO_ROOT/context-v/$flavor/"*) anchor_rank=0 ;;
        *)                                anchor_rank=1 ;;
      esac
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "$name" "$(dir_mtime "$dir")" "$flavor_rank" "$anchor_rank" "$dir"
    done < <(find "$MONO_ROOT" \
                 -type d \( -name node_modules -o -name .git \) -prune -o \
                 -type f -name SKILL.md -print 2>/dev/null \
               | grep -E "/context-v/${flavor}/[^/]+/SKILL.md$" || true)
  done
}

# Winner per name: newest mtime, then agent-skills, then anchor.
select_winners() {
  sort -t"$(printf '\t')" -k1,1 -k2,2nr -k3,3n -k4,4n \
    | awk -F'\t' '!seen[$1]++ { print $1 "\t" $5 }'
}

linked=0; repointed=0; skipped=0
while IFS=$'\t' read -r name dir; do
  [ -n "$name" ] || continue
  target="$DEST/$name"

  if [ -L "$target" ]; then
    cur="$(readlink "$target")"
    if [ "$cur" = "$dir" ]; then
      skipped=$((skipped + 1)); continue
    fi
    if [ "$DRY_RUN" = 1 ]; then
      echo "would repoint $name"; echo "    from $cur"; echo "      to $dir"
    else
      ln -sfn "$dir" "$target"; echo "repointed $name -> $dir"
    fi
    repointed=$((repointed + 1)); continue
  fi

  if [ -e "$target" ]; then
    echo "SKIP  $name — a non-symlink already exists at $target" >&2
    skipped=$((skipped + 1)); continue
  fi

  if [ "$DRY_RUN" = 1 ]; then
    echo "would link $name -> $dir"
  else
    ln -s "$dir" "$target"; echo "linked $name -> $dir"
  fi
  linked=$((linked + 1))
done < <(list_candidates | select_winners)

if [ "$DRY_RUN" = 1 ]; then
  echo "dry run: $linked would be new, $repointed would be repointed, $skipped already correct"
else
  echo "done: $linked new, $repointed repointed, $skipped already present/skipped"
fi
