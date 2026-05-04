---
name: changelog-conventions
description: How The Lossless Group writes and structures changelog/ entries across all repos (projects, true monorepos, pseudomonorepos). Use whenever shipping or pushing a coherent chunk of work, when scaffolding a new repo's changelog/ directory, when authoring a product release message, when the user says "log this", "write a changelog", or "ship note", or when reviewing a changelog/ file. Encodes the strict frontmatter (publish, lede, ISO dates), filename pattern, "it exists" priority, and the show-don't-enforce ethos.
---

# Changelog Conventions

> **The single most important rule: it exists.** Everything else is refinement.

Every Lossless repo at every level (project, true monorepo, pseudomonorepo) should have a `changelog/` directory at the root, parallel to `context-v/`. Entries are written when meaningful chunks of work ship — or at least when they push.

## When to use this skill

- You just shipped or pushed a coherent chunk of work
- The user says "log this", "write a changelog", "ship note", "publish update"
- Scaffolding a new repo's `changelog/` directory
- Reviewing or updating an existing changelog entry
- Authoring a product release message (see `releases/` subfolder below)

## When to write an entry

**Yes:**
- A coherent chunk of work shipped (deployed, merged, released)
- Or at least pushed to a remote where someone else might land on it
- A new convention, blueprint, or tool became available
- Multiple smaller changes have accumulated into something worth announcing

**Not necessarily:**
- Every commit (most aren't worth a changelog)
- Typo fixes, minor refactors, work-in-progress

> **Future direction:** the team is open to a "tweet-style" subset — short, frequent micro-changelogs for the in-between work that doesn't merit a full entry. Not implemented yet; flagged as a candidate.

## Where it lives

```
<any-repo>/
├── context-v/        # living documentation
└── changelog/        # ← this skill governs this directory
    ├── YYYY-MM-DD_NN.md       # entries
    ├── YYYY-MM-DD_NN.md
    └── releases/              # for product-style projects only
        ├── v1.0.0.md
        └── v1.1.0.md
```

- **Filename:** `YYYY-MM-DD_NN.md` where `NN` is a daily counter (`01`, `02`, ...). ISO date with dashes — always.
- **`releases/` subfolder:** only for product-style projects with versioned releases. Release messages live there as `<version>.md` (or whatever versioning scheme the product uses). Standard changelog entries live in `changelog/` proper.

## Mandatory frontmatter (last few months and forward)

These six fields are **hardcoded** for new entries — non-negotiable. Older entries may have less or more; respect them.

```yaml
---
date_created: YYYY-MM-DD       # ISO with dashes. Set on creation.
date_modified: YYYY-MM-DD      # ISO. Updated on every edit. Obsidian template often manages this; sometimes meaningless updates happen, that's accepted.
title: "Human-readable title"
lede: "Subtitle that grabs attention — used where the point is to make the reader keep reading"
publish: true                  # Obsidian publisher convention. STRICTLY ENFORCED. Do not deviate.
authors:                       # Always a list. Preferred ul format (not [a, b] inline). One item per line.
  - Firstname Lastname
  - Claude Sonnet 4.5
---
```

### Notes on the fields

- **`publish: true`** is set by Obsidian publisher and is strictly enforced there. Do not toggle it off without understanding the publishing implications.
- **`lede`** is intentional — not "subtitle" or "description". The word signals: *write something that grabs attention*. The reader should want to keep reading.
- **`authors`** preferred form is the YAML list (one author per line), not inline `[a, b]`. Add yourself when you wrote substantial content. Use the model name (e.g., `Claude Sonnet 4.5`).
- **ISO dates with dashes for everything** — both dates and timestamps. Never `2026/05/04` or `May 4, 2026`.

See `references/frontmatter-spec.md` for edge cases and optional fields.

## Public by default

Changelogs are written **for the public web**. Assume:

- A reader with no prior context lands on this entry from a Google search
- The lede has to do its job in two seconds
- Internal jargon needs a one-sentence translation or a `[[wikilink]]`
- Embarrassments and bugs can be discussed honestly — that's part of building in public

A long-running goal: aggregate all changelogs across all Lossless repos via the GitHub API into a "Lossless Changelog" umbrella view. Write entries that would render well in that aggregated context.

## Show, don't enforce

Conventions here are evolving. People are encouraged to experiment. The way to spread the convention is to **show it working** — not to police existing entries.

- ✅ Write your own entries to the convention
- ✅ Nudge a contributor toward the format when they ask
- ❌ Go around "fixing" old entries to match current frontmatter
- ❌ Reject a PR for using `description` instead of `lede`

The aspiration is consistency. The reality is generative-first. Respect that.

## Reference / submodule projects

**Don't expect them to have proper changelogs or frontmatter.** Many submodules in our pseudomonorepos are external projects we're studying or vendoring. They are out of scope for our conventions. When working *on* an external project's content, follow that project's conventions; when working in *our* code, follow these.

## Templates

When creating a new entry, start from `templates/entry.md` (standard changelog) or `templates/release.md` (product release).

## Composition with other skills

- **`pseudomonorepos`** — the `lossless-loop` Phase 2 (Progress) and Phase 4 (Publish) both write to changelogs. Project changelog = Progress. Parent pseudomonorepo changelog = Publish.
- **`context-vigilance`** — changelogs sit alongside `context-v/`, not inside it (aspirationally). Some legacy projects nest them; respect what's there.
- **`astro-knots`** — changelog content gets aggregated and rendered on Astro Knots sites. Write with that publication path in mind.

## Typical flow

1. **You just shipped something.** Pause before opening a new task.
2. **Decide:** is this a coherent chunk worth logging? (Apply the "Yes/Not necessarily" guide above.)
3. **Find the changelog/** at the repo root. Create it if missing.
4. **Filename:** `YYYY-MM-DD_NN.md`. Increment `NN` if today already has entries.
5. **Copy** `templates/entry.md`. Fill in frontmatter (all 6 fields, ISO dates, `publish: true`).
6. **Write the lede first.** If you can't write a compelling lede, the work might not warrant an entry.
7. **Body:** what shipped, why it matters, what it enables next. Link related work via `[[wikilinks]]`.
8. **Commit and push.** This entry is part of the work, not separate from it.

## See also

- `references/frontmatter-spec.md` — full frontmatter rules, optional fields
- `references/filename-conventions.md` — daily counter, releases subfolder
- `references/what-counts.md` — heuristics for when an entry is warranted
- `templates/entry.md`, `templates/release.md` — scaffolds
- `pseudomonorepos/references/lifecycle-workflow.md` — how changelogs fit the 5-phase loop
