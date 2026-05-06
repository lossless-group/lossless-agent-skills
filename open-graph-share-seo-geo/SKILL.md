---
name: open-graph-share-seo-geo
description: How to make a page unfurl reliably in iMessage, WhatsApp, Slack, Discord, LinkedIn, and X — and stay legible to generative engines (GEO). Use when adding or debugging OpenGraph / Twitter Card metadata, picking an OG image format, choosing where to host the image, fixing pages that "won't unfurl", or auditing share previews on a marketing splash, blog post, plugin page, or product page. Encodes the JPEG-over-WebP rule, the ImageKit content-negotiation gotcha, the absolute-URL requirement, the og:image:type-must-match-bytes invariant, and the cache-busting recipe for forcing a re-unfurl.
---

# OpenGraph, Share, SEO & GEO

> Make the link unfurl. Make it fast. Make it match the bytes.

Lossless Group convention for share metadata across all sites (Astro Knots, plugin pages, splash, fundraise decks). Optimized for **iMessage and WhatsApp first** (the channels we share through most), with Slack, Discord, LinkedIn, X, Facebook, and generative engines (Perplexity, ChatGPT, Claude, Gemini) as concentric rings around that.

## When to use this skill

- Adding or auditing `<head>` meta tags on any page that gets shared
- "It's not unfurling in iMessage / WhatsApp / Slack" debugging
- Picking the OG image format (`.webp` vs `.jpg` vs `.png`)
- Deciding where to host the OG image (`/public` vs CDN)
- Building or modifying a `MetaTags`-style component
- Reviewing or shipping a marketing splash, plugin page, blog post, fundraise deck
- Setting up GEO (Generative Engine Optimization) on a content-heavy page

## Hard rules (Why + How to apply)

### 1. Host the OG image on a remote CDN, not `/public`

**Rule:** Default OG image goes on a CDN (ImageKit, Cloudflare Images, S3+CloudFront, Vercel Blob). Do not point `og:image` at a local `/public/og.png` served by GitHub Pages or a static host.

**Why:** Local assets behind GitHub Pages unfurl intermittently in iMessage, WhatsApp, and Slack. The original page renders fine, but the unfurler silently skips the image — usually because of slow first-byte time, missing `Content-Length`, missing CORS, or aggressive negative caching. CDNs (ImageKit in particular) ship the right headers (`access-control-allow-origin: *`, `cache-control: public, max-age=…`, accurate `content-length`, `etag`) and serve from edges close to the unfurler.

**How to apply:** When scaffolding a new site's OG defaults, upload the banner to ImageKit first and reference the absolute URL. Treat `/public/og-default.png` as a fallback only — better yet, do not bother committing it.

### 2. Prefer JPEG over WebP for the bytes the unfurler receives

**Rule:** The image bytes that reach iMessage, WhatsApp, Slack, Discord, LinkedIn, X, and Facebook should be **JPEG**. PNG is a fine second choice for graphics with text. WebP is risky.

**Why:** WebP support across unfurlers is uneven and historically silent-failing. iMessage and WhatsApp have both shipped versions that ignore WebP previews entirely. JPEG is universally accepted, ~95 KB at 1200×630 for a photographic banner — small enough that no unfurler chokes on it.

**How to apply:** If you are exporting from Image-Gin / Figma / Photoshop, export JPEG. If you are using ImageKit transformations, request `?tr=f-jpg` or rely on its content negotiation (see rule 3). To convert an existing local file, the user is likely to have `ffmpeg` installed — `ffmpeg -i in.webp out.jpg` is the simplest one-liner; see [references/seo-best-practices.md](references/seo-best-practices.md) for more conversion recipes.

### 3. `og:image:type` must match the actual bytes the unfurler receives — not the URL extension

**Rule:** Verify with `curl -sI` (no `Accept` header) what `content-type` the server returns. Whatever that is — `image/jpeg`, `image/png`, `image/webp` — is what goes in `<meta property="og:image:type">`. The URL's file extension is not authoritative.

**Why:** ImageKit (and many modern CDNs) content-negotiate via `Vary: Accept`. A URL ending in `.webp` will serve `image/webp` to a Chrome browser that sends `Accept: image/webp`, but `image/jpeg` to an unfurler that doesn't. If your meta tag declares `image/webp` but the unfurler downloads `image/jpeg`, strict validators (and some unfurlers) bail. Match the declared type to the bytes most unfurlers actually receive.

**How to apply:** Before committing, run:
```bash
curl -sI "<your-og-image-url>" | grep -iE "content-type|content-length|vary"
```
The `content-type` line is what you put in `og:image:type`. If `vary: accept` is present, you are content-negotiated — declare the JPEG/PNG response (the no-`Accept` default), not the WebP variant.

### 4. Absolute URLs only

**Rule:** Every `og:image`, `og:image:secure_url`, `og:url`, `twitter:image`, and canonical `href` is a fully qualified `https://…` URL.

**Why:** Unfurlers do not know the origin. A path like `/og.png` resolves to *their* origin (often nothing) and is dropped. This bites especially hard on sites served under a base path (GitHub Pages `/repo-name/`).

**How to apply:** In Astro, build the absolute URL from `Astro.site` (or `Astro.url.origin`) plus `import.meta.env.BASE_URL` plus the path. Branch on `startsWith('http')` so absolute URLs pass through untouched. See the `MetaTags.astro` pattern in any Astro Knots site.

### 5. Always emit the full image-meta sextet

**Rule:** Every page emits all six OG image properties:

```html
<meta property="og:image"            content="https://cdn.example.com/banner.jpg" />
<meta property="og:image:secure_url" content="https://cdn.example.com/banner.jpg" />
<meta property="og:image:type"       content="image/jpeg" />
<meta property="og:image:width"      content="1200" />
<meta property="og:image:height"     content="630" />
<meta property="og:image:alt"        content="Descriptive alt text — one short sentence." />
```

Plus the Twitter card pair:
```html
<meta name="twitter:card"     content="summary_large_image" />
<meta name="twitter:image"    content="https://cdn.example.com/banner.jpg" />
<meta name="twitter:image:alt" content="Descriptive alt text — one short sentence." />
```

**Why:** Width and height let the unfurler reserve layout space without downloading the image. Type lets it skip formats it cannot render. Alt is required for accessibility *and* used by some clients (Slack) as the fallback caption. `secure_url` is legacy but still consulted by older clients. Omitting any of these turns into "sometimes it shows, sometimes it doesn't."

### 6. Standard banner dimensions: 1200 × 630

**Rule:** Default OG banners are **1200 × 630** (the "Image-Gin wide" standard). Plugin/page-specific overrides may use other ratios but must declare matching width/height in the meta tags.

**Why:** 1200 × 630 is the largest size Facebook/LinkedIn/X render without re-cropping, the size iMessage and WhatsApp expect for "rich" previews, and small enough (~90–150 KB JPEG) for fast unfurling. 1408 × 704 and similar non-standard sizes get center-cropped or downscaled inconsistently.

**How to apply:** Image-Gin is configured to export 1200 × 630. If you are hand-cropping in Figma, snap to that size. Never declare width/height that do not match the actual file.

### 7. Cache-bust to force a re-unfurl

**Rule:** When you change an OG image or the meta tags and the old preview keeps showing, append `?v=2` (or any new query string) to `og:url` and the share URL.

**Why:** iMessage, WhatsApp, Slack, and Discord cache OG metadata **per exact URL**, often for days. They do not honor `Cache-Control` from your origin for this — only a different URL invalidates. Most have no public "force re-fetch" button.

**How to apply:** For one-off shares, just paste `https://example.com/page?v=2`. For a permanent re-unfurl on a marketing page, bump a version in the canonical URL and add a redirect from the old. For Facebook/LinkedIn, use their debuggers (see references/unfurler-matrix.md).

## The minimum viable `<head>`

```html
<!-- Title + description -->
<title>Page Title — site-name</title>
<meta name="description" content="One-sentence description, ≤155 characters, no trailing site-name." />
<link rel="canonical" href="https://example.com/page" />

<!-- OpenGraph -->
<meta property="og:type" content="website" />
<meta property="og:site_name" content="site-name" />
<meta property="og:title" content="Page Title — site-name" />
<meta property="og:description" content="Same one-sentence description." />
<meta property="og:url" content="https://example.com/page" />
<meta property="og:image" content="https://cdn.example.com/banner.jpg" />
<meta property="og:image:secure_url" content="https://cdn.example.com/banner.jpg" />
<meta property="og:image:type" content="image/jpeg" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:image:alt" content="Descriptive alt text." />

<!-- Twitter / X -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="Page Title — site-name" />
<meta name="twitter:description" content="Same one-sentence description." />
<meta name="twitter:image" content="https://cdn.example.com/banner.jpg" />
<meta name="twitter:image:alt" content="Descriptive alt text." />
```

For `og:type=article` add `article:published_time`, `article:modified_time`, `article:author`, and one `article:tag` per tag.

## Character limits (truncate at render, not source)

| Field          | Limit | Notes                                                              |
| -------------- | ----- | ------------------------------------------------------------------ |
| `<title>`      | 60    | Including site-name suffix. Truncate at word boundary with ellipsis. |
| `description`  | 155   | Same string for `<meta>`, `og:description`, `twitter:description`. |
| `og:image:alt` | 420   | Practically: one short sentence.                                   |

Store the long version in your SEO registry; truncate inside the `MetaTags` component.

## GEO (Generative Engine Optimization) — the bonus layer

Generative engines (Perplexity, ChatGPT search, Claude, Gemini, Google AI Overviews) consume the same `<head>` metadata as social unfurlers, plus a few extras. The OpenGraph rules above already cover ~80% of GEO. Add these:

1. **JSON-LD `Article` schema** for blog/changelog/long-form pages. `@context: https://schema.org`, `@type: Article` (or `BlogPosting`, `NewsArticle`), `headline`, `description`, `image`, `datePublished`, `dateModified`, `author`. Generative engines use this as ground truth more than they use OG tags.
2. **Clear, factual first paragraph.** The first 200 characters of body text are what gets quoted. Lead with the claim, not a hook.
3. **`<h1>` matches `<title>` semantically.** Engines penalize divergence between them as a relevance signal.
4. **Stable canonical URLs.** Do not let GEO-indexable content live behind query-string variants. Always set `<link rel="canonical">`.
5. **`robots.txt` allows AI crawlers** (or the specific ones you want to be cited by). The default is conservative — explicitly allow `GPTBot`, `ClaudeBot`, `PerplexityBot`, `Google-Extended` if you want to be cited.

For the deeper schema.org patterns, defer to the page-type-specific spec when one exists in `context-v/` of the project. For broader on-page and technical SEO concerns that also feed GEO (canonicals, sitemaps, breadcrumbs, anti-patterns), see [references/seo-best-practices.md](references/seo-best-practices.md).

## Verification recipe

Before merging changes that touch OG metadata:

```bash
# 1. Confirm the bytes the unfurler will receive
curl -sI "<og-image-url>" | grep -iE "content-type|content-length|vary"

# 2. Confirm the meta tags actually render
curl -s "<page-url>" | grep -iE 'og:|twitter:'

# 3. Manual unfurl test — the only ground truth
#    Send the URL to yourself in iMessage and WhatsApp.
#    Both must show: image, title, description.
```

For Facebook/LinkedIn/X debuggers and per-client quirks (TTLs, fallbacks, what each one ignores), see [references/unfurler-matrix.md](references/unfurler-matrix.md).

## Common failure modes (and the fix)

| Symptom                                         | Likely cause                              | Fix                                                        |
| ----------------------------------------------- | ----------------------------------------- | ---------------------------------------------------------- |
| iMessage shows title only, no image             | Image is WebP or hosted on slow origin    | Switch to JPEG on a CDN. Re-share with `?v=2`.             |
| WhatsApp shows old image after update           | Per-URL cache                             | Append `?v=N` query string                                 |
| Slack unfurls, others don't                     | `og:image:type` mismatch with actual bytes | `curl -sI` the image, fix the meta tag                     |
| LinkedIn unfurl is stale                        | LinkedIn caches for ~7 days               | LinkedIn Post Inspector → "Inspect" forces re-fetch        |
| Facebook shows wrong image                      | Old scrape cached                          | Facebook Sharing Debugger → "Scrape Again"                 |
| Image renders zoomed / cropped weirdly          | Wrong width/height declared OR not 1200×630 | Re-export at 1200×630, fix meta tag                        |
| Local dev unfurl test fails                     | Page is not publicly reachable            | Deploy to a preview URL — unfurlers cannot reach localhost |

## See also

- [references/unfurler-matrix.md](references/unfurler-matrix.md) — per-client TTLs, debuggers, image format support, and known bugs.
- [references/seo-best-practices.md](references/seo-best-practices.md) — titles, headings, URL structure, schema beyond Article, sitemaps, Core Web Vitals, image SEO, anti-patterns, pre-launch audit checklist.
- [references/user-tools-for-image-generation.md](references/user-tools-for-image-generation.md) — which image-generation tool the user prefers (currently Ideogram), with a swap-out config block agents read to decide how to call it.
