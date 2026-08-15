# Frontmatter Spec for `context-v/` Documents

> **In practice, frontmatter is scattered.** Some files are richly tagged with status, supersedes, related, aliases. Others have only `title` and `date_created`. Both are fine. This document describes the *aspirational* baseline for new files — not a validator's checklist.

Most Markdown files under `context-v/` start with YAML frontmatter delimited by `---` lines. Be generous reading; be thoughtful writing.

## Property names: always `snake_case`

**All frontmatter property names in `context-v/` are `snake_case`.** This is not a stylistic preference — **Obsidian's frontmatter rendering and property indexing enforce it**, and most Lossless `context-v/` directories are symlinked into Obsidian vaults. camelCase and kebab-case keys break Obsidian's property panel and graph indexing.

- ✅ `date_created`, `augmented_with`, `semantic_version`, `superseded_by`, `implements_spec`, `related_blueprint`
- ❌ `dateCreated`, `augmented-with`, `SemanticVersion`, `supersededBy`

The rule applies to **keys only.** Values are governed separately:

- `tags` values → **Train-Case** (e.g., `Markdown-Rendering`)
- `status` values → **Train-Case** (e.g., `In-Discussion`, `Signed-Off`) — see the `status` row below
- `authors`, `augmented_with` values → free-form human-readable strings
- Dates → `YYYY-MM-DD`

When introducing a new property anywhere in the tree (in a doc, a template, a tool, a script): name the key in `snake_case`, no exceptions. When you encounter an existing file with a non-`snake_case` key, surface it to the user rather than silently renaming — some sites' build tooling or content collections may be reading the field by its current name.

## Canonical example

```yaml
---
title: "Maintain an Extended Markdown Render Pipeline"
lede: "Why our markdown pipeline is the asset — and where it's heading next."
date_created: 2026-03-30
date_modified: 2026-05-03
authors:
  - Michael Staton
augmented_with:
  - Pi on Claude Sonnet 4.5
semantic_version: 0.1.2.0
tags:
  - Markdown
  - Rendering
  - Astro
---
```

## Baseline fields (recommended for new files)

| Field | Type | Notes |
|---|---|---|
| `title` | string | Human-readable. Quote it if it contains a colon. Title Case. |
| `lede` *(or `description`)* | string | **A rendering field: the one line under the title on a card, list view, or social preview.** It exists because `title` says *what a thing is* and `description` is always too long and too boring to read on a card — `lede` says *why you'd care*, in a glance. **Optional on any `context-v/` doc-type** — spec, prompt, blueprint, exploration, reminder, issue. Newsroom-style hook that makes a reader want to keep reading. **Keep it subtitle-length: one to (at most) a few sentences, never more than ~3 rendered lines** — it's the single line shown in a list view / preview card / OG snippet before a reader decides to click, so a lede that runs long has stopped being a hook. When the lede wants to grow, that material belongs in a `## Why Care?` (or context) section in the body, not the frontmatter. **`lede` is preferred** over `description` because the word itself signals the job (*grab attention*); both are accepted. Many `context-v/` docs render publicly through Astro Knots sites, so the lede also doubles as the OpenGraph / preview-card / list-view summary. See the `context-vigilance` skill's *Lede length discipline* and the `changelog-conventions` skill for the deeper rationale and concrete examples. |
| `publish` | boolean | **A decision, not a measurement.** `true` if there's real content a reader would get value from; `false` for a stub, a title with nothing under it, an empty placeholder, or a doc whose every section is `[awaits discussion]` / `<!-- developing -->`. **If the key already exists, never flip it** — especially never `false` → `true`. Judge it by *reading*: a stale "Stub" banner over a fully-developed body is `true`; a polished title and lede over twelve placeholder sections is `false`. Word counts get both backwards. |
| `date_created` | YYYY-MM-DD | **Filesystem.** When the bytes appeared. Set once. Never change — and never overwrite an existing value with `stat` (see *Filesystem dates lie* below). Legacy spelling `created:` renames to this, value verbatim. |
| `date_modified` | YYYY-MM-DD | **Filesystem.** Update on every meaningful edit. Obsidian bumps this on mere *open*, so it is not the field a timeline should read — that's `date_authored_current_draft`. Never stamp it with today as a side effect of an automated pass; read it before editing. |
| `date_authored_initial_draft` | YYYY-MM-DD | **Editorial.** When the content was first *set* — real, coherent, not a stub. Not when the file was created empty. Set once. Legacy spelling `date:` renames to this. |
| `date_authored_current_draft` | YYYY-MM-DD | **Editorial.** When the doc last received a **substantive** revision. Never earlier than `initial_draft`; if the best source would be, set them equal. Moves together with `at_semantic_version`. |
| `authors` | list of strings | **Humans only.** Always a list, even with one entry. |
| `augmented_with` | list of strings | AI tools used. Format: `<tool> on <model name version>`. Include whenever an AI agent contributed materially. |
| `at_semantic_version` | string `e.M.m.p` | Four-part. See `versioning.md`. New docs start at `0.0.0.1`. **This is the standard spelling** (~4,140 files). `semantic_version` (~330 files) is a **permanently-accepted alias for the same property and value** — not a legacy form awaiting migration. Write `at_`, read either, and never rewrite an existing file just to change which name it uses. Consumers resolve the field as `at_semantic_version ?? semantic_version`. |
| `tags` | list of strings | **Train-Case** (e.g., `Markdown-Rendering`). At least one tag. |

### Filesystem dates lie — which is why the editorial pair exists

`context-v/` documents constantly evolve, so "when did this last really change?" is the question the directory has to answer. The filesystem cannot answer it:

- **`date_modified` overstates recency.** Obsidian's templater bumps mtime when you merely open a file. A spec untouched in substance for three months can show yesterday's date.
- **`date_created` can overstate age-of-origin.** A machine recovery in this tree reset birthtime on a batch of files to the recovery date. Where frontmatter already records an *earlier* `date_created` than `stat` reports, **the frontmatter is the more accurate record.** Never overwrite it.
- **Deriving a missing `date_created`?** Prefer `date_authored_initial_draft` over filesystem birthtime. A document cannot have been created after its own first draft.

#### Source precedence when a date must be derived

Use the first one that resolves. **`stat` is last, not first.**

1. **An existing frontmatter date** on the same file (`date_authored_initial_draft`, `date_created`, `date_modified`).
2. **A date encoded in the filename** — `2025-11-26_03.md` → `2025-11-26`. Changelog entries always carry this.
3. **A date stated in the document's own body** — release notes often name their ship date.
4. **Git first-commit date:** `git log --diff-filter=A --follow --format=%ad --date=short -- <file> | tail -1`. This is the strongest *derived* source and beats the filesystem outright, because git records when the content actually entered the repo.
5. **Filesystem `stat`** — only when everything above fails, and treat the result as suspect.

**Why `stat` is last.** Whole directories in this tree carry a birthtime from a bulk copy or machine recovery rather than from authorship. Observed cases: a hundred changelog entries spanning Nov 2025 – Mar 2026 all reporting `created=2026-05-06 modified=2026-05-06`, and a set of release-notes files reporting a birthtime of *the day the sweep ran* while git dated them nine months earlier. A uniform birthtime across files of obviously different ages is the tell. When you see it, drop to git.

If an existing file is missing any baseline field, **don't silently add them while doing unrelated edits** — surface the gap to the user first. Frontmatter changes are a separate concern from content changes. (The exception is an operator-directed sweep — see *Validation philosophy* at the bottom.)

## Optional fields

Add as needed; do not invent fields without precedent in the project. Common ones seen in the wild:

| Field | Purpose |
|---|---|
| `status` | **Train-Case display string** (e.g., `Draft`, `In-Review`, `Signed-Off`, `Implementing`, `Shipped`, `Partially-Shipped`, `Deferred`, `Stale`, `Superseded`, `Archived`). Treat as a rendering string for humans, **not a machine enum** — don't switch on these values in code, since spelling and casing drift across files. The Train-Case casing is the signal: "this property exists for display, not for build/render-pipeline branching." Update status as work lands; don't let it rot at `Draft`. Companion fields are required for `Shipped`, `Partially-Shipped`, `Deferred`, and `Superseded` — see `status-discipline.md` for the full lifecycle, companion-field rules, and the `## Remaining work` section convention. Spec-specific progression lives in `developing-a-spec.md`. |
| `date_authored_final_draft` | `YYYY-MM-DD`, or **present-but-empty**. Empty is meaningful: "not final yet." **Do not delete the empty key** — its presence is the signal that finality is being tracked. |
| `date_first_published` | `YYYY-MM-DD`. The ship date, set when `status:` first becomes `Shipped` or `Partially-Shipped`. Never updated after — it anchors when the work first landed. |
| `date_last_updated` | `YYYY-MM-DD`. Any touch, substantive or not. Contrast `date_authored_current_draft`, which moves only on substantive revision. Having both is intentional: one tracks activity, the other tracks meaning. |
| `post_ship_note` | Multiline string. Things learned after `Shipped`. Useful when later work invalidates or sharpens a claim the plan made. See `status-discipline.md`. |
| `deferral_note` | Multiline string. Required when `status: Deferred`. Names the reason and (where known) the expected unblocker. |
| `supersedes` | wikilink or filename of the doc this one replaces |
| `superseded_by` | reverse of above |
| `related` | list of `[[wikilinks]]` to related docs |
| `aliases` | alternate titles for Obsidian linking |

## Avoid disclosing what could be considered sensitive

Most `context-v/` work is publishable and *should* be published — it's how the practice spreads. The goal here is not secrecy. It is a light habit: **write generically about specifics that aren't yours to share.**

### Genericize first; `publish: false` is the fallback

When a document is useful but names something it shouldn't, **the fix is almost always to genericize the sentence, not to hide the document.** A plan about lifting shared navigation into a package is worth publishing; it just doesn't need the client's name in it.

| Instead of | Write |
|---|---|
| "chroma-decks was built before the carve-out" | "the first client site was built before the carve-out" |
| "Humain's three scroll-deck variants" | "one engagement's three scroll-deck variants" |
| "Jane Chen, formerly of Acme, 18% IRR" | "a partner with a prior fund track record" |
| "the round is mostly committed at $12M" | *(cut it — the fact adds nothing to an engineering doc)* |
| a client's 12-dimension rubric reproduced verbatim | "the client's scoring framework has ~12 weighted dimensions" |

### The decision order — the document's job comes first

Never damage a useful internal document to make it publishable. Ask in this order:

1. **Does it do its job just as well genericized?** Almost always yes for engineering docs. Genericize the sentence, keep `publish: true`.
2. **Is it materially better at its job *with* the specifics?** Then **keep the specifics and set `publish: false`.** A plan that names the actual client, deck, and slide is easier for the next agent to act on; a data model whose example rows are real is easier to reason about. That value is real, and it's the whole point of `context-v/` — internal shared memory across the pseudomonorepo tree. Keep it for us.

`publish: false` is **not a demotion.** A large share of the corpus is legitimately internal. The failure mode to avoid is not "too many `false`" — it's a vague document that helps nobody *and* still names a client, having been watered down for a publication that was never going to happen.

So: genericize when it costs nothing, and go internal when it costs something.

### What actually wants genericizing

- **PII.** Named individuals with biography, performance, judgment, or behavior attached. Roles and generic descriptions are fine.
- **A client's trade secrets.** Proprietary frameworks, rubrics, and taxonomies reproduced verbatim; brand tokens and design IP lifted from their production assets.
- **Confidential deal terms.** Raise amounts, round status, valuations, cap-table splits, LP commitments — on identifiable companies.
- **Third-party confidential documents.** Don't reproduce a doc marked Confidential, including its structure or table of contents.
- **Client names**, where naming them adds nothing. Usually it doesn't.

### What is fine — don't over-screen

Being over-cautious makes the practice useless. These are **not** sensitive:

- **Variable and env-var names** (`SESSION_SECRET`, `TURSO_AUTH_TOKEN`). A name is not a secret. Actual values obviously are.
- **Architecture, schemas, file layouts, component contracts, keyboard maps, route tables.** This is ordinary engineering writing.
- **The fact that client work happened**, described generically.
- **Our own conventions, practices, and post-mortems.** Candour about what we got wrong is a feature of this corpus, not a liability.
- **Illustrative figures and placeholder data** that aren't tied to a real party.

### The one reliable tell

The documents that most often need genericizing are the ones *about* handling confidential material — a doc explaining a private-data submodule pattern, or a corpus data model, tends to quote the very filenames and paths it exists to protect. Worth a second look when the title mentions private data, datarooms, substantiation, or auth.
| Not reader-ready | raw session transcript, duplicated half-sentences, trailing "Rewriting the entry now." |

**Borderline resolves to `false`.** Internal-by-default is a recoverable error; publishing a client's scorecard is not.

### Check the repo's own convention first

Before deciding anything, count what the repo already does:

```bash
grep -rh '^publish:' --include='*.md' context-v/ | sort | uniq -c
```

A repo running 47 `false` to 5 `true` has made a decision. Respect it, and treat a `true` there as the exception that needs justifying. Tree-wide the split is roughly 2:1 in favour of `true`, so **there is no safe global default** — you have to look.

## Author conventions

**Strong Lossless preference: `authors` is for humans only.** Even when an AI agent produced most of the prose, the human directing the work is the author. AI tooling is tracked separately under `augmented_with`.

### `authors`

- Use the human's full preferred name (not a handle)
- Always a list, even with one entry
- Order: alphabetical or by contribution — team's call, no hard rule

### `augmented_with`

- The AI tool(s) used. Format: `<tool> on <model name and version>`
- Examples: `Pi on Claude Sonnet 4.5`, `Claude Code on Claude Opus 4`, `Cursor on GPT-5`, `Aider on Claude Sonnet 3.7`
- ul-list form, one entry per tool/model pair
- Include this field whenever an AI agent contributed materially — the more, the more important to disclose
- Avoid generic strings (`"AI Assistant"`, `"ChatGPT"`) — always specify both tool and model
- The point: honesty about augmentation matters more than credit allocation

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

The Lossless team **does not hard-validate** frontmatter (this is itself a reminder). Be lenient about reading existing files; be thoughtful when writing new ones. Files older than current conventions are not bugs.

If a file's frontmatter is genuinely broken (malformed YAML, missing `title`), fix it as a `patch` bump and note the fix in the body or a commit message. Don't auto-migrate property names or styles unless explicitly asked.

**Never delete a key you don't recognize.** The vocabulary here is deliberately broad and unevenly applied — different surfaces read different keys, and an unused key costs nothing to carry. Not knowing what a field does is a reason to leave it alone and ask, never a reason to remove it.

## When a normalization sweep *is* directed

"Don't auto-migrate" governs **incidental** edits — don't rewrite someone's frontmatter as a side effect of unrelated work. It does not forbid an operator explicitly asking for a directory or repo to be brought up to standard. Under such a sweep, these bind:

1. **Additive only.** Add missing keys; rename the legacy spellings (`created:` → `date_created:`, `date:` → `date_authored_initial_draft:`) preserving values verbatim. Change nothing else.
2. **No YAML round-trips.** Serializing frontmatter through a YAML library reorders hand-authored keys and collapses multi-line `lede:` / `authors:` / `post_ship_note:` blocks. Edit the key's line in place; append new keys at the end of the block.
3. **Never touch the body.** The diff should be frontmatter lines and nothing else. A sweep that changes one line of prose is a failed sweep.
4. **`publish` cannot be mechanized.** It requires reading the document — see the baseline table. And an existing value is a decision: never flip it.
5. **Don't stamp `date_modified` with today.** Read it before editing. Adding a frontmatter key is not a substantive edit, and neither is it a reason to move `date_authored_current_draft` or bump `at_semantic_version`.
6. **Edit originals, never rollups.** Collated copies (`context-vigilance-kit/corpus/`, `splash/src/rollup/`) and vendored skill copies (`context-v/agent-skills/`) are derived from source and regenerate. Editing them is work that gets overwritten. Fix the original.
7. **Grep for consumers before a rename lands.** Renaming a key across a few hundred files is easy; noticing what *read* the old key is the actual work. The `date:` → `date_authored_initial_draft` migration silently broke two changelog ingesters — one lifted `date` into a metadata allowlist, the other used it as a temporal anchor.
8. **`agent-skills/` is out of scope.** `SKILL.md` frontmatter is a machine contract — Claude Code parses `name` and `description` to decide whether a skill loads. Extra keys are ignored by the loader and safe to *add*, but they are never reordered around those two, and vendored skill copies are not the source of truth.
