# Content Roll-Up Across the Tree

> **Intent.** A pseudomonorepo's splash, site, or gallery should surface not only its own `changelog/` and `context-v/`, but also those of its submodules — rolled up into one feed at the parent level.

**Status:** aspirational. The first splash (`memopop-site`) and the second (`content-farm/splash`) both render local-only content as of writing. Roll-up is the documented next step, not yet implemented.

## What rolls up

- **`changelog/`** — every submodule's published ship notes get aggregated into the parent's changelog list. Sorted by date across the merged set, with provenance on each card (which submodule it came from).
- **`context-v/`** — same pattern. Specs, blueprints, plans, and chores from submodules show up alongside the parent's own. Grouped by type (specs together, blueprints together) rather than by submodule, with the originating repo as a meta tag on each entry.

## Mechanism — preferred

**GitHub Content API, authenticated, at build time.**

```
GET /repos/{owner}/{repo}/contents/{path}?ref={branch}
```

For each submodule registered in `.gitmodules`:

1. Parse the `url =` line to derive `{owner}/{repo}`.
2. Use the `branch =` line as `ref` (defaults to `development` per the branch-alignment convention).
3. Hit `/contents/changelog/` and `/contents/context-v/` — handle 404 quietly when a submodule lacks the directory.
4. For each file: fetch the content (or use the `download_url`), parse frontmatter, merge into the parent's collection.

Why this over `git submodule update --remote && glob('**/changelog/*.md')`:

- Submodule clones in CI are heavy and brittle; the Content API is cheap and rate-limited generously for authenticated requests (5000/hr).
- The parent's working tree stays small — no need to vendor children's working trees just to render their changelogs.
- The branch tracked by the submodule pointer can lag behind what's actually published; the Content API hits the *current* state of the child's `branch`.

## Auth

- **CI:** `GITHUB_TOKEN` from the workflow context. Already authorized for the calling repo's submodules within the same org.
- **Local dev:** a personal access token in `.env` (e.g., `GITHUB_API_TOKEN`). Document the variable in the site's README so contributors can set it.
- **Anonymous fallback:** allowed but rate-limited (60 req/hr). Useful for initial scaffolds before secrets are wired in.

Never commit tokens. Never log the token value. Standard practice.

## Provenance and identity

Every rolled-up entry should carry **which submodule it came from** in its rendered metadata:

```
[ image-gin ]  2026-05-04   improve(modals): bring Recraft + Ideogram modals to UX parity
[ cite-wide ]  2026-05-02   feat(citations): wide modal v2
[ content-farm ]  2026-05-04  ship(splash): launch the GitHub Pages splash
```

The submodule's `id`/`slug` becomes a routable filter — `/changelog?from=image-gin` shows only that plugin's entries. Same for `/context-v?from=cite-wide`.

## Failure modes (degrade gracefully)

- **Submodule missing `changelog/` or `context-v/`** → skip silently. Don't error the build.
- **Rate limit hit** → cache aggressively (per build, ideally per day), fall back to last cached set.
- **Network failure during dev** → render local-only content with a banner: "submodule content unavailable, showing local only."
- **Frontmatter mismatch** (older entries with non-standard fields) → use lenient zod preprocessors. Skip-with-warning beats hard-failure.

## Build-time vs runtime

**Build-time, static, baked into `dist/`.** The splash is a static Astro site. Roll-up should produce the same static HTML on every build; readers get instant page loads, no client-side API calls. Re-run the build to refresh.

If a future iteration wants live updates, a scheduled GitHub Action (`cron: '0 */6 * * *'`) re-running the build is simpler than client-side fetching.

## Where it lives in code

A custom Astro content collection loader, not the default `glob` loader:

```ts
// splash/src/content.config.ts (sketch)
import { defineCollection } from 'astro:content';
import { rollupLoader } from './loaders/rollup';

const changelog = defineCollection({
  loader: rollupLoader({
    local: '../changelog',
    submodules: '../.gitmodules',     // parse and follow
    contentPath: 'changelog',          // relative path inside each child repo
  }),
  schema: /* ... */,
});
```

The loader's responsibilities:

1. Glob the local directory.
2. Parse `.gitmodules`, iterate each submodule.
3. Hit the GitHub Content API for each child's `contentPath`.
4. Merge results, normalize frontmatter, return as a single collection.
5. Cache by submodule + commit SHA so unchanged submodules don't re-fetch on every build.

## Cross-tree implication

This pattern composes up the tree. A pseudomonorepo's splash rolls up its children. The *parent* pseudomonorepo's splash (when it has one) rolls up *its* children — including the entire content-farm subtree. Each level only knows how to query one level down; the recursion happens implicitly because every level uses the same loader.

This is also what eventually feeds the long-stated "Lossless Changelog" umbrella view at the org level — see the `changelog-conventions` skill.

## Logging the gap

Until roll-up is implemented for a given splash, log it as Phase 2 work in the splash's spec under `context-v/specs/`. Don't pretend the splash is "done" — it's done with Phase 1, with a known follow-up. The pseudomonorepo skill's drift policy applies: surface the gap, don't let it lurk.
