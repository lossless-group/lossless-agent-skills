# Astro Knots skill pack

Skills for building Astro sites the way The Lossless Group does: the stack and
its prohibitions, themes and modes, markdown, splash pages, share images and
metadata, analytics, and brand marks.

| Skill | Use it when |
|---|---|
| [`astro-knots`](./skills/astro-knots/) | Starting or changing any Astro site: the tech hierarchy, approved frameworks, and what never to install |
| [`theme-system`](./skills/theme-system/) | Setting up tokens and the light, dark and vibrant modes |
| [`maintain-design-md`](./skills/maintain-design-md/) | Writing or updating a site's `DESIGN.md` |
| [`lossless-flavored-markdown`](./skills/lossless-flavored-markdown/) | Authoring or rendering content with LFM |
| [`maintain-splash-pages`](./skills/maintain-splash-pages/) | Building a repo's `splash/` site on GitHub Pages |
| [`generate-consistent-og-images`](./skills/generate-consistent-og-images/) | Making share images that look like one family |
| [`open-graph-share-seo-geo`](./skills/open-graph-share-seo-geo/) | Getting links to unfurl, plus sitemaps, robots and `llms.txt` |
| [`openpanel-analytics`](./skills/openpanel-analytics/) | Adding or debugging OpenPanel |
| [`trademark-packs-files`](./skills/trademark-packs-files/) | Making a site's favicon, appIcon, wordmark, trademark and `favicon.ico` |

## Layout

Each skill sits at `skills/<name>/SKILL.md`, the shape a pack will keep if it
moves to its own repo (see `context-v/explorations/Organize-Our-Skills-into-Skill-Packs.md`
at this repo's root). Harnesses still see each skill by its bare name:
`sync-skills-symlinks.sh` links `~/.claude/skills/<name>` straight to the
skill's folder, so a pack changes where a skill lives, not what it's called.

## Where else it appears

The [Astro Knots MCP](https://github.com/lossless-group/astro-knots-mcp)
copies most of these skills into its `skills/` folder with `pnpm sync-skills`,
so its Claude Code and Codex plugins ship them. Edit them here, never there.
