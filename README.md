---
name: lossless-skills-readme
description: Overview of the Lossless Skills collection - installation instructions, skill status, and contributing guidelines. Reference only.
---

# Lossless Skills

The Lossless Group's agent skills collection — across projects and people.

A shared library of [Agent Skills](https://agentskills.io/specification) used by Lossless team members and AI coding agents on Lossless projects. Skills here are tool-agnostic: they work with [pi-coding-agent](https://github.com/badlogic/pi-mono), Claude Code, OpenAI Codex, and anything else that follows the Agent Skills standard.

## Built in public

This repo is part of [The Lossless Group's](https://www.lossless.group) **Lost in Public** practice: developing methods, tooling, and institutional knowledge openly so others can adopt, adapt, critique, and contribute. Expect frequent commits, occasional churn, and skills that evolve as the team's real workflows reveal what works.

If a skill here helps you, take it. If you find a sharper way to express it, open a PR. If you disagree with a convention, open an issue — we'd rather argue in public than silently diverge.

## Skills

| Skill | Directory | What it covers — and why we care |
|---|---|---|
| **Context Vigilance** | [`context-vigilance/`](./context-vigilance/) | Framework for managing `context-v/` directories — directory roles (specs / prompts / blueprints / reminders / explorations / issues), four-part `epoch.major.minor.patch` versioning, YAML frontmatter, wikilinks. AI co-development drowns in unstructured context; this is the team's working contribution to making thinking durable, retrievable, and version-aware across humans and agents. See <https://www.lossless.group/projects/gallery/context-vigilance>. |
| **Pseudomonorepos** | [`pseudomonorepos/`](./pseudomonorepos/) | Coined Lossless pattern: parent repos that aggregate child repos (often submodules) primarily to host a parent-level `context-v/`. Encodes a *search-before-create* discipline and a tree-walking routine — without it, the same idea gets started in three places and the team loses to itself. |
| **Study Repos First** | [`study-repos-first/`](./study-repos-first/) | Discipline of pinning a curated collection of upstream repos (a *study*) around a domain question *before* designing or coding in that domain. Encodes "read upstream code, don't paraphrase from training data" — agents reach for plausible-but-stale conventions when real prior art is one `cd` away. This enforces the search-first habit for conventions, schemas, and protocols, and the setup mechanics for a study (named question, pinned submodules, promote-when-grows). |
| **Astro Knots** | [`astro-knots/`](./astro-knots/) | Tech hierarchy (HTML / CSS first, then vanilla JS, then a small package, then a framework), approved frameworks (Astro, Svelte, GSAP, Reveal), and hard prohibitions (React, JSX, Angular) for the family of ~10+ Astro sites. Without it, agents reach for `npm install` reflexively and the sites drift toward generic React-shaped JAMstack. See <https://www.lossless.group/projects/gallery/astro-knots>. |
| **Changelog Conventions** | [`changelog-conventions/`](./changelog-conventions/) | How to write `changelog/` entries — frontmatter (`publish: true`, `lede`, ISO dates), `YYYY-MM-DD_NN.md` filenames, `releases/` subfolder for product-style projects, show-don't-enforce ethos. "Changelog First Development" is the team's working theory: a fast-moving public changelog signals momentum to clients, contributors, and your future self. |
| **Git Conventions** | [`git-conventions/`](./git-conventions/) | Commit message conventions — structured headers with action verbs and effort groupings, paragraph-spaced bodies that explain impact before implementation, "Also included" riders for minor changes. Conventional Commits is too narrow; this captures both the change and the reason in a way that reads sensibly a year later. |
| **Theme System** | [`theme-system/`](./theme-system/) | Theme and mode architecture for Astro Knots sites: two-tier token system, three-mode contract (light / dark / vibrant), `theme.css` organization, design-system conventions. Without a shared system every site re-invents tokens, and mode toggles break in ways that are hard to debug after the fact. |
| **Maintain DESIGN.md** | [`maintain-design-md/`](./maintain-design-md/) | How to author and maintain a `DESIGN.md` file at the project root following [Google Stitch's open spec](https://github.com/google-labs-code/design.md) — frontmatter token groups (colors, typography, rounded, spacing, components) plus the eight canonical prose sections, the maintenance triggers (what code changes should bounce back into the doc), the runtime-CSS-is-source-of-truth discipline, and the precedent for off-spec extensions like the `imagery:` block. The agent-readable contract for a project's visual identity. Composes with `theme-system` (architecture) and `generate-consistent-og-images` (which reads the `imagery:` extension). |
| **Deck Iteration Workflow** | [`deck-iteration-workflow/`](./deck-iteration-workflow/) | Workflow for slides-only Astro sites (fundraise decks, conference talks): variant management, structured iteration cycle, alignment with the `calmstorm-decks` project patterns. Decks rot fast and agents over-engineer them; this keeps generation cheap and revision discipline tight when timelines are real. |
| **Crawl, Fetch, Ingest** | [`crawl-fetch-ingest/`](./crawl-fetch-ingest/) | The team's workflow for filling in team and portfolio metadata for VC firms (and similar org work): crawl a firm's site, fetch structured data + brand assets for people and companies referenced in a deck/PDF, ingest as canonical `.md` files with YAML frontmatter. Encodes the four-checkpoint cascade (VC team → advisors → portfolio companies → portco CEOs), the cross-tool fallback pattern (Firecrawl → Tavily → OpenGraph.io), the global-cache-per-firm convention so the same firm's data is reused across multiple decks/memos. |
| **OpenGraph, Share, SEO & GEO** | [`open-graph-share-seo-geo/`](./open-graph-share-seo-geo/) | Rules for reliable share-preview unfurls in iMessage, WhatsApp, Slack, Discord, LinkedIn, X — plus traditional SEO and Generative Engine Optimization (GEO). Encodes the JPEG-over-WebP rule, the CDN-not-`/public` rule, and the ImageKit content-negotiation gotcha (`og:image:type` must match the bytes the unfurler actually receives, not the URL extension) that cost us a debugging cycle. |
| **Generate Consistent OG Images** | [`generate-consistent-og-images/`](./generate-consistent-og-images/) | How to generate share-imagery (banners, portraits, squares, tall WhatsApp/iMessage cards) for any Lossless site so the resulting images form a coherent visual family. Locks every parameter on the Ideogram v3 request except `prompt` and `aspect_ratio`; the rest (style reference, color palette weights, negative prompt, seed, rendering speed) lives in the project's `DESIGN.md` `imagery:` block. Encodes the empty-space-as-first-class-subject prompt structure (lead with the empty region, give it concrete content, then put the subject in the second clause) that defeats the "subject grows up into the SVG overlay zone" failure mode. WhatsApp / iMessage chat-preview is the primary target. |
| **Lossless Flavored Markdown** | [`lossless-flavored-markdown/`](./lossless-flavored-markdown/) | Polyglot extended-markdown spec — user-configured *syntax-triggers* drive a render pipeline in a frontend framework, giving plain `.md` files MDX-class power without MDX's JSX-shaped lock-in. Implemented as `@lossless-group/lfm` on [JSR](https://jsr.io); source lives in `astro-knots/`. Use when authoring or rendering content, building components routed from markdown, or co-developing the package itself. |
| **Maintain Splash Pages** *(Draft)* | [`maintain-splash-pages/`](./maintain-splash-pages/) | The repo-level splash pattern: small Astro sites at `<repo>/splash/` that ship to GitHub Pages on push to `main`, render the repo's `changelog/` + `context-v/` alongside curated marketing copy, and stay isolated from any package the repo also publishes. Codifies the proven shape across three reference implementations (`memopop-site`, `content-farm/splash`, `lfm/splash`) and the package-isolation discipline that keeps splashes safe to add to repos that also publish to JSR / npm. |
| **Chroma Agent Skills** *(submodule)* | [`chroma-agent-skills/`](./chroma-agent-skills/) | Official skills from the [Chroma](https://www.trychroma.com) team for integrating Chroma local and Chroma Cloud (CloudClient, schema, hybrid search, cloud CLI). Pinned as a git submodule from [`chroma-core/agent-skills`](https://github.com/chroma-core/agent-skills); we vendor it here so any agent loading the Lossless skills tree gets battle-tested vector-store guidance from upstream rather than paraphrased-from-training-data Chroma usage. |

**Planned / not yet shipped:** `lossless-loop/` — the 5-phase Start → Progress → Reflect → Publish → Market lifecycle for any meaningful unit of work. Diagram and spec live at `pseudomonorepos/references/lifecycle-workflow.md` until the skill graduates.

A running backlog of additional candidates lives in [**`CANDIDATES.md`**](./CANDIDATES.md).

## Engineer-influencer collections we watch

External skills repos from engineer-influencers in the broader community. We track them for inspiration and to see where conventions converge. These are not pinned references — just repos whose evolution we follow.

| Engineer | Repo | Known for |
|---|---|---|
| **Matt Pocock** | [mattpocock/skills](https://github.com/mattpocock/skills) | TypeScript educator and engineer (Total TypeScript, `ts-reset`). |

## Install

### Pi (recommended for Lossless contributors)

```bash
pi install git:github.com/lossless-group/lossless-skills
```

Or clone directly into the global skills directory:

```bash
git clone https://github.com/lossless-group/lossless-skills.git ~/.pi/agent/skills
```

In an active pi session, run `/reload` to pick up changes without restarting.

### Claude Code

Clone into Claude's skills directory:

```bash
git clone https://github.com/lossless-group/lossless-skills.git ~/.claude/skills
```

### OpenAI Codex / other harnesses

Clone anywhere and point your tool's skills configuration at the directory.

### Cross-tool sharing on one machine

Use the `~/.agents/skills/` location (read by pi and other Agent-Skills-compatible tools), or symlink:

```bash
ln -s ~/.pi/agent/skills ~/.agents/skills
```

## Layout

Each skill is a directory with a `SKILL.md` file:

```
<skill-name>/
├── SKILL.md              # Required: frontmatter (name, description) + instructions
├── references/           # Deep-dive docs the agent loads on demand
├── templates/            # Scaffolds for new files
└── scripts/              # Helper scripts (when needed)
```

The `description` in `SKILL.md` frontmatter determines when an agent will auto-load the skill. Be specific.

## Contributing

Skills here represent shared Lossless conventions. Before adding or changing a skill:

1. **Discuss first** if it changes how the team works (open an issue or a draft PR with rationale).
2. **Match existing conventions:**
   - Skill directory and `name:` field: lowercase with hyphens (e.g., `context-vigilance`)
   - Filenames inside skills: `Train-Case.md`
   - Frontmatter follows the Agent Skills spec
3. **Test the skill** in a real session before committing — verify the agent loads it when you'd expect.
4. **Commit message convention:**
   ```
   skill(<skill-name>): short description
   ```

### Adding a new skill

1. `mkdir <skill-name>` (lowercase, hyphens, must match `name:` in frontmatter)
2. Create `SKILL.md`:
   ```yaml
   ---
   name: <skill-name>
   description: When the agent should load this skill. Be specific about triggers.
   ---
   ```
3. Add `references/`, `templates/`, `scripts/` as needed
4. Update the **Skills** table in this README
5. Open a PR

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [pi skills documentation](https://github.com/badlogic/pi-mono/blob/main/packages/pi-coding-agent/docs/skills.md)
- [Context Vigilance project](https://www.lossless.group/projects/gallery/context-vigilance)
- [The Lossless Group](https://www.lossless.group)

## License

[MIT](./LICENSE) © The Lossless Group
