---
name: astro-knots
description: The Lossless Group's Astro Knots conventions — vision, tech hierarchy, approved frameworks, and hard prohibitions for the family of ~10+ Astro sites and the Lossless Flavored Markdown ecosystem. Use whenever working on an Astro project in the lossless-monorepo (or any sibling repo), scaffolding new sites, choosing dependencies, building components, integrating LFM, or when the user mentions "Astro Knots", "LFM", "Lossless Flavored Markdown", or "pseudomonorepo". Hard prohibitions on React, JSX, Angular, and unnecessary dependencies.
---

# Astro Knots

> A vision-mission masquerading as a stack: use the Internet as it was originally, idealistically intended.

Astro Knots is The Lossless Group's umbrella for a family of conventions across **~10+ Astro sites at various stages**, built around Astro + Extended Markdown + SCM workflows + APIs. Think JAMstack with a steeper opinion gradient — and no one's heard of it yet.

Reference site: <https://www.lossless.group/projects/gallery/astro-knots>

## When to use this skill

- Working in any Astro project under `lossless-monorepo` or a sibling repo
- Scaffolding a new Astro site (multiple new sites per quarter is normal)
- Choosing or adding dependencies — **always check tech rules below before installing anything**
- Building components, page layouts, content pipelines
- Integrating [Lossless Flavored Markdown (LFM)](https://jsr.io/@lossless-group/lfm)
- User mentions "Astro Knots", "LFM", "extended markdown", "pseudomonorepo", or any of the ~10 site names
- Code review or refactor on an Astro Knots project

## The vision (don't skip)

1. **Internet as originally intended.** Documents, links, hypertext. Composable, not bundled. Readable URLs. Fast pages. Open formats.
2. **Build in public.** Ship code and content together. Document thinking *while* shipping, not after.
3. **Generate meaningful content while shipping.** Every project produces durable thought-artifacts (specs, blueprints, explorations). The work and the writing are the same activity.
4. **Forefront of Human + AI + Agent collaboration.** Aspire to make a meaningful contribution to how humans and agents build things together. The `context-v/` framework is one such contribution; LFM is another.

If a proposal contradicts these, push back before implementing.

## The Tech Hierarchy

A strict preference order. Always reach for the lowest level that works.

1. **HTML & CSS** — first choice. Semantic HTML, modern CSS (grid, flexbox, container queries, `@supports`, native nesting). If HTML+CSS can do it, do not reach higher.
2. **Vanilla JS** — when interactivity is genuinely needed. Web standards (Fetch, IntersectionObserver, custom elements) before any helper.
3. **A small focused package** — when vanilla JS would require reinventing something hard. Prefer single-purpose, low-dep, ideally tree-shakeable libraries.
4. **A framework** — last resort, and only one of the approved few below.

> Fewer dependencies is always better. Dependencies are liabilities, not assets.

## Approved Frameworks (and only these)

| Framework | When to use | Why approved |
|---|---|---|
| **Astro** | Default site framework | Server-first, ships zero JS by default, partial hydration on demand |
| **Svelte** | Interactivity that genuinely benefits from reactivity / SSR | Compiles to small vanilla JS; no virtual DOM tax |
| **GSAP** | Animations that exceed CSS animations / transitions | Battle-tested; only when CSS truly can't |
| **Reveal.js** | One of three presentation-as-code renderings | Plain-HTML slides authored as Markdown |

> Two other presentation renderings exist alongside Reveal. // TBD: confirm which (likely Marp and/or Slidev). Update this table when confirmed.

### Conditional / experimental

We will *test* new tools but stay skeptical. Anything not in the approved list is on probation by default.

## Hard Prohibitions

These are not vetoes-with-exceptions. They are **no**.

- ❌ **React** — bundle weight, virtual DOM tax, ecosystem sprawl
- ❌ **JSX** in any form — including in Astro components (Astro supports `.astro` syntax; use it)
- ❌ **Angular**
- ❌ **Any "bloat" framework** that violates the Tech Hierarchy

If a third-party tool *requires* React/JSX/Angular as a runtime dep, find another tool or build the slice we need. If the user explicitly asks for React, push back and offer the equivalent in approved tech. Only proceed if they confirm with full understanding.

## Lossless Flavored Markdown (LFM)

Our first true package. Polyglot but lean: extended markdown syntax → component render pipeline. More daring than CommonMark, less rigid than MDX. **Any syntax can be added as a trigger to render a component.**

- Production: <https://jsr.io/@lossless-group/lfm>
- Philosophy: assimilate the best ideas, let anyone try anything

A dedicated `lfm` skill is **forthcoming**. Until it lands:

- Prefer LFM-friendly content patterns when authoring `.md` files for Astro Knots sites
- If the user wants extended markdown syntax (callouts, embeds, transclusions, etc.), reach for LFM-shaped solutions, not MDX
- Don't suggest MDX as an alternative

## Pseudomonorepos

Our coined term — see `references/pseudomonorepos.md`. Brief: a parent repo that adds child repos as **git submodules**, primarily so the parent can host a `context-v/` that aggregates context across the children. Not a true monorepo (no shared build, no shared deps), not loosely coupled either.

Implication: when working in a child repo, also check the parent's `context-v/` for relevant blueprints/specs. Headaches in implementation often have answers in the parent.

A dedicated `pseudomonorepos` skill **exists** — load it whenever working in this tree. It encodes the search-first discipline that composes with everything else.

## How to behave (decision rules)

When the user asks for X, default behavior:

| Ask | Default response |
|---|---|
| "Add React" / "use React" | Push back. Offer Astro + Svelte equivalent. |
| "Use MDX" | Push back. Offer LFM-shaped approach. |
| "Install [framework]" | Check Tech Hierarchy. If not approved, ask why and propose alternative. |
| "Add a UI library" | Strong skepticism. Most often: write the component in Astro/Svelte. |
| "Animate this" | CSS first. GSAP only if CSS genuinely can't do it. |
| "Make it interactive" | Vanilla JS or Svelte. Justify before reaching higher. |
| "Build a slide deck" | Markdown + Reveal (or one of the other two). |
| "Document this work" | Use `context-v/` per the `context-vigilance` skill. |

## Cross-skill ties

- **`context-vigilance`** governs *how* we document. **`astro-knots`** governs *what* we build (and the values around it). They compose: blueprints in a project's `context-v/blueprints/` should reflect Astro Knots tech principles.
- **`pseudomonorepos`** — shipped. Composes directly with this skill: walk the tree, search before creating, log refactor debt when shipping fast.
- Forthcoming: **`lfm`** (Lossless Flavored Markdown).

## See also

- `references/philosophy.md` — the vision in depth, build-in-public practice
- `references/tech-stack.md` — full rationale for each approved/prohibited tech
- `references/ecosystem.md` — the family of sites, LFM, pseudomonorepos, roadmap
