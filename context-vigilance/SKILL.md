---
name: context-vigilance
description: Lossless Group's framework for managing context-v/ directories in any project. Use whenever creating, updating, or organizing files in any context-v/ folder (specs, plans, prompts, blueprints, reminders, agent-skills, explorations, issues — plus the universal extra/ and sitemap/, and the experimental loops/, handoffs/, decisions/, and contracts/), or when the user asks about context engineering, AI co-development workflow, or the "context-v" convention. Enforces directory roles, the four-part epoch.major.minor.patch versioning, YAML frontmatter standard, wikilink cross-references, and the prep/reflective/journey cognitive modes.
---

# Context Vigilance

A framework for Human + AI collaboration: **manage the context available to AI and collaborators with the same rigor you manage code.** Every Lossless project has a `context-v/` directory with (commonly) eight subdirectories, organized into three cognitive modes: **Prep, Reflective, and Journey** — plus two universal utility folders and a small experimental tier still finding its shape.

**Norms, not rules.** Patterns here are loosely enforced. The team is generative-first; consistency emerges when attention focuses on a project, file, or pattern. Be generous reading existing files (they may pre-date current norms or be experiments) and careful writing new ones. See `references/philosophy.md` for the deeper rationale.

**Drift policy:** When you encounter inconsistencies (mismatched frontmatter, deviating filenames, partial-convention adoption), **observe, note, surface, but do not auto-fix as a side effect of unrelated work.** Cleanup happens only with explicit user permission. The user runs parallel agent sessions; silent normalization creates conflicts. (This rule lives globally in `~/.pi/agent/AGENTS.md`; restated here for redundancy.)

Reference: <https://www.lossless.group/projects/gallery/context-vigilance>

## When to use this skill

- The user asks you to create or edit any file under a `context-v/` directory
- The user mentions specs, prompts, blueprints, reminders, explorations, or issues in the Lossless sense
- Starting a new project and setting up `context-v/`
- The user asks about context engineering, AI co-development, or "the context-v thing"

## The Eight Directories

### Prep Mode (spec → plan → prompt)

The work of deciding what to build *is* the work — "prep" here is not "minor pre-work", it's the deliberate forward construction phase. Specs, plans, and prompts are the artifacts, in descending altitude.

- **`context-v/specs/`** — Living specifications. What you're building and why. Constantly updated. Single source of truth. Every prompt references a spec.
- **`context-v/plans/`** — Actionable work plans: sequenced, scoped, closer to execution than a spec but not yet the step-by-step of a prompt. The natural home for agent-produced plans (plan-mode output, migration sequences, refactor roadmaps). Promoted to canon 2026-07-21 after appearing organically in 14 repos — the most-adopted folder the original six didn't name.
- **`context-v/prompts/`** — Step-by-step, prompt-by-prompt implementation documents (NOT single chat messages). Each prompt references specs/plans/blueprints/reminders. Success at each step is verifiable before moving on.

> A prompt without a spec is a vibe. A prompt within a spec is engineering.

### Reflective Mode (blueprint ↔ reminder, plus agent-skills)

- **`context-v/blueprints/`** — Codified patterns, architecture decisions, proprietary thinking. Institutional knowledge AI needs to respect the system (e.g., "how our extended markdown flavor works", component organization, naming rationale).
- **`context-v/reminders/`** — Short, sharp corrections born from repeated AI mistakes (e.g., "We don't use React. Astro + Svelte for interactivity. Do not hard-validate frontmatter."). Battle scars turned into guardrails.
- **`context-v/agent-skills/`** — Per-repo agent skills following the Anthropic agent-skills shape (`<name>/SKILL.md` + optional `references/`, `templates/`, `scripts/`). This is the incubator: skills are born here next to the code they serve, and graduate to the shared public `lossless-agent-skills` repo (mounted at the anchor monorepo's `context-v/skills/`) once they prove out or apply beyond one repo. Reflective mode's executable tier — a blueprint an agent can *load and follow*, not just read.

### Journey Mode (unpaired)

- **`context-v/explorations/`** — Documents where the destination is unclear. Research, prototype tradeoffs, option-space mapping, thinking out loud with AI as partner. Ends when you've learned enough to write a spec — or decided you don't need one.
- **`context-v/issues/`** — Issue-resolution journey logs. The painful, winding path through debugging. Capture so no human or AI has to retrace it.

### Universal utility folders (any project, any mode)

Two folders that aren't doc-types so much as infrastructure, applicable to every project:

- **`context-v/extra/`** — Scratch and out-of-band material: half-thoughts, pasted transcripts, working files that aren't ready to be (or shouldn't become) real docs. **Gitignored by default** — add `context-v/extra/` to the repo's `.gitignore` when scaffolding. Corpus rollups and ingesters already exclude it by convention; the gitignore makes the privacy boundary structural rather than tooling-dependent.
- **`context-v/sitemap/`** — Maps of the project's own surfaces: pages, routes, slides, endpoints, screens — described as context docs so agents can reason about "what exists where" without crawling the source. First proven across the deck client-sites; applicable to any project with a navigable surface.

### Experimental tier (proposed, not yet consistent)

Folders the team is actively trialing. Their shape is **not settled** — expect variation between repos, and don't enforce consistency across them yet:

- **`context-v/loops/`** — Definitions of recurring operational loops: a loop's scope, cadence, per-iteration procedure, and exit conditions (e.g., a dependency-upgrade loop that fans out across sites until every build is green). Pairs naturally with agent loop-runners like Claude Code's `/loop` — the doc is the durable definition; the runner is the execution.
- **`context-v/handoffs/`** — Session-to-session handoff notes: the state of work captured at the end of a working session (what landed, what's mid-flight, what the next session must know) so a future session — human or agent, same person or a collaborator — resumes without re-derivation. The agentic-tooling world is converging on handoff documents as a primitive; this folder is where ours live.
- **`context-v/decisions/`** — Artifacts of clear decisions made: what was decided, when, by whom, and what alternatives were passed over. Supplements specs and plans by isolating the *decision itself* — a spec tells you the current state of intent, a decision doc tells you the moment intent changed and why. Kin to the industry's ADR (Architecture Decision Record) convention, but not limited to architecture.
- **`context-v/contracts/`** — Binding agreements, in two flavors that share one property: they are *not suggestions*. (1) **Constitution contracts** — standing rules agents must always follow, regardless of session, task, or model (invariants stronger than reminders: a reminder corrects drift, a contract defines the boundary of acceptable behavior). (2) **Interface contracts** — ironclad API-level documentation of how data must flow through the app or across a microservices architecture: schemas, payload shapes, ownership boundaries, who may write what. Where a blueprint explains *how the system is designed*, a contract states *what must never be violated*.

When creating either, follow the standard frontmatter baseline and note in the doc that the folder is experimental. When you see one shaped differently from this description, that's expected — surface the divergence, don't normalize it.

### When you find a folder outside the set

The set above is convention, not closed. Experimentation is normal — you'll encounter folders that don't match (observed in the wild: `narratives/`, `profiles/`, `inquiry/`, `models/`, `strategy/`, `notes/`, `research/`). Some are domain-specific and correct where they are: `narratives/` and `slides-content/` in deck workspaces, `profiles/` and `inquiry/` across the studies shelf. When you find one:

1. **Don't fight it.** Read what's there.
2. **Identify the cognitive mode** (planning / reflection / journey / something new).
3. **Discuss with the user** whether the folder should be assimilated (promoted to a new convention — the path `plans/` and `agent-skills/` took), folded (contents moved into an existing folder), or kept as project-specific.
4. **Default to keeping it** if unsure. Re-organizing someone's mental model mid-session is rude.

## Conventional Frontmatter

Frontmatter in `context-v/` is **scattered in practice** — some files have lots of properties, some have very few. When creating new files, lead with this baseline:

```yaml
---
title: "Human-readable title"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
authors:
  - Author Name
semantic_version: 0.0.0.1
tags:
  - Relevant-Tag
  - Another-Tag
---
```

When editing existing files, **respect what's there**. Don't add fields the file didn't have unless they're genuinely useful. Don't remove fields you don't recognize.

Key conventions (full details in `references/frontmatter-spec.md`):

- **All property names are `snake_case`** — enforced by Obsidian's frontmatter rendering. Never camelCase or kebab-case keys.
- Update `date_modified` whenever you edit the file
- `semantic_version` is **four-part `epoch.major.minor.patch`** — see `references/versioning.md`
- `authors` is **humans only**, always a list. AI agents are tracked separately under `augmented_with` (format: `Pi on Claude Sonnet 4.5`). See `references/frontmatter-spec.md`.
- `tags` use **Train-Case** values (e.g., `Markdown-Rendering`, `Issue-Resolution`) — Obsidian convention
- `status` uses **Train-Case** values too — it's a display string, not a machine enum
- `lede` (or `description`) is optional on any doc-type — a newsroom hook for preview cards / OG snippets / list views. **Keep it subtitle-length** (see *Lede length discipline* below).

## Lede length discipline

**The lede is a subtitle, not an abstract.** It's the single line a reader sees in a list view, a preview card, or an OpenGraph snippet before deciding to click. Its whole job is to make them want to keep reading — and a hook that runs long has stopped being a hook.

The rule: **one to (at most) a few sentences, never more than ~3 rendered lines.** If you can't say it in a subtitle, the lede isn't the place — the material belongs in the body.

When you feel the lede wanting to grow — to carry the full context, the journey, the stakes, the file inventory — that's the signal to **start a `## Why Care?` section directly under the title** (or an equivalent context/intro section) and put the long version there. The body is unbounded; the lede is not.

```
✅  lede: "The single org slot becomes an open-ended stack of affiliation
          cards — pick an org once instead of retyping it on every person."

❌  lede: "Yesterday the surface held one org per person, which was a lie about
          how careers work because people sit on boards and advise and change
          jobs and keep past titles, so tonight we … [200 more words]"
          ← this is a Why Care? section wearing a lede's clothes
```

This mirrors the audience cascade the `changelog-conventions` skill codifies: **lede = the two-second hook; `Why Care?` = the paragraph that earns the scroll.** Same discipline, every doc-type — specs, explorations, blueprints, issues.

## Status discipline

The `status:` field is the load-bearing signal of where a document sits in its lifecycle. A directory full of `status: Draft` plans, half of which actually shipped, is a directory you can't trust. **Status reflects reality** — promote it as work lands.

Canonical values (Train-Case display strings, not machine enums):

`Draft` → `In-Review` → `Signed-Off` → `Implementing` → `Shipped` · `Partially-Shipped` · `Deferred` · `Stale` · `Superseded` · `Archived`

Companion fields that must move with status:

- **`Shipped`** — set `date_first_published: YYYY-MM-DD`; optionally `post_ship_note:` for things learned after ship.
- **`Partially-Shipped`** — set `date_first_published:` for the first shipped slice; append a `## Remaining work (as of YYYY-MM-DD)` section enumerating what's done and what's left.
- **`Deferred`** — set `deferral_note:` explaining the named reason.
- **`Superseded`** — set `superseded_by: [[Successor-Doc]]`.

In every case, bump `date_last_updated` (or `date_modified`) on the same edit. Status changes are meaningful edits.

**When to update:** when you ship a substantial portion, defer explicitly, supersede, or notice the field doesn't match reality during a sweep.

**When NOT to update:** mid-session as a side effect of unrelated work (drift policy — surface, don't silently normalize); for docs authored by someone else whose ship state you're not sure about (ask first); as a way to "tidy up" without a real ship event to point at.

Full reference: `references/status-discipline.md`. The periodic sweep procedure: `lossless-monorepo/context-v/habits/Maintain-Status-Discipline-Across-Context-V-Files.md`.

## Cross-references

Cross-referencing is how humans and agents focus on a limited scope at any moment — **humans have context windows too.** Three styles, all valid:

1. **Obsidian-style backlinks (preferred):** `[[path/to/Filename.md]]` or `[[Filename]]`
2. **Standard Markdown links:** `[link text](../specs/Some-Spec.md)`
3. **Backtick paths:** `` `context-v/specs/Some-Spec.md` `` for references the reader isn't expected to click

Use whichever serves the reader. Backlinks are preferred because most `context-v/` directories are symlinked into Obsidian vaults, where `[[wikilinks]]` unlock graph view, autocomplete, and backlink panes.

Common linking patterns:

- prompts → link the spec they implement
- reminders → link the blueprint that explains the pattern
- explorations & issues → link whatever they relate to

## Audience: User + Agent + Reader

Almost everything in `context-v/` is destined for public web publishing through one of the Lossless [Astro Knots](https://www.lossless.group/projects/gallery/astro-knots) sites. So every document balances three audiences:

1. **The User** writing or editing it
2. **The Agent** that will load it as context in some future session
3. **The Reader** who lands on it on the web with no prior context

Practical implications:

- **Lead with marketing. Lead with why. Lead with something anyone can understand.** Get into technical detail deeper in the doc.
- **The first paragraph should be readable by an outsider.** The rest can be specialized.
- **Fork early; don't wait for "too long."** Long-context-window models (Opus 4.7 with 1M tokens, etc.) can technically ingest huge documents — but **creativity, cross-referencing, and human-agent cooperation all degrade as a single doc grows**, regardless of what the model can accept. The trigger to split is *anxiety about length*, not a word count: when you (or the user) notice you're scrolling past sections to reach the one that matters, that's the cue. The practice is **fork-and-cross-reference**, not "split when forced." Pre-emptively factor self-contained sub-systems into sibling specs, reusable patterns into blueprints, and specific debugging journeys into issues — each linked from the parent. The parent doc keeps the *map*; the children carry the *detail*. See `references/philosophy.md` for the longer rationale.
- **Common split shapes when forking:** marketing/why stays at the top (or its own short doc), pattern/architecture → blueprint, thing-being-built → spec, how-to-build-it → prompt. Whatever fits.

## Filename conventions

Use **Train-Case** for filenames: `Train-Case.md`. Same convention as tags. Matches existing examples like `When-Claud-Code-and-When-Pi.md`, `Migrating-Study-to-its-own-Pseudomonrepo.md`.

## Decision tree: which folder?

- Defining what to build, with criteria & scope? → **specs/**
- Sequenced, scoped work plan (plan-mode output, roadmap, migration sequence)? → **plans/**
- Step-by-step implementation prompts referencing a spec or plan? → **prompts/**
- Capturing how/why a system is designed (pattern, architecture)? → **blueprints/**
- Short correction the AI keeps needing? → **reminders/**
- Executable know-how an agent should load and follow (SKILL.md shape)? → **agent-skills/**
- Don't know the answer yet, need to research/weigh options? → **explorations/**
- Debugging a specific painful problem and capturing the path? → **issues/**
- Scratch, pasted transcripts, not-a-doc-yet material? → **extra/** (gitignored)
- Mapping the project's own pages/routes/slides/surfaces? → **sitemap/**
- Recurring operational loop definition? → **loops/** (experimental)
- End-of-session state capture for the next session or a collaborator? → **handoffs/** (experimental)
- Isolated record of a decision made — what, when, why, alternatives passed over? → **decisions/** (experimental)
- Inviolable rule — agent constitution or ironclad data-flow/API contract? → **contracts/** (experimental)

When in doubt, see `references/doc-type-guide.md`.

## Templates

When creating a new file, start from the matching template in `templates/`:

- `templates/spec.md`
- `templates/prompt.md`
- `templates/blueprint.md`
- `templates/reminder.md`
- `templates/exploration.md`
- `templates/issue.md`

## Typical flow for a `context-v/` task

Not a checklist — a default rhythm. Adjust to the situation.

1. **Locate the project's `context-v/`.** Walk up from cwd if needed. Some repos have multiple (e.g., one per sub-project).
2. **Survey what's there.** Look at sibling files for tone, depth, and frontmatter conventions. Match them.
3. **Pick the folder** using the decision tree. If nothing fits, see *When you find a folder outside the set* above.
4. **Copy the matching template** from `templates/` if helpful, or write from scratch matching nearby files.
5. **Frontmatter:** today's date for both `date_created` and `date_modified`. Start at `0.0.0.1`. Add the user as author. If you (an AI) contributed materially, add yourself under `augmented_with` (e.g., `Pi on Claude Sonnet 4.5`) — not under `authors`.
6. **Lead with the why.** First paragraph readable by an outsider.
7. **Cross-link** to related docs using `[[wikilinks]]`.
8. **Filename & tags:** Train-Case (`My-New-Doc.md`, tags like `- New-Pattern`).
9. **When editing an existing doc:** bump `semantic_version` per `references/versioning.md` and update `date_modified`. Respect existing frontmatter shape.
10. **If the doc is ballooning, propose a split** before continuing. Better two clean docs than one bloated one.

## Developing a spec (the rich case)

Specs have more rhythm than the other doc-types: stub-first, discuss-then-write, handle stale prior art without hijacking the primary dialog, sign-off gate before implementation, narrative pass *after* sign-off, and pair with prompts for chunked execution. The full rhythm lives in `references/developing-a-spec.md` — load it whenever you're initiating or developing a spec with the user.

## The philosophy (tl;dr)

- AI doesn't learn between sessions → externalize memory as loadable docs
- Context windows have limits (humans too) → modular docs designed for selective loading and cross-linking
- Specs align everyone again, better → AI makes specs cheap to write and cheaper to keep current
- We publish in public → docs serve users, agents, and outside readers simultaneously
- Norms over rules → generative first, consistency emerges with attention

For the deeper version, see `references/philosophy.md`.
