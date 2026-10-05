# Vendored: graphify

This skill is upstream's, copied verbatim. Don't edit `SKILL.md` or `references/` here.
Fix problems upstream, or record them in this file.

| | |
|---|---|
| Upstream | [`safishamsi/graphify`](https://github.com/safishamsi/graphify) (MIT, see `LICENSE`) |
| Package | `graphifyy` on PyPI, which provides the `graphify` CLI the skill drives |
| Version | `0.9.32` (also in `.graphify_version`) |
| Vendored | 2026-10-05, from the output of `graphify install` |

## Why a copy and not a submodule

Archify and Chroma are submodules because their repos contain a ready `SKILL.md`
folder. Graphify's doesn't. The skill ships inside the Python package as
`graphify/skill.md` (plus a variant per harness), and `graphify install` writes it
out as `SKILL.md` and `references/`. That installed output is what lives here.

## The skill needs the CLI

The skill shells out to `graphify`. Its Step 1 finds or installs the package
(`uv tool`, then `pipx`, then `pip`). Keep the package and this copy on the same
version: a newer CLI under an older `SKILL.md` can drift.

## Refreshing

```bash
uv tool upgrade graphifyy        # or: uv tool install graphifyy
graphify install                 # rewrites ~/.claude/skills/graphify
cp -R ~/.claude/skills/graphify/{SKILL.md,references,.graphify_version} <this-dir>/
```

Then update the version above and add a changelog entry.

## Links on a machine where graphify was installed first

`graphify install` creates `~/.claude/skills/graphify` as a real directory. The sync
script never replaces a non-symlink, so that copy keeps loading. That's fine while
both are on the same version. To load this copy instead, move the installed one
aside and re-run the sync. Note that a later `graphify install` would then write
through the link into this repo.
