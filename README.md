# Pi Skills — mpstaton

Personal [pi-coding-agent](https://github.com/badlogic/pi-mono) skills, kept under version control so they sync across machines and have a history.

This directory is the global pi skills location: `~/.pi/agent/skills/`. Pi loads every subdirectory containing a `SKILL.md` on startup.

## Skills

| Skill | Purpose |
|---|---|
| [`context-vigilance/`](./context-vigilance/) | Lossless Group's framework for managing `context-v/` directories (specs, prompts, blueprints, reminders, explorations, issues) with four-part `epoch.major.minor.patch` versioning and Train-Case conventions. |

## Layout convention

```
<skill-name>/
├── SKILL.md              # required: frontmatter (name, description) + instructions
├── references/           # deep-dive docs the agent loads on demand
└── templates/            # scaffolds for new files
```

See the [Agent Skills spec](https://agentskills.io/specification) and [pi skills docs](https://github.com/badlogic/pi-mono/blob/main/packages/pi-coding-agent/docs/skills.md).

## Working with this repo

```bash
cd ~/.pi/agent/skills

# After editing a skill:
git add <skill>
git commit -m "skill(<name>): <change>"
git push

# In an active pi session, pick up changes without restarting:
# /reload
```

## Sharing with Claude Code / Codex

Pi follows the Agent Skills standard, so these skills work in other harnesses. To share, either:

1. Symlink: `ln -s ~/.pi/agent/skills ~/.agents/skills`
2. Or add to your other tool's settings to read this directory.

## Adding a new skill

1. `mkdir <skill-name>` (lowercase, hyphens, matches `name:` in frontmatter)
2. Create `SKILL.md` with required frontmatter:
   ```yaml
   ---
   name: <skill-name>
   description: When the agent should load this skill. Be specific.
   ---
   ```
3. Optional: `references/` for deep docs, `templates/` for scaffolds, `scripts/` for helpers
4. `/reload` in pi or restart
5. Commit
