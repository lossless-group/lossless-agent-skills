# The Philosophy Behind Context Vigilance

Read this when you need the *why* behind the patterns, not just the patterns themselves.

## Why `context-v/` exists at all

AI co-development is a massive productivity unlock and a massive source of frustration. Every AI session starts from zero. Vibe coding produces spaghetti. Without externalized memory, you're trapped in an endless cycle of re-explaining your project to every new session, every collaborator, every model.

`context-v/` is the answer: turn institutional knowledge into loadable artifacts that survive session boundaries and serve humans, agents, and outside readers simultaneously.

## The cognitive modes

The framework isn't six folders for the sake of six. It's two paired cognitive modes plus a journey mode:

- **Planning** (specs ↔ prompts): forward motion. *"What shall we build and how?"*
- **Reflection** (blueprints ↔ reminders): backward motion. *"What have we learned and how do we keep doing it well?"*
- **Journey** (explorations, issues): exploratory motion. *"We don't know where this ends yet."*

Most development activity falls into one of these. When something doesn't fit, that's interesting — discuss it, give it a folder, see if it earns assimilation.

## Six is not the answer

The six are convention, not law. Teams experiment. Folders show up that no one planned for (`notes/`, `decisions/`, `changelog/`, `plans/`, `research/`, etc.). When you encounter one:

1. Ask what kind of cognitive activity it represents
2. Discuss whether it deserves to be a new norm or merge into an existing one
3. Either **assimilate** (promote to convention) or **fold** (move contents into one of the six)
4. **Default to keeping it** if unsure. Reorganizing someone's mental model mid-session is rude.

The framework matters more than the count.

## Audience: User + Agent + Reader

Almost everything in `context-v/` is destined for the public web through one of the Lossless [Astro Knots](https://www.lossless.group/projects/gallery/astro-knots) sites. Every doc therefore balances three audiences:

1. **The User** writing or editing it (the project owner, today)
2. **The Agent** that will load it as context in some future session
3. **The Reader** who finds it on the web with no prior context

Practical implications:

- **Lead with marketing. Lead with why. Lead with something everyone can understand.** Get into technical detail deeper in the doc.
- The first paragraph should be readable by an outsider. The rest can be specialized.
- If a doc is getting too long, **split it**. Common splits:
  - Marketing/why → top of doc, or its own short doc
  - Pattern/architecture → blueprint
  - Thing being built → spec
  - How-to-build-it → prompt

  Whatever fits. The split is a feature, not a failure.

## Cross-references and human context windows

Humans have context windows too. Cross-referencing lets both humans and agents focus on a limited scope at any moment.

- Obsidian-style backlinks (`[[wikilinks]]`) are preferred — most `context-v/` directories are symlinked into Obsidian vaults, where they unlock graph view and backlink panes.
- Standard Markdown links work fine.
- Backtick paths (`` `context-v/specs/X.md` ``) are appropriate when you don't expect the reader to click.

The goal isn't link consistency. It's **scope discipline**: each doc should fit in one head (or one context window) at a time.

## On consistency vs. generativity

The team is generative-first. Consistency emerges when attention focuses on a project, file, or pattern. These are in tension. The way to resolve it:

- **Be generous reading existing files.** Don't demand they conform to current conventions. They might be older, experimental, or written under different assumptions.
- **Be thoughtful writing new ones.** Match conventions when you know them, ask when you don't.
- **When you notice drift, surface it.** Open an issue, write a blueprint, draft a reminder. Don't silently re-impose your preferences across a codebase.

## On Obsidian as substrate

Many `context-v/` directories are symlinked into Obsidian vaults so contributors can edit with backlinks, graph view, and full-text search. This is why:

- Filenames and tags use Train-Case (Obsidian's tag handling is finicky)
- Cross-references prefer `[[wikilinks]]`
- Frontmatter is YAML with optional `aliases`

But the files are still plain Markdown. They render fine in any editor, on the web, and to any agent that can read text.

## On rules vs. norms

There are no hard rules in this framework. There are norms with rationale.

If a norm isn't working for you on a specific doc, **break it**. But document why — in the doc itself or in a new exploration. The next person (human or AI) will learn from your deviation. That's how the framework evolves.

## On building in public

This skill, the `context-v/` framework, and most of the institutional knowledge it captures are developed openly as part of [The Lossless Group's "Lost in Public"](https://www.lossless.group/lost-in-public) practice. Imperfect docs in public beat perfect docs in private. If you find a sharper way to express something here, propose the change. If you disagree with a convention, surface it.
