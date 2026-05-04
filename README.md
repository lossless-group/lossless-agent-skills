# Lossless Skills

The Lossless Group's agent skills collection — across projects and people.

A shared library of [Agent Skills](https://agentskills.io/specification) used by Lossless team members and AI coding agents on Lossless projects. Skills here are tool-agnostic: they work with [pi-coding-agent](https://github.com/badlogic/pi-mono), Claude Code, OpenAI Codex, and anything else that follows the Agent Skills standard.

## Skills

| Skill | Purpose |
|---|---|
| [`context-vigilance/`](./context-vigilance/) | Lossless Group's framework for managing `context-v/` directories (specs, prompts, blueprints, reminders, explorations, issues) with four-part `epoch.major.minor.patch` versioning and Train-Case conventions. See <https://www.lossless.group/projects/gallery/context-vigilance>. |

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

MIT (see [LICENSE](./LICENSE)) — to be added.
