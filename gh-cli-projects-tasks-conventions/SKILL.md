---
name: gh-cli-projects-tasks-conventions
description: How The Lossless Group uses the `gh project` CLI (GitHub Projects v2) to manage tasks across the pseudomonorepo tree. Use whenever creating, editing, or listing GitHub Project tasks via `gh project item-create`, `gh project item-add`, or `gh project item-edit`; whenever the user mentions "gh project", "create a task", "add to the project", "draft a project item", "ProjectV2", or asks to script project task creation; whenever an agent is about to author a task body that references one or more `context-v/` files. Encodes the **task-body-is-a-github-link** convention — every task whose work-context lives in a `context-v/` file gets a body whose primary content is a clickable GitHub URL to that file in its own repo (NOT a deep path inside the parent monorepo, because each pseudomonorepo level is its own git repo and the URL must respect that). Composes with the `pseudomonorepos` skill to identify which repo a local context-v path belongs to and which branch tier (`development` / `main` / `master`) the link should target.
---

# gh CLI · Projects & Tasks Conventions

> **Premature on purpose — 2026-06-05.** We don't yet have many preferences. The two that exist are codified here so they don't drift in the meantime: (1) compose with [[pseudomonorepos]] to figure out which repo a local path actually lives in; (2) every task body that points at a `context-v/` file points at it via a clickable GitHub URL. As more conventions emerge (status field discipline, priority discipline, custom-field schemas, project-per-app vs project-per-engagement), they get added here.

## When to use this skill

- Creating, editing, or listing GitHub Project tasks via `gh project` — particularly `item-create`, `item-add`, `item-edit`.
- The user says "create a task," "add to the project," "draft a project item," "set up a project," "gh project," or any variant.
- An agent is about to author a task body that references one or more `context-v/` files anywhere in the pseudomonorepo tree.
- Scripting bulk task creation from a spec, exploration, or plan that has sections / decisions / placeholders worth tracking.

## Compose with `pseudomonorepos`

This skill assumes [[pseudomonorepos]] is in context. The tree-walking discipline there is what makes the link-building behavior below correct: a `context-v/` file at `/Users/mpstaton/code/lossless-monorepo/ai-labs/context-v/explorations/X.md` does **not** live in the `lossless-monorepo` repo on GitHub — it lives in the `ai-labs` repo, which is submoduled. The link convention below depends on resolving the right repo before building the URL.

If you don't load `pseudomonorepos` first, you will produce links that look right (`github.com/lossless-group/lossless-monorepo/blob/development/ai-labs/context-v/...`) but 404, because that path doesn't exist in the parent repo — only the submodule pointer does.

## The behavioral core (this is the actual skill)

### Convention 1 — Task bodies that reference `context-v/` files use GitHub URLs

When a task's work-context is "go read these context-v files and act on them," the **body of the task is, primarily, the GitHub link(s) to those files**. Not a copy-pasted summary. Not a path the collaborator has to translate manually. A clickable URL that lands them in the right file in the right repo on the right branch.

**Why:** project items are read by collaborators who may not have the full tree cloned. They click. The click has to work. A correct link is the difference between "I'll get to it" and "where is this." A wrong link silently rots the trust the project list is supposed to build.

**Body shape, default:**

```markdown
Context:
- [<file title or relative path>](<github URL to file in its own repo on its own branch>)
- [<another file>](<URL>)

<optional one-line ask if the title doesn't make the ask obvious>
```

That's it for the default. The link is the whole point. Add prose only when the file title doesn't convey what the work is.

### Convention 2 — Building the URL correctly

Given a local path `/Users/mpstaton/code/lossless-monorepo/<some-sub-path>/context-v/<rest>/<file>.md`, the URL is **not** built by string-substitution on the parent path. It is built by asking the **repo that actually owns the file** for its remote and branch.

Recipe:

```bash
# Given LOCAL_PATH = an absolute path to a context-v file
DIR=$(dirname "$LOCAL_PATH")
cd "$DIR"

# 1. Find the git root of the repo that owns this file (NOT the parent monorepo)
REPO_ROOT=$(git rev-parse --show-toplevel)

# 2. Get its origin remote (the GitHub URL of the repo this file is in)
REMOTE=$(git remote get-url origin)
# Normalize: git@github.com:owner/repo.git or https://github.com/owner/repo.git → owner/repo
OWNER_REPO=$(echo "$REMOTE" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')

# 3. Get the current branch on that repo (NOT the parent's branch — they may differ)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 4. Compute the file's path relative to the repo root
REL_PATH=$(realpath --relative-to="$REPO_ROOT" "$LOCAL_PATH")

# 5. Assemble
URL="https://github.com/${OWNER_REPO}/blob/${BRANCH}/${REL_PATH}"
echo "$URL"
```

The `cd "$DIR"` and `git rev-parse --show-toplevel` together do the work of "which repo am I actually in" — submodules report their own root, not the parent's. That's the entire point.

**On macOS, `realpath --relative-to` requires coreutils** (`brew install coreutils` then `grealpath`, or use Python: `python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$LOCAL_PATH" "$REPO_ROOT"`).

### Convention 3 — Branch tier (per [[pseudomonorepos]])

The branch the URL targets must match the **branch tier** of the work the task represents:

- Active work in motion → `development` (default).
- Cohesive shipped chunk → `main`.
- Settled stable surface → `master`.

The recipe above uses `git rev-parse --abbrev-ref HEAD` because the file's own repo is presumably checked out at the tier the work is happening on. If you're scripting from a stale checkout, override `BRANCH` explicitly.

**Do not** default to `main` blindly because it's GitHub's default. The pseudomonorepo tree's default tier for in-motion work is `development`. A link to `main` for a draft spec produces a 404 (the spec is on `development`, hasn't been promoted yet).

### Convention 4 — One link per relevant file, not summary-replaces-link

If a task pulls from three files, the body lists three links. Do **not** synthesize one prose paragraph that "summarizes" all three; that creates a second source of truth that immediately drifts from the files themselves. The whole point of the link is that the file is the source. The body is a pointer set, not a recap.

### Convention 5 — When the work is itself authoring a new context-v file

If the task is "write a new `context-v/` file," the link can't exist yet. In that case:

- **Title:** name the file you intend to create, exactly (Train-Case, `.md` extension implied).
- **Body:** list the prior-art files that the new file will inherit from, as links per Convention 1. Optionally add a one-line "Lands at: `<intended-repo>/<intended-path>`".

When the file is later created, edit the task to add the actual link.

## Practical `gh project` recipes

### Look up the IDs you'll need (one-time per project)

```bash
OWNER=lossless-group
PNUM=<project number from the URL>

# Project node ID + field metadata
gh project view "$PNUM" --owner "$OWNER" --format json | jq '.id'
gh project field-list "$PNUM" --owner "$OWNER" --format json
```

Cache the project ID, the `Status` field ID, and the option IDs for `Todo`/`In Progress`/`Done` in script variables. They don't change.

### Create a single task that points at a context-v file

```bash
# (URL produced via the recipe above)
URL="https://github.com/lossless-group/ai-labs/blob/development/context-v/explorations/Cloud-Variant-of-Dididecks-AI-Workspace.md"

ITEM_ID=$(gh project item-create "$PNUM" --owner "$OWNER" \
  --title "Close Decision 1 (architectural shape) on Cloud-Workspace spec" \
  --body  "Context:
- [Cloud-Variant-of-Dididecks-AI-Workspace.md]($URL)" \
  --format json | jq -r .id)
```

### Bulk-create tasks from sections of a spec

A common shape: a spec stub has N placeholder sections each marked `[awaits discussion]`. One task per section, each body linking to the spec.

```bash
SPEC_URL="https://github.com/lossless-group/dididecks-ai/blob/development/context-v/specs/Cloud-Workspace-for-Dididecks.md"

# Array of (title, anchor) pairs — anchor is the section's GitHub anchor (slugified)
declare -a TASKS=(
  "Fill in Section 1: Privacy-property contract|#1-privacy-property-contract--awaits-discussion"
  "Fill in Section 4: Threat model and mitigations|#4-threat-model-and-mitigations--awaits-discussion"
  "Fill in Section 5: Network and runtime topology|#5-network-and-runtime-topology--awaits-discussion"
)

for entry in "${TASKS[@]}"; do
  TITLE="${entry%%|*}"
  ANCHOR="${entry##*|}"
  gh project item-create "$PNUM" --owner "$OWNER" \
    --title "$TITLE" \
    --body  "Context:
- [Cloud-Workspace-for-Dididecks.md → $TITLE](${SPEC_URL}${ANCHOR})"
done
```

GitHub auto-generates section anchors as kebab-cased slugs of the heading text. Verify the anchor by opening the file on GitHub and clicking the link icon next to the section heading — it produces the canonical anchor.

### Add an existing issue (not a draft) to the project

```bash
gh project item-add "$PNUM" --owner "$OWNER" \
  --url https://github.com/lossless-group/dididecks-ai/issues/42
```

Use this when the work is concrete enough to be a tracked issue with its own discussion, labels, and assignees. Draft items via `item-create` are for tasks that don't deserve repo-level discussion overhead.

### Set Status (or any single-select field)

```bash
PROJECT_ID="PVT_..."           # from gh project view
STATUS_FIELD_ID="PVTSSF_..."   # from gh project field-list
TODO_OPTION_ID="..."           # from the same field-list, under .fields[].options[]

gh project item-edit \
  --id "$ITEM_ID" \
  --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --single-select-option-id "$TODO_OPTION_ID"
```

Field IDs are GraphQL node IDs (long opaque strings). Fetch once with `field-list --format json`, cache in the script.

## Auth

```bash
gh auth status                # confirm token has 'project' scope
gh auth refresh -s project    # add the scope if missing
```

The `project` scope is separate from `repo`. A token that creates issues fine may still 403 on `gh project` calls until refreshed.

## When `gh project` isn't enough

Anything `gh project` doesn't expose (custom field schemas, complex field updates in one call, project iteration / views) is reachable via the same auth with raw GraphQL:

```bash
gh api graphql -F query='
  query($org: String!, $num: Int!) {
    organization(login: $org) {
      projectV2(number: $num) {
        id
        title
        fields(first: 20) { nodes { ... on ProjectV2FieldCommon { id name } } }
      }
    }
  }
' -F org="$OWNER" -F num="$PNUM"
```

Same token, more flexibility. Don't reach for it until `gh project` actually fails — the CLI is easier to read in a script.

## Anti-patterns

**Don't point a project task at the parent monorepo path of a submodule file.** `github.com/lossless-group/lossless-monorepo/blob/.../ai-labs/context-v/...` does NOT exist on GitHub — the parent only has a submodule pointer at `ai-labs`, not the file tree. The link 404s. Use the child repo's own URL.

**Don't paste a long prose summary into the task body and skip the link.** The collaborator can read the file. The body's job is to send them to it.

**Don't use the wrong branch in the URL.** The default tier for in-motion work is `development`, not `main`. Build the URL from the repo's actual current branch, not from convention.

**Don't `gh project item-create` for work that genuinely belongs as a repo issue.** Draft items are for "tasks at the project layer that don't need their own labels / assignees / repo-level discussion." If reviewers need to comment, if there's a PR coming, if there are CI checks — make an issue first (`gh issue create`), then `gh project item-add`.

**Don't lose track of the project ID and field IDs.** Every `item-edit` needs them. A `.env`-style file at the project's working directory (`PROJECT_ID=…`, `STATUS_FIELD_ID=…`, `TODO_OPTION_ID=…`) is fine; just don't re-fetch them on every call.

**Don't auto-bump project status as a side effect of merging code.** That's [[git-conventions]]-adjacent and belongs in deliberate post-merge updates, not in workflow magic. (Provisional rule; may evolve.)

## After authoring or editing this skill

Per [[../../AUTHORING.md]]:

```bash
bash sync-skills.sh
```

This is **not** automatic. Both Claude Code and Pi need per-skill symlinks at `~/.claude/skills/<name>/SKILL.md` and `~/.pi/skills/<name>/SKILL.md`. The script handles that; running it is the human (or agent) step.

## Open seams (future preferences likely to live here)

Listed so they're visible as the skill grows:

- Status discipline — when a project item moves from Todo → In Progress → Done, who moves it and based on what signal.
- Priority discipline — if/when we add a Priority field, what `P0 / P1 / P2` mean concretely.
- Project layout — one project per app vs one per engagement vs one per quarter. Currently undecided.
- Custom field conventions — Repo, Engagement, Type, etc.
- Iteration / sprint conventions — if we adopt them.
- Cross-app project rollups — if a parent-level project ever aggregates child-app items.
- Auto-archival rules — when Done items leave the active view.

When any of these settle, add the convention here. Until then, defer to whatever the user wants in the moment.

## Related

- [[pseudomonorepos]] — load before this skill; the tree-walking discipline is what makes Convention 2 correct.
- [[context-vigilance]] — what `context-v/` files look like, so the things being linked to follow the discipline.
- [[git-conventions]] — commit-message shape, branch tiering. Task-body links to a context-v file inherit the branch tier from the same model.
- [[changelog-conventions]] — when a project task is "ship this," the corresponding changelog entry lives in `<repo>/changelog/` per that skill.
- External — gh CLI Projects docs: <https://cli.github.com/manual/gh_project>
- External — GitHub ProjectV2 GraphQL reference: <https://docs.github.com/en/graphql/reference/objects#projectv2>
