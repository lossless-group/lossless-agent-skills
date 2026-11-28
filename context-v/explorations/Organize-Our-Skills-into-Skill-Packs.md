---
title: "Organize Our Skills into Skill Packs"
lede: "Forty-odd skills in one flat folder work for us. To work for anyone else, they need to become packs: each one a repo with its own name, audience, and install, living where it's used and mounted here too."
date_created: 2026-11-22
date_modified: 2026-11-27
date_authored_initial_draft: 2026-11-22
date_authored_current_draft: 2026-11-27
authors:
  - Michael Staton
augmented_with:
  - Claude Code on Claude Opus 5.5
at_semantic_version: 0.0.0.3
status: Open
site_uuid: 9ee9f5ec-ecc9-4796-b989-a8ede7deeb3a
hex_code: plp58x
summary: >-
  Sets the goal of reorganizing lossless-agent-skills into skill packs, two
  ways at once: each pack is one repo that lives in its natural habitat (the
  product or project that uses it) and is also mounted here as a submodule;
  and each pack is shaped and branded so people outside The Lossless Group and
  its clients can find, install, and use it, whether they are developers or
  business professionals picking by role, department, or type of firm. Takes
  the vc-skill-pack (skills shared with MemoPop, DidiDecks, and event-hog) as
  the hard case, because a skill that belongs to several packs needs one
  source of truth. Reads against four packs pinned in the agent-skill-packs
  study (pstack, seo-skills, mattpocock-skills, gstack).
publish: true
type: Explorations
tags: [Agent-Skills, Skill-Packs, Pseudomonorepos, Distribution, Branding]
---

# Organize Our Skills into Skill Packs

## The goal

Turn this repo's growing list of skills into **skill packs**: named clusters of
skills that work together, built for a specific kind of user. Two requirements,
both at once:

1. **A pack lives in its natural habitat and here.** Each pack is one repo. It
   is mounted as a submodule where it is used day to day (MemoPop, DidiDecks,
   event-hog, an Astro Knots site) **and** in `lossless-agent-skills`, which
   becomes the index of every pack rather than the home of every skill.
2. **A pack can get traction outside us.** It is shaped, named, documented, and
   installable so that people who are not Lossless team members or live clients
   can find it and use it in a few minutes. That audience includes developers
   trying to get good with agents, **and** business professionals choosing by
   role, team, or department (finance, ops, IR, marketing), or by type of firm
   (venture capital, family office, nonprofit, agency).

Some skills belong in more than one pack. The first case is a
**`vc-skill-pack`** for venture capital firms, made of skills that also ship
inside MemoPop, DidiDecks, and event-hog. A shared skill has to have **one**
source of truth, mounted or acknowledged everywhere it appears.

***

## Where we are today

- **One flat folder.** About 43 skill directories at the repo root, plus
  vendored submodules (`chroma-agent-skills`, `archify`, `talk-normal`,
  `humanizer`, `agent-reach`, `floorplan`). The README's Skills table mixes
  developer conventions (`git-conventions`, `pseudomonorepos`), Astro site
  rules (`astro-knots`, `theme-system`), VC and CRM workflows
  (`lossless-crm-interface-guidelines`, `decile-hub-connector`,
  `competitive-analysis`), and event work (`event-prep`,
  `augment-speakers-panelists`). A visitor can't tell which part is for them.
- **Install means taking everything.** `git clone … ~/.claude/skills` or
  `pi install` pulls all 43, including skills that only work against our own
  Twenty instances and Astro sites. There is no plugin manifest, no version,
  and no way to install one group. The splash does render a page per skill
  (`/skills/[slug]/`), but it is styled for developers and has no install
  button.
- **The catalog has drifted.** Twelve skill folders have no row in the README
  table; the install commands still name the repo `lossless-skills`;
  `CLAUDE.md` still says it mounts at `context-v/skills/`. An outsider would hit
  all three before using a single skill.
- **Skills already live in several places, as copies.** Measured 2026-11-22:

  | Skill | Copies | State |
  |---|---|---|
  | `crawl-fetch-ingest` | here; `dididecks-ai/context-v/agent-skills/` | **Diverged** (`routines/investor-credibility-ingest.md` differs). The harness loads the DidiDecks copy, because the sync script picks the most recently updated. |
  | `competitive-analysis` | here; `memopop-ai/context-v/agent-skills/` | **Diverged** (`SKILL.md` differs). The harness loads this repo's copy. |
  | `market-capture-analysis`, `timeline-scenario-analysis` | here; `memopop-ai/context-v/agent-skills/` | Two copies each |
  | `remake-deck`, `slide-target` | here; `dididecks-ai/context-v/agent-skills/` | Two copies each |
  | `augment-speakers-panelists` | here; `event-hog-mcp/kit/skills/` | Two copies, identical today |

  Which copy an agent gets depends on file timestamps. That is the drift the
  pack structure has to end.
- **Two products already ship skills as a unit**, each in its own way.
  MemoPop has a Claude Code plugin (`memopop-orchestrator/plugin/`, manifest
  `.claude-plugin/plugin.json`, v0.2.0). event-hog serves a `kit/skills/`
  folder over its MCP server (`list_skills`, `get_skill`), with `brand/`,
  `config/`, and `templates/` beside it. Neither is mounted here.
- **`THIRD-PARTY.md` already names a "skill pack" shape**, but only for packs
  we mine and never load (`context-v/skill-packs/<pack>/`). This exploration
  is about packs we build and load.

***

## Requirement 1: one repo per pack, mounted in two places

The pseudomonorepo already knows how to do this: a repo is the unit, and
parents mount children as submodules.

```
lossless-group/vc-skill-pack            ← the pack's own repo (source of truth)
├── README.md                           ← who it's for, what's inside, install
├── .claude-plugin/plugin.json          ← one install per harness (see Requirement 2)
├── skills/<skill>/SKILL.md
└── docs/<skill>.md                     ← one human page per skill

mounted at:
  lossless-agent-skills/packs/vc-skill-pack          ← the index of all packs
  memopop-ai/…/vc-skill-pack (or the skills it needs) ← natural habitat
```

What `lossless-agent-skills` becomes: a **catalog**. Its README lists packs,
not skills. Cross-cutting skills that serve every pack (`context-vigilance`,
`git-conventions`, `changelog-conventions`) can stay at the root, or become a
`lossless-dev` pack of their own.

### The hard case: a skill in more than one pack

`competitive-analysis` belongs in `vc-skill-pack` and is used by MemoPop. 
`augment-speakers-panelists` belongs in `vc-skill-pack` (firms work conferences)
and in event-hog. Three ways to handle it:

| Option | How | Cost |
|---|---|---|
| **A. Every shared skill is its own repo**, nested as a submodule in each pack that uses it | `vc-skill-pack/skills/competitive-analysis` → `lossless-group/skill-competitive-analysis` | Most correct, most expensive. Nesting reaches four levels (monorepo → agent-skills → pack → skill). We never run recursive git commands in this tree, so every level is updated by hand, one submodule at a time. |
| **B. One pack owns the skill; other packs reference it** | `competitive-analysis` lives only in `vc-skill-pack`. MemoPop mounts `vc-skill-pack` (or names it as a dependency) instead of keeping a copy. | Cheap and has one source of truth. A product that needs one skill pulls the whole pack, and a skill has to have one obvious owner. |
| **C. Copies, with a manifest that says which is canonical** | Copies stay, a `skills.lock` or `SHARED.md` records the canonical path and SHA, and a check fails when a copy drifts | No new repos. Still copies, so drift is caught rather than prevented. |

**Leaning B, with A for the few skills that truly have no single owner.** Most
shared skills do have an obvious home (`competitive-analysis` is VC work first,
MemoPop second). Promote a skill to its own repo (A) only when two packs with
different audiences both own it. Today's copies-with-timestamps state is worse
than any of the three.

***

## Requirement 2: packs other people can use

A pack built for outsiders needs things our flat folder doesn't have. The
agent-skill-packs study (`ai-labs/studies/agent-skill-packs/`) profiles four
public packs; the list below is the starting checklist, to be sharpened by
those profiles.

- **A name and an audience.** "Skills for venture capital firms", not "Lossless
  Skills". One sentence on the README says who it's for.
- **Install per harness, in one line, for just this pack.** A plugin manifest
  for Claude Code, plus the `npx skills add <repo>` path and a manual copy for
  everyone else.
- **Grouped and governed.** Skills grouped by job or maturity, with a stated
  bar for what gets in.
- **A way in.** A router or index skill that tells the agent (and the person)
  which skill to use for what.
- **A page per skill**, written for the person, not the agent: what it does,
  when to reach for it, an example prompt, what "working" looks like. Our
  splash already has the page; it needs the content and an install button.
- **Public method, private config.** Already ours: particulars in a gitignored
  `config/private.json`, documented by `private.example.json`. This is the
  thing that makes a pack built for our clients publishable to everyone else,
  and none of the four studied packs has an equivalent.

### Audiences beyond developers

Developer packs are the crowded part of the market. The open ground is
business professionals, packaged two ways:

- **By role or department:** investor relations, deal team, platform/community,
  finance and fund admin, marketing.
- **By type of firm:** venture capital, family office, foundation or nonprofit,
  agency or studio.

A business user won't clone a repo. For them, the pack's front door is
probably the product it already lives in (MemoPop's plugin, event-hog's MCP
`get_skill`) or a page with a one-click install, not a GitHub README.

***

## A first pack map

Proposed, not decided. Names are working titles.

| Pack | For | Skills (today's homes) |
|---|---|---|
| `vc-skill-pack` | Venture capital firms: deal team, platform, IR | `competitive-analysis`, `market-capture-analysis`, `timeline-scenario-analysis`, `12ps-5os-scorecard`, `thesis-bleed-cleanup` (MemoPop); `manage-memo-citations`, `repair-memo-citations`, `setup-new-firm` (MemoPop orchestrator); `remake-deck`, `slide-target`, `crawl-fetch-ingest` (DidiDecks); `augment-speakers-panelists`, `prioritize-attendees`, `draft-follow-up-emails`, `event-prep` (event-hog); `lossless-crm-interface-guidelines`, `decile-hub-connector` (here) |
| `event-skill-pack` | Anyone working a conference | event-hog's `kit/skills/` plus `event-prep`; overlaps `vc-skill-pack` |
| `lossless-dev` | Developers who want our working method | `context-vigilance`, `pseudomonorepos`, `study-repos-first`, `git-conventions`, `changelog-conventions`, `gh-cli-projects-tasks-conventions` |
| `astro-knots` | People building Astro sites our way | `astro-knots`, `theme-system`, `maintain-design-md`, `lossless-flavored-markdown`, `maintain-splash-pages`, `generate-consistent-og-images`, `open-graph-share-seo-geo`, `openpanel-analytics`, `trademark-packs-files`. **Moved 2026-11-22**, see below. |
| `content-and-share` | Marketers and writers | `open-graph-share-seo-geo`, `prep-images-for-embed`, `write-site-narrative`, `humanizer`, `talk-normal` |

Overlaps are deliberate: they are exactly the skills that need Option A or B.

***

## What the study shows

Four packs are profiled in `ai-labs/studies/agent-skill-packs/context-v/profiles/`,
each with a "Compared with lossless-agent-skills" section:
[[Profile__pstack]], [[Profile__mattpocock-skills]], [[Profile__gstack]],
[[Profile__seo-skills]].

| | pstack | mattpocock-skills | gstack | seo-skills |
|---|---|---|---|---|
| Size | 58 | 39 | 64 + router | 30 |
| Grouped by | Layer: 24 one-rule `principle-*` skills under 34 task skills | Maturity: engineering, productivity, in-progress, misc | Role on a software team | Domain: seo, content, copywriting, marketing |
| Way in | `poteto-mode` router, 22 playbooks; `poteto-help` | `ask-matt` router, re-synced by rule on every change | Root router skill, trigger lists, a routing hook | README catalog with an example prompt per skill, six named chains |
| Install | Two versioned plugin manifests, `npx skills add` | Self-updating plugin on four harnesses, skills.sh elsewhere | One paste, a 5,410-line `setup`, 13 typed harness adapters | `npx skills add`, three plugin manifests, `.mcp.json`, copy-paste site |
| Audience | Engineers | Engineers | Founders and engineers | Founders and marketers |

What they do that we don't, in rough order of how much it would help an
outsider:

1. **A one-step, versioned install.** pstack, Matt Pocock, and seo-skills ship
   plugin manifests; gstack installs through a setup script. Matt Pocock's
   manifest goes further and ships only his promoted skills, leaving
   experiments out. That curated subset is the model for us and the single
   biggest gap: our install hands an outsider our CRM connectors along with our
   git conventions.
2. **Grouping that means something to the reader.** By layer, maturity, role,
   or domain. None of them is flat.
3. **A way in.** Three of the four have a router skill; the fourth has a
   catalog with an example prompt for every skill. We have descriptions only.
4. **Governance an outsider can read.** Matt Pocock's pack has a written scope
   bar, a folder of recorded rejections, and "promoted" meaning a fixed bundle:
   README row, manifest entry, docs page, router entry. That one rule would
   have prevented our twelve missing README rows.
5. **Declared invocation.** pstack and Pocock mark each skill as typed by the
   person or reachable by the model. Every one of ours loads from its
   description, and some descriptions run past 2,000 characters, paid in every
   session. gstack caps its always-loaded catalog.
6. **Paid-API fallbacks with a budget.** seo-skills tries an MCP tool, then API
   keys from the environment, then a manual export, and stops at a spend cap.
   Our HubSpot, Decile, and CRM skills would benefit directly, and this is the
   pattern a business user needs most.

What we do that none of them does: **public skills with private config**; a
written **third-party intake policy** (`THIRD-PARTY.md`); skills that compose
with each other in writing; a changelog and a public site; no build step and no
hooks; and breadth beyond engineering. Breadth is our advantage for business
audiences and the reason grouping matters more for us than for them.

Two cautions from the study:

- **Heavy machinery has a cost.** gstack's templates, adapters, and hooks buy
  consistency at the price of a Bun dependency and edits to the user's
  `settings.json`. Our "no build step" stance is worth keeping for packs aimed
  at business users.
- **Packs don't make agents smarter.** gstack's own test found no gain in fix
  rate with the pack installed. A pack earns its place through workflow,
  consistency, and safety, so each pack should say what it makes reliable, and
  how we'd know.

***

## Agents inside a pack

A pack can ship subagents as well as skills. A skill is instructions the
current agent follows; a subagent is a separate worker, defined in one Markdown
file, that the agent starts with a fresh context and a report coming back.
pstack pairs them: its `poteto-mode` skill plans the work and its `poteto-agent`
subagent does each task after reading the skill. A `vc-skill-pack` could do the
same for long, noisy jobs such as a research pass on a company.

There is no standard for defining an agent the way Agent Skills defines a
skill. The full survey (fourteen competing formats, plus the layers that have
settled) is in the agent-workspace-bundles study:
[Ways to Define an Agent](https://github.com/lossless-group/study-agent-workspace-bundles/blob/main/context-v/explorations/Ways-to-Define-an-Agent.md).
In short:

| Need | Use | Why |
|---|---|---|
| A subagent shipped inside a pack | Markdown with frontmatter (`name`, `description`, prompt body) | The de facto shape in Claude Code and Cursor; matches `SKILL.md`; least likely to need rewriting when a spec settles |
| A product running as a service (MemoPop, event-hog) | A2A Agent Card | The only agent-description standard with real backing; describes what an agent does without exposing its prompts |
| A portable definition of a multi-step workflow | Watch Oracle's Agent Spec | The strongest cross-framework candidate (adapters to LangGraph, AutoGen, CrewAI), not yet adopted elsewhere |

***

## First move: `skill-packs/astro-knots` (2026-11-22)

The `astro-knots` pack is the first one made, as a folder in this repo
rather than a repo of its own:

```
lossless-agent-skills/skill-packs/astro-knots/
├── README.md
└── skills/<name>/SKILL.md      ← the nine skills in the pack map row
```

`skills/<name>/` is the layout a pack repo would have, so splitting it out
later is a `git subtree split` and a submodule, not a reshuffle. Until then
it costs nothing in git: no new repo, no extra submodule level.

What had to learn the new depth, and does:

- `sync-skills-symlinks.sh` and `sync-skills.sh` link each pack skill flat, as
  `~/.claude/skills/<name>`. Names don't change.
- Stow can't link that deep, so `.stow-local-ignore` skips `skill-packs/` and
  shows the one-line loop that links them by hand.
- The splash finds `skill-packs/*/skills/*/SKILL.md` and keeps each skill's
  bare name as its slug, so its page URL didn't move.
- The Astro Knots MCP's `sync-skills.mjs` looks in packs as well as the root.
- context-v-corpus's `skills_policy.py` and `build-skills-manifest.py` count
  pack skills as master skills, so child copies are still skipped as bundles.

The MCP also syncs `build-a-moodboard`, `maintain-design-system-page`,
`spike-then-refactor-into-components` and `write-site-narrative`, and
`generate-site-design-variants` is Astro work too. They are candidates for
this pack; `write-site-narrative` may belong to `content-and-share`.

***

## Every skill we have, and every one proposed (2026-11-27)

Found by walking the whole tree for `SKILL.md` (plus the MemoPop and event-hog
folders that serve skills over MCP), and by reading `CANDIDATES.md` and recent
`context-v/` docs for skills that are named but not written. Third-party skills
we only study are counted at the end, not listed. **Bold** marks a skill that
exists in more than one place.

### 1. In this repo, at the root (37)

| Group | Skills |
|---|---|
| Our working method | **`context-vigilance`**, **`pseudomonorepos`**, **`study-repos-first`**, **`git-conventions`**, **`changelog-conventions`**, `gh-cli-projects-tasks-conventions`, **`search-lossless-corpus`**, **`maintain-filemap`**, `obsidian-vault-hygiene`, `surrealdb-canonical-layer`, `shares-down-to-the-edge`, `cloudflare-artifacts-interface`, `graphify` |
| VC, CRM, deals | **`competitive-analysis`**, **`market-capture-analysis`**, **`timeline-scenario-analysis`**, `refactor-memo-to-form-requirements`, **`crawl-fetch-ingest`**, **`lossless-crm-interface-guidelines`**, `decile-hub-connector`, `hubspot-interface`, `create-contact-list-from-image-or-spreadsheet`, `expense-report-generation` |
| Decks | **`deck-iteration-workflow`**, **`remake-deck`**, **`slide-target`**, **`overlay-svg-text`** |
| Events | **`event-prep`**, **`augment-speakers-panelists`** |
| Sites and design (pack candidates) | **`build-a-moodboard`**, **`maintain-design-system-page`**, **`spike-then-refactor-into-components`**, **`write-site-narrative`** |
| Images and files | `prep-images-for-embed`, `slim-file-sizes`, `convert-images-to-pdf` |
| Writing | `humanizer` (vendored, see 3) |

### 2. In `skill-packs/astro-knots` (9)

**`astro-knots`**, **`theme-system`**, **`maintain-design-md`**,
**`lossless-flavored-markdown`**, **`maintain-splash-pages`**,
**`generate-consistent-og-images`**, **`open-graph-share-seo-geo`**,
`openpanel-analytics`, **`trademark-packs-files`**.

### 3. Vendored here, read-only (7)

`archify`, `chroma-local`, `chroma-cloud` (chroma-agent-skills), `floorplan`,
`humanizer`, `talk-normal`, `agent-reach`.

### 4. Written by us, living only outside this repo (about 75)

These are the ones a visitor to `lossless-agent-skills` never sees.

| Where | Skills that exist only there | Copies of skills from here |
|---|---|---|
| `ai-labs/context-vigilance-kit/agent-skills/` | `blueprint`, `decide`, `explore`, `handoff`, `implement`, `init`, `issue`, `kickoff`, `loop`, `new`, `plan`, `prep`, `prompt`, `reflect`, `remind`, `spec`, `upgrade`, `mobile-x-platform-w-tauri` (18) | `context-vigilance`, `pseudomonorepos` |
| `ai-labs/memopop-ai/context-v/agent-skills/` | `12ps-5os-scorecard`, `thesis-bleed-cleanup` | `competitive-analysis`, `market-capture-analysis`, `timeline-scenario-analysis` |
| `ai-labs/memopop-ai/agent-skills/` | `source-with-extracts-md`, `sources-md-curation`, `user-adds-adhoc-sources` | |
| `memopop-orchestrator/context-v/agent-skills/` | `adhoc-edits-workflow`, `manage-memo-citations`, `repair-memo-citations`, `setup-new-firm` | |
| `memopop-orchestrator/plugin/skills/` | `memopop` (the Claude Code plugin) | |
| `memopop-orchestrator/src/connector/skills/` (flat `.md`, served over MCP) | `change-the-outline-for-this-memo`, `compile-and-check-the-site`, `edit-wording`, `fix-a-source-or-citation`, `just-edit-the-memo`, `preview-a-memo`, `rewrite-a-section-from-its-research` | |
| `ai-labs/mcps/event-hog-mcp/kit/skills/` (served over MCP) | `capture-slides`, `conference-attendee-export`, `draft-follow-up-emails`, `maintain-design-system`, `parallel-content-generation-starters`, `prioritize-attendees`, `recreate-slides-in-brand` | `augment-speakers-panelists` |
| `ai-labs/dididecks-ai/context-v/agent-skills/` | `setup-new-dddecks-workspace` | **19 copies**: `astro-knots`, `changelog-conventions`, `context-vigilance`, `crawl-fetch-ingest`, `deck-iteration-workflow`, `generate-consistent-og-images`, `git-conventions`, `maintain-design-md`, `maintain-filemap`, `lossless-flavored-markdown`, `maintain-splash-pages`, `open-graph-share-seo-geo`, `overlay-svg-text`, `pseudomonorepos`, `remake-deck`, `search-lossless-corpus`, `slide-target`, `study-repos-first`, `theme-system` |
| `ai-labs/augment-it/context-v/agent-skills/` | `decile-hub-interface`, `inbox-curation`, `triage-inbox-w-suggestions` | |
| `ai-labs/hope-ai/context-v/agent-skills/` | `personal-strategic-plan` | |
| `astro-knots/context-v/agent-skills/` | `dependency-upgrade-loop`, `generate-site-design-variants` | |
| `astro-knots/mcps/astro-knots-mcp/skills/` (synced by `sync-skills.mjs`) | `knot-check`, `start-an-astro-knot` | 13 copies, generated |
| `astro-knots/sites/twf-next/.claude/skills/` | `port-legacy`, `port-survey`, `twf-bio`, `twf-claims`, `twf-copy`, `twf-design`, `twf-figures`, `twf-intake`, `twf-media`, `twf-portraits`, `twf-sources`, `twf-upscale`, `twf-water` (site-specific; `twf-claims` and `twf-design` also in `.agents/skills/`) | |
| `astro-knots/sites/fullstack-vc/public/downloads/skills/` | `create-html-breakout-highlights` (offered as a download) | |
| `fantasy-gm/context-v/agent-skills/` | `design-system`, `mobile-app` | |
| `self-host-stack/context-v/agent-skills/` | `custom-domain-cutover`, `decilehub-interface`, `vc-firm-profile-ingest` | |
| `self-host-stack/client-stacks/*/` | `twenty-interface` (palmer-ai and reach-edu, two copies) | `lossless-crm-interface-guidlines` (misspelled copy, lossless stack) |
| `~/.claude/skills/` only | `use-railway` (and a real-directory `graphify` that shadows the one in this repo) | |

Name collisions this turned up, each of which should become one skill:

- **Decile Hub, three ways:** `decile-hub-connector` (here), `decile-hub-interface`
  (augment-it), `decilehub-interface` (self-host-stack).
- **Design systems, five ways:** `maintain-design-md`, `maintain-design-system-page`,
  `maintain-design-system` (event-hog), `design-system` (fantasy-gm), and the
  `maintain-design-systems` candidate.
- **Twenty CRM, two ways:** `lossless-crm-interface-guidelines` and
  `twenty-interface`.

### 5. Proposed, not made

| Candidate | Source | Note |
|---|---|---|
| `lossless-loop` | `CANDIDATES.md` | The 5-phase lifecycle; stubbed in `pseudomonorepos/references/` |
| `fill-enrich-components-w-data` | `CANDIDATES.md` | Follow-up to `crawl-fetch-ingest` |
| `maintain-design-systems` | `CANDIDATES.md` | Overlaps the five design-system skills above |
| `astro-component-patterns` | `CANDIDATES.md` | Would go in the `astro-knots` pack |
| `lossless-house-style` | `CANDIDATES.md` | Voice and formatting; may overlap `talk-normal`, `humanizer` |
| `submodule-hygiene` | `CANDIDATES.md` | Wraps the existing reattach scripts |
| `monorepo-nav` | `CANDIDATES.md` | May fold into `pseudomonorepos` |
| `obsidian-integration` | `CANDIDATES.md` | Partly covered by `obsidian-vault-hygiene` |
| `profiles-doctype` | `CANDIDATES.md` | Probably a `context-vigilance` doc type, not a skill |
| `study-pattern` | `CANDIDATES.md` | Mostly shipped as `study-repos-first` |
| `inquiry-vs-explorations` | `CANDIDATES.md` | A reminder, not a skill |
| `flave-bundle` | `ai-labs/flave-ai/context-v/specs/Master-Flave-…` | Teaches the Flave bundle conventions; the spec says write it first |
| A router skill per pack | This exploration, "A way in" | One per pack once packs exist |
| Packs: `vc-skill-pack`, `event-skill-pack`, `lossless-dev`, `content-and-share` | This exploration, "A first pack map" | Only `astro-knots` is made |

`CANDIDATES.md` is stale: `lfm` shipped as `lossless-flavored-markdown`, and
most of what's listed in 1 and 4 isn't in its Promoted table.

### 6. Third-party, studied, not loaded

`astro-knots/context-v/skill-packs/seo-skills/` (30 skills, mined per
`THIRD-PARTY.md`), the 14 `speckit-*` skills spec-kit generated in augment-it,
and the skills inside upstream repos pinned in `ai-labs/studies/` and
`self-host-stack/core/`.

***

## One source, many spots

Section 4 shows that a skill doesn't live in two spots, it lives in up to six:
this repo, a product's `context-v/`, a Claude Code plugin, a folder an MCP
server serves (event-hog, astro-knots-mcp, MemoPop's connector), a site's
download page, and the harness's skills directory. The rule has to be **one
source of truth, any number of spots**, and the only spots that may hold a copy
are ones a script fills from the source and nobody edits by hand.
`astro-knots-mcp`'s `sync-skills.mjs` already works that way.

**There is no separate host for skills.** Every place that lists them indexes
git repos:

- **skills.sh / `npx skills`** (Vercel) installs from a GitHub repo, and
  `npx skills add <owner>/<repo> --skill <name>` takes one skill out of a repo
  that holds many.
- **A Claude Code plugin marketplace** is a repo with a
  `.claude-plugin/marketplace.json` listing as many plugins as you like, and a
  plugin's `source` can be a subdirectory of another repo (`git-subdir`).

So **packs don't each need a repo.** `lossless-agent-skills` can be the single
source *and* the marketplace: each pack a folder with its own `plugin.json`,
listed in one `marketplace.json`, installable on its own. Products then
install the pack (MemoPop's plugin depends on `vc-skill-pack`) or sync the
skills they serve from it at build time, instead of keeping copies. That is a
fourth option beside A, B and C above, cheaper than all three: **D, one repo,
packs as folders, every other spot generated.** It also means
`astro-knots-skills-pack` didn't have to be its own repo; it could fold back
into a folder here, with the submodule kept or dropped.

## Open questions

1. **Option B's owner rule.** When MemoPop needs `competitive-analysis`, does it
   mount all of `vc-skill-pack`, or does the plugin manifest list skills from
   another repo?
2. **Product packs vs. role packs.** Is MemoPop's plugin a pack of its own, or
   the VC pack plus MemoPop's MCP tools?
3. **Private config across a pack.** Several VC skills read firm particulars.
   Does a pack share one `config/private.json`, or one per skill?
4. **Naming and branding.** Do public packs carry the Lossless name, a product
   name (didi.sh), or neither?
5. **Who maintains the index.** Each pack keeps its own README; does this
   repo's README list packs by hand, or generate the list?
6. **Migration order.** `vc-skill-pack` first (the most duplication and the
   clearest outside audience), then `lossless-dev`?
7. **Option D.** Make this repo a plugin marketplace with packs as folders,
   and fold `astro-knots-skills-pack` back in? Or keep pack repos for packs a
   product mounts?
8. **What counts as a skill here.** Do the 18 `context-vigilance-kit` commands,
   MemoPop's connector playbooks and the `twf-*` site skills belong in the
   catalog, or stay with the products they serve?
