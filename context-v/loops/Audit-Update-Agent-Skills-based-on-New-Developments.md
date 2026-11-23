---
title: "Audit and Update Agent Skills based on New Developments"
lede: "When the Agent Skills spec changes or a new best practice lands, write it down once as a brief, then send one fresh subagent per skill to audit against it, approve the fixes, apply them, and log the run, so the next time someone asks 'did we already do this?' the answer is in the repo."
date_created: 2026-11-22
date_modified: 2026-11-22
date_authored_initial_draft: 2026-11-22
date_authored_current_draft: 2026-11-22
authors:
  - Michael Staton
augmented_with:
  - Claude Code on Claude Opus 5.5
semantic_version: 0.1.0.0
status: Draft
site_uuid: 8db53eb9-b75e-4334-9a02-515297115994
hex_code: 9437p5
tags: [Agent-Skills, Maintenance, Best-Practices, Specifications, Subagents]
publish: true
type: Loops
---

# Audit and Update Agent Skills based on New Developments

An abstract loop: the procedure is fixed, and the content changes every run. Each
run starts from one **audit brief**, a file that states a single new development
(a spec change or a best practice) as checks a subagent can run against a skill.
The loop sends one fresh subagent per skill with that brief, collects findings,
gets them approved, applies them, and records the run.

`loops/` is an experimental `context-v` folder; expect this doc's shape to change.

**Invoke with:**
```
/loop context-v/loops/Audit-Update-Agent-Skills-based-on-New-Developments.md <path-to-audit-brief>
```

***

## What counts as a new development

| Kind | Examples | Where to watch |
|---|---|---|
| **Spec change** | A new or changed `SKILL.md` frontmatter field; a change to how harnesses discover, load, or preview skills; a plugin-manifest schema change | [agentskills.io/specification](https://agentskills.io/specification); each harness's skills docs (Claude Code, pi, Codex, Cursor); the `agent-plugins.org` schema pstack declares |
| **Best practice** | Vendor guidance on writing skills; a pattern proven in a well-run pack | Anthropic's skills guide; the packs pinned in `ai-labs/studies/agent-skill-packs/` |
| **Model change** | A new model generation that reads skills differently (less prescription needed, partial reads of long files) | Model release notes; the vendor guidance that ships with them |
| **Our own lesson** | A failure seen across several skills in real sessions | `context-v/reminders/` and `issues/` across the tree |

Secondhand sources (a video, a blog post, a newsletter) are welcome as the
trigger but never as the authority. The brief records what the primary source
says.

***

## Cadence

- **Event-driven (the main trigger).** Someone captures a development: a
  transcript lands in `content-md/lossless/Sources/`, a spec repo cuts a
  release, a model ships. Write the brief, run the loop.
- **Periodic sweep (monthly).** Check the watch list above for anything not yet
  briefed. If nothing changed, log a one-line "checked, nothing new" row in the
  run log, as pstack's `SYNC-LOG.md` does for upstream checks.

***

## The audit brief (the file the subagents work from)

One development per brief. Briefs live in `context-v/loops/audit-briefs/`,
named `YYYY-MM-DD__<Slug>.md`. A brief is the subagents' only source of what
changed, so it must stand on its own.

```markdown
---
title: "<the development, as a short name>"
date_created: YYYY-MM-DD
kind: spec-change | best-practice | model-change | our-own-lesson
source_primary: <URL to the spec, guide, or release notes>
source_secondary: <optional: the transcript or post that surfaced it>
verified_against_primary: true | partial | false
applies_to: all | <list of skills or a selector, e.g. "skills over 300 lines">
type: Audit-Briefs
---

# <title>

## What changed
Two or three sentences, from the primary source.

## Checks
One row per rule. Each check must be something a subagent can decide from the
skill's files alone.

| ID | Rule | Check (how to tell) | Fix (what to change) | Confidence |
|---|---|---|---|---|
| R1 | SKILL.md is a contents page | `SKILL.md` over 500 lines, or detail inline that a step could load from a linked file | Move detail into `references/`, link it one level deep | verified |
| R2 | ... | ... | ... | secondhand: check before applying |

## Out of scope
What this brief does not ask anyone to change.
```

**Confidence** decides what happens to a finding: `verified` rows can be fixed
after approval; `secondhand` rows are reported but not applied until someone
checks the primary source and updates the brief.

***

## Per-run procedure

### 1. Intake
- Read the brief. If `verified_against_primary` is `false`, stop and say which
  rows need checking first. Don't audit 40 skills against a rumour.
- Check the **run log** at the bottom of this doc. If the same development was
  already run, say when, and run only against skills added or changed since.

### 2. Scope
- **In scope:** skills authored in this repo (top-level folders with a
  `SKILL.md`), filtered by the brief's `applies_to`.
- **Out of scope:** vendored submodules (`chroma-agent-skills`, `archify`,
  `agent-reach`, and other upstream pins). Never edit inside them. Forks we own
  (`humanizer`, `talk-normal`, `floorplan`) are audited in their own repos, not
  here.
- **Copies elsewhere in the tree** (for example, skills duplicated into
  `ai-labs/dididecks-ai/context-v/agent-skills/` or
  `ai-labs/memopop-ai/context-v/agent-skills/`): audit the canonical copy only,
  and list the duplicates in the report as drift. Don't fix two copies.
- Write the scoped list of skills into the run log before fanning out.

### 3. Fan out: audit only
Start **one fresh subagent per skill** (batch small skills three or four to an
agent if the list is long). Fresh means a new context window, not a fork of
this conversation. Run them in parallel.

Kickoff, in this order:

```
Read <absolute path to the audit brief> before anything else.
You are auditing one agent skill against that brief. Do not edit any file.
Skill: <absolute path to the skill folder>
For each check in the brief, report: ID, pass / fail / not applicable,
evidence (file:line), and the smallest fix that would make it pass.
Also report anything in the skill the brief makes obsolete, i.e. instructions
the model no longer needs. Removing text is a valid fix.
Return only the report, in the shape below.
```

Report shape (one per skill):

```
## <skill-name>
| ID | Result | Evidence | Proposed fix | Size |
|---|---|---|---|---|
| R1 | fail | SKILL.md:1-612 | Move §4-§7 into references/workflow.md | M |
Obsolete: <lines or "none">
Drift: <duplicate copies found, or "none">
```

### 4. Triage
- Merge the reports into one table, grouped by skill, failures first.
- **A person approves before anything changes.** Present the table; take
  approvals per skill or per row. Secondhand rows stay unapplied.
- Note anything the brief got wrong: if most skills "fail" a check for a good
  reason, fix the brief, not the skills.

### 5. Apply
Start a fresh subagent per approved skill with the same brief, the approved rows
from its report, and permission to edit only that skill's folder. One commit per
skill, following `git-conventions` (e.g.
`update(<skill-name>): Apply <brief slug> — <what changed>`).

### 6. Verify
For each changed skill:
- The directory name still matches the frontmatter `name:`.
- The `description` still says when to load the skill (and, if the brief set a
  length limit, is under it).
- Every file `SKILL.md` links to exists, one level deep.
- If the skill has a `config/private.example.json`, no private value leaked
  into `SKILL.md` (run the audit grep in `README.md`).
- Load it in a real session once where you'd expect it to fire.

### 7. Record
- Add a row to the run log below.
- Write one `changelog/` entry for the run, linking the brief.
- Mark the brief `status: Applied` (or `Partial`, with what's left).
- Run `bash ./sync-skills-symlinks.sh` so changed skills relink.

### Exit conditions
The run is done when every scoped skill has a report, every approved fix is
committed and verified, and the run is recorded. A run that stops early records
where it stopped.

***

## Guardrails
- **Audit and apply are separate passes.** Auditors never edit.
- **Less can be the fix.** Newer models often need fewer instructions; a brief
  that only ever adds text is suspect.
- **Don't normalize what the brief didn't ask about.** Other drift goes in the
  report, not the diff. Parallel sessions may be editing the same skills.
- **The brief is the single source of what changed.** If a subagent needs
  something not in the brief, the brief is incomplete; fix it and re-run.

***

## Run log

| Date | Brief | Kind | Skills in scope | Changed | Notes |
|---|---|---|---|---|---|
| ~2026-10 | Anthropic's updated skills guide, via the RoboNuggets transcript (`content-md/lossless/Sources/Transcripts/Anthropic Just Revealed 10 NEW Rules for Claude Skills.md`) | best-practice | unknown | unknown | Reported as already applied, but no commit, changelog entry, or brief records it in this repo (checked 2026-11-22). The transcript is secondhand and flags its "first 100 lines" claim as unverified. Candidate for the first brief: write it from Anthropic's guide, then re-audit. |
