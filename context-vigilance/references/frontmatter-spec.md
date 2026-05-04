# Frontmatter Spec for `context-v/` Documents

Every Markdown file under any `context-v/` directory MUST start with YAML frontmatter delimited by `---` lines.

## Canonical example

```yaml
---
title: "Maintain an Extended Markdown Render Pipeline"
date_created: 2026-03-30
date_modified: 2026-05-03
authors:
  - Michael Staton
  - Claude Sonnet 4.5
semantic_version: 0.1.2.0
tags:
  - Markdown
  - Rendering
  - Astro
---
```

## Required fields

| Field | Type | Notes |
|---|---|---|
| `title` | string | Human-readable. Quote it if it contains a colon. Title Case. |
| `date_created` | YYYY-MM-DD | Set once on creation. Never change. |
| `date_modified` | YYYY-MM-DD | Update on every meaningful edit. |
| `authors` | list of strings | Always a list, even with one entry. |
| `semantic_version` | string `e.M.m.p` | Four-part. See `versioning.md`. New docs start at `0.0.0.1`. |
| `tags` | list of strings | **Train-Case** (e.g., `Markdown-Rendering`). At least one tag. |

## Optional fields

Add as needed; do not invent fields without precedent in the project. Common ones seen in the wild:

| Field | Purpose |
|---|---|
| `status` | e.g., `draft`, `proposed`, `accepted`, `superseded` |
| `supersedes` | wikilink or filename of the doc this one replaces |
| `superseded_by` | reverse of above |
| `related` | list of `[[wikilinks]]` to related docs |
| `aliases` | alternate titles for Obsidian linking |

## Author conventions

- Use the human's full preferred name (not a handle)
- For AI co-authors, name the model: `Claude Sonnet 4.5`, `GPT-5`, `Gemini 2.5 Pro`. Avoid generic "AI Assistant".
- Order: humans first, AI last
- Add yourself when you contributed substantial content (more than a typo fix)

## Tag conventions

- **Train-Case**: `Markdown-Rendering`, not `markdown-rendering`, `MarkdownRendering`, or `markdown_rendering`
- This is an Obsidian convention — Obsidian treats `#Markdown-Rendering` as a single tag, while underscores and other separators behave inconsistently
- Single-word tags are still capitalized: `Spec`, `Astro`, `Markdown`
- Singular over plural when ambiguous: `Spec`, not `Specs`
- Reuse existing tags in the project before inventing new ones — survey with:
  ```bash
  grep -rhA20 '^---' context-v/ | grep -E '^  - [A-Z]' | sort -u
  ```

## Date format

Always `YYYY-MM-DD`. No timestamps. No timezones. If you genuinely need a timestamp, use a separate field like `last_run: 2026-05-03T14:32:00Z` rather than overloading the date fields.

## Title quoting

Quote when the title contains:
- a colon (`:`)
- a leading number (`2026 Plan`)
- special YAML characters (`#`, `&`, `*`, `!`, `|`, `>`, `'`, `"`, `%`, `@`, `` ` ``)

When in doubt, double-quote.

## Validation philosophy

The Lossless team **does not hard-validate** frontmatter (this is itself a reminder). Be lenient about reading existing files; be careful when writing new ones.
