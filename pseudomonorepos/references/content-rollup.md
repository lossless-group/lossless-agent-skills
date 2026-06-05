# Content Roll-Up Across the Tree

> **Intent.** A pseudomonorepo's splash, site, or gallery should surface not only its own `changelog/` and `context-v/`, but also those of its submodules — rolled up into one feed at the parent level. So the splash at `content-farm.lossless.group` shows ship notes from cite-wide, image-gin, perplexed, and the rest of the plugin family alongside content-farm's own; the splash at `ai-labs.lossless.group` shows entries from context-vigilance-kit, memopop-ai, dididecks-ai, and augment-it alongside ai-labs's own.

**Status:** implemented in two variants. Two production reference implementations as of 2026-05-17 — `content-farm/splash` (GitHub Content API variant) and `ai-labs/splash` (local-filesystem variant). The mechanism diverges based on whether the child repos are always-checked-out locally or not.

## What rolls up

- **`changelog/`** — every submodule's published ship notes get aggregated into the parent's changelog list. Sorted by date across the merged set, with provenance on each card (which submodule it came from). **Subdirectories of `changelog/` are traversed recursively** — so `<plugin>/changelog/releases/<version>.md` files surface in the same feed at canonical URLs like `<splash>/changelog/<plugin>/releases/<version>`.
- **`context-v/`** — same pattern. Specs, blueprints, plans, and chores from submodules show up alongside the parent's own. Grouped by section (specs together, blueprints together) rather than by submodule, with the originating repo as a meta tag on each entry.

## Two variants — pick by lookup-pattern

| Variant | When to use | Reference impl |
|---|---|---|
| **GitHub Content API** (`scripts/rollup-sync.ts` calling `src/loaders/rollupFetch.ts`) | Children are git submodules that may NOT be locally checked out (e.g., contributors clone the parent without `--recurse-submodules`). The script hits `/repos/{owner}/{repo}/contents/{path}?ref={branch}` for each submodule registered in `.gitmodules`, walks recursively, and writes the results to `splash/src/rollup/`. | `content-farm/splash` (8 plugin submodules, several not always present locally) |
| **Local filesystem** (`scripts/rollup-sync.ts` reading directly from sibling paths) | Children are always-checked-out workspace siblings (a true monorepo flavor, or a pseudomonorepo where the parent's `pnpm install` pulls children in via workspaces). The script reads each child's `changelog/` and `context-v/` directly from the filesystem. Also handles pseudomonorepo *children* that have their own `apps/<name>/` substructure — auto-discovers any `apps/*/changelog/` or `apps/*/context-v/` and rolls them up with `<child>/<app>` slugs. | `ai-labs/splash` (4 children, two of which have apps/ sub-children) |

Both variants produce the same `splash/src/rollup/` output shape, so the content-collection setup and page templates are identical downstream.

## Architecture — deliberate-sync, not live-fetch

**Run `pnpm rollup:sync` as an explicit step; subsequent `pnpm build` and `pnpm dev` runs read from local files.** This was the conscious move away from a prior design where Astro's content-collection loader hit the API at build time. That design made every build run ~60 API calls, required `GITHUB_TOKEN` plumbing in CI, and produced flaky builds whenever GitHub rate-limited or returned 5xx.

Current model:

```
pnpm rollup:sync   ← deliberate; fetches + writes splash/src/rollup/
pnpm build         ← pure file IO; no API calls; reproducible
pnpm dev           ← same; instant rebuilds
```

Run `pnpm rollup:sync` when:
- You bumped a submodule pointer and want the splash to reflect the new content
- A child shipped a new changelog entry (or new release narrative under `changelog/releases/`)
- Periodically (e.g. weekly) to catch upstream drift
- Right before pushing to the `gh-pages`-deploying branch

The rollup output lives under version control at `splash/src/rollup/` (committed alongside the rest of the splash). That way the splash repo always contains everything needed to build — no API dependency in CI.

## Output layout

```
splash/src/rollup/
├── README.md                                          (auto-written marker explaining the dir)
├── changelog/
│   ├── cite-wide/
│   │   ├── 2026-05-01_01.md                          (per-day entry; provenance frontmatter added)
│   │   ├── 2026-05-02_02.md
│   │   └── releases/
│   │       └── 0.2.0.md                              (release narrative; subdir preserved)
│   ├── image-gin/
│   │   ├── 2026-05-09_01.md
│   │   └── releases/
│   │       ├── 0.1.1.md
│   │       └── 0.2.2.md
│   └── perplexed/
│       ├── 2026-04-30_01.md
│       └── releases/
│           └── 0.1.1.md
└── context-v/
    ├── cite-wide/
    │   ├── blueprints/
    │   ├── reminders/
    │   └── specs/
    └── …
```

Every rolled-up file gets injected provenance frontmatter (`from`, `from_path`, optional `legacy: true`) plus a one-line HTML comment at the top warning that the file is synced and should be edited at the source:

```markdown
<!-- Rolled up from cite-wide/changelog/releases/0.2.0.md. Edit at the source, not here. Re-run `pnpm rollup:sync` to refresh. -->
```

## Mechanism — GitHub Content API variant

For each submodule registered in `.gitmodules`:

1. Parse the `url =` line to derive `{owner}/{repo}`.
2. Use the `branch =` line as `ref` (defaults to `development` per the branch-alignment convention, but each submodule's actual default branch is respected).
3. Recursively walk `/contents/changelog/` and `/contents/context-v/` — handle 404 quietly when a submodule lacks the directory.
4. For each file: fetch the raw content, parse frontmatter, write to `splash/src/rollup/<collection>/<child>/<path>.md`.
5. Optional `remoteFallbackPaths` config picks up legacy locations (e.g., older repos that still have `context-v/changelogs/` rather than the new `changelog/` location — those entries get `legacy: true` in their frontmatter so pages can label them).

Auth:
- **CI:** `GITHUB_TOKEN` from the workflow context. Already authorized for the calling repo's submodules within the same org.
- **Local dev:** personal access token in `splash/.env` as `GITHUB_API_TOKEN` (or `GITHUB_TOKEN`).
- **Anonymous fallback:** allowed but rate-limited (60 req/hr). One full sync uses ~60-70 calls, so authenticated mode is recommended.

## Mechanism — local-filesystem variant

For each child listed in the script's `CHILDREN` array:

1. Read child's `changelog/` and `context-v/` directly from sibling-directory paths.
2. If the child has an `apps/` directory, auto-discover any `apps/<name>/changelog/` or `apps/<name>/context-v/` and roll those up as `<child>/<name>` sub-children.
3. Walk recursively; write to `splash/src/rollup/<collection>/<child>/<path>.md` (or `splash/src/rollup/<collection>/<child>/<app>/<path>.md` for the apps case).

No auth, no rate limits, no network. Simpler and faster, but only viable when the child working trees are always present.

## Content-collection wiring

The splash's `src/content.config.ts` defines a custom **union loader** that merges:

1. The parent's own `../changelog/` and `../context-v/` (read directly from the filesystem, no sync needed for parent-authored content)
2. The rolled-up children at `src/rollup/<collection>/`

Both go through the same Zod schema with **lenient preprocessors** (`lenientString`, `lenientStringArray`, `lenientDate`, `lenientNumber`, `lenientBoolean`) so author-written frontmatter never throws — empty strings, `~`, `TBD`, malformed dates all coerce to `undefined` rather than failing the build. The whole point of the rollup is to surface what people actually wrote; the schema bends to fit.

Loaded entries carry a `from:` field. Pages filter and group on it — `/changelog/?from=cite-wide` shows only that plugin's entries; the index sorts by date across the union.

## Provenance and identity

Every rolled-up entry carries **which submodule it came from** in its rendered metadata. Cards on the changelog index look like:

```
[ cite-wide ]      2026-05-17   Cite-Wide 0.2.0 — From Citation Formatter to LLM-Era Research Tool
[ image-gin ]      2026-05-17   Image Gin 0.2.2 — Every Image Asks Where It Goes
[ perplexed ]      2026-05-17   Perplexed 0.1.1 — From Research Modal to Per-Directory Content Workflow
[ content-farm ]   2026-05-04   ship(splash): launch the GitHub Pages splash
```

The submodule's `slug` becomes a routable filter — `/changelog?from=image-gin` shows only that plugin's entries. Same for `/context-v?from=cite-wide`.

## Releases as a first-class subfolder

Per the `changelog-conventions` skill, version-anchored release narratives go under `<repo>/changelog/releases/<version>.md`. The rollup script walks `changelog/` recursively, so these land at `splash/src/rollup/changelog/<plugin>/releases/<version>.md` and render at URLs like `<splash>/changelog/<plugin>/releases/<version>`.

The splash's changelog index renders release narratives mixed in with per-day entries, sorted by date. They visually differentiate by their `category: Release` frontmatter and `Release-Narrative` tag — but they don't get their own page unless the splash explicitly carves one out. **If you want a dedicated `/releases` view**, add a new `pages/releases/index.astro` that filters `getCollection('changelog')` by `data.category === 'Release'`. The data is already there; only the page layer is missing.

## Failure modes (degrade gracefully)

- **Submodule missing `changelog/` or `context-v/`** → skip silently. Don't error the rollup.
- **Rate limit hit** → script logs the failure for that submodule and continues; the existing `src/rollup/` files stay (so the splash keeps building with the prior content). Authenticate before re-running.
- **Network failure during sync** → fail loud at the sync step; never write a partial `src/rollup/` over a known-good one.
- **Frontmatter mismatch** (older entries with non-standard fields) → use lenient zod preprocessors. Skip-with-warning beats hard-failure.

## Build-time vs runtime

**Build-time, static, baked into `dist/`.** The splash is a static Astro site. Readers get instant page loads, no client-side API calls. Re-run `pnpm rollup:sync && pnpm build` to refresh.

For automated refresh: a scheduled GitHub Action (`cron: '0 */6 * * *'`) re-running the rollup + build + deploy is simpler than client-side fetching. Both reference splashes deploy via GitHub Pages on push to `main`, so the cron path is "scheduled workflow runs `pnpm rollup:sync`, commits the changed `src/rollup/`, pushes — push triggers the existing Pages deploy."

## Cross-tree implication

This pattern composes up the tree. A pseudomonorepo's splash rolls up its children. The *parent* pseudomonorepo's splash (when it has one) rolls up *its* children — including the entire content-farm subtree. Each level only knows how to query one level down; recursion happens implicitly because every level uses the same loader.

This is also what eventually feeds the long-stated "Lossless Changelog" umbrella view at the org level — see the `changelog-conventions` skill.

## See also

- `splash/scripts/rollup-sync.ts` in both reference impls — the variants
- `splash/src/loaders/rollupFetch.ts` (Content API variant) — the recursive walker
- `splash/src/content.config.ts` — union loader + lenient schemas
- `splash/src/rollup/README.md` — auto-written marker doc, last-sync stamp
- `pseudomonorepos/references/branch-alignment.md` — how the `branch =` field in `.gitmodules` is chosen
- `changelog-conventions` skill — what gets rolled up, and the `releases/` subfolder convention this respects
- `maintain-splash-pages` skill — the broader splash discipline this fits inside
