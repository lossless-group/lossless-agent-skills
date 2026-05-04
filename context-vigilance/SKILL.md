---
name: context-vigilance
description: Lossless Group's framework for managing context-v/ directories in any project. Use whenever creating, updating, or organizing files in any context-v/ folder (specs, prompts, blueprints, reminders, explorations, issues), or when the user asks about context engineering, AI co-development workflow, or the "context-v" convention. Enforces directory roles, the four-part epoch.major.minor.patch versioning, YAML frontmatter standard, wikilink cross-references, and the planning/reflection/journey cognitive modes.
---

# Context Vigilance

A framework for Human + AI collaboration: **manage the context available to AI and collaborators with the same rigor you manage code.** Every Lossless project has a `context-v/` directory with up to six subdirectories, organized into three cognitive modes.

Reference: <https://www.lossless.group/projects/gallery/context-vigilance>

## When to use this skill

- The user asks you to create or edit any file under a `context-v/` directory
- The user mentions specs, prompts, blueprints, reminders, explorations, or issues in the Lossless sense
- Starting a new project and setting up `context-v/`
- The user asks about context engineering, AI co-development, or "the context-v thing"

## The Six Directories

### Planning Mode (paired: spec ↔ prompt)

- **`context-v/specs/`** — Living specifications. What you're building and why. Constantly updated. Single source of truth. Every prompt references a spec.
- **`context-v/prompts/`** — Step-by-step, prompt-by-prompt implementation documents (NOT single chat messages). Each prompt references specs/blueprints/reminders. Success at each step is verifiable before moving on.

> A prompt without a spec is a vibe. A prompt within a spec is engineering.

### Reflective Mode (paired: blueprint ↔ reminder)

- **`context-v/blueprints/`** — Codified patterns, architecture decisions, proprietary thinking. Institutional knowledge AI needs to respect the system (e.g., "how our extended markdown flavor works", component organization, naming rationale).
- **`context-v/reminders/`** — Short, sharp corrections born from repeated AI mistakes (e.g., "We don't use React. Astro + Svelte for interactivity. Do not hard-validate frontmatter."). Battle scars turned into guardrails.

### Journey Mode (unpaired)

- **`context-v/explorations/`** — Documents where the destination is unclear. Research, prototype tradeoffs, option-space mapping, thinking out loud with AI as partner. Ends when you've learned enough to write a spec — or decided you don't need one.
- **`context-v/issues/`** — Issue-resolution journey logs. The painful, winding path through debugging. Capture so no human or AI has to retrace it.

## Mandatory Frontmatter

Every document under `context-v/` starts with this YAML frontmatter:

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

Key rules (full details in `references/frontmatter-spec.md`):

- Update `date_modified` whenever you edit the file
- `semantic_version` is **four-part `epoch.major.minor.patch`** — see `references/versioning.md`
- `authors` is always a list, even with one author. Add yourself when you co-author (use the model name, e.g., "Claude Sonnet 4.5")
- `tags` use **Train-Case** (e.g., `Markdown-Rendering`, `Issue-Resolution`) — Obsidian convention

## Cross-references

Use `[[wikilinks]]` to reference other `context-v/` documents. Prefer:

- prompts → link the spec they implement
- reminders → link the blueprint that explains the pattern
- explorations & issues → link whatever they relate to

## Filename conventions

Use **Train-Case** for filenames: `Train-Case.md`. Same convention as tags. Matches existing examples like `When-Claud-Code-and-When-Pi.md`, `Migrating-Study-to-its-own-Pseudomonrepo.md`.

## Decision tree: which folder?

- Defining what to build, with criteria & scope? → **specs/**
- Step-by-step implementation plan referencing a spec? → **prompts/**
- Capturing how/why a system is designed (pattern, architecture)? → **blueprints/**
- Short correction the AI keeps needing? → **reminders/**
- Don't know the answer yet, need to research/weigh options? → **explorations/**
- Debugging a specific painful problem and capturing the path? → **issues/**

When in doubt, see `references/doc-type-guide.md`.

## Templates

When creating a new file, start from the matching template in `templates/`:

- `templates/spec.md`
- `templates/prompt.md`
- `templates/blueprint.md`
- `templates/reminder.md`
- `templates/exploration.md`
- `templates/issue.md`

## Steps for any context-v/ task

1. **Locate the project's `context-v/`.** Walk up from cwd if needed. Some repos have multiple (e.g., one per sub-project).
2. **Pick the folder** using the decision tree above.
3. **If the folder doesn't exist, create it** — don't ask, just make it. The framework expects all six.
4. **Copy the matching template** from `templates/` and fill it in.
5. **Frontmatter:** today's date for both `date_created` and `date_modified`. Start at `0.0.0.1`. Add the user as author; add yourself if you wrote substantial content.
6. **Add `[[wikilinks]]`** to related docs.
7. **Filename & tags:** Train-Case (`My-New-Doc.md`, tags like `- New-Pattern`).
8. **When editing an existing doc:** bump `semantic_version` per `references/versioning.md` and update `date_modified`.

## The philosophy (tl;dr)

- AI doesn't learn between sessions → externalize memory as loadable docs
- Context windows have limits → modular docs designed for selective loading
- Specs align everyone again, better → AI makes specs cheap to write and cheaper to keep current
- This scales to teams → a `context-v/` answers "where's the context?" before it's asked
