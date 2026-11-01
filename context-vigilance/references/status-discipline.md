# Status Discipline for `context-v/` Documents

**Contents:** What status is for · The problem this addresses · The status values · Common variants and what they map to · The lifecycles · Companion fields · The `## Remaining work` section · When to update status · When NOT to update status · Sweep cadence · Anti-patterns

> The `status:` field is the load-bearing signal of where a document sits in its lifecycle. A directory full of `status: Draft` plans, half of which actually shipped, is a directory you can't trust.

## What status is for

Today `context-v/` gets used as we go: as reference, and to pick up where a session left off. The direction is a **visual dashboard that does real workflow management** over every `context-v/` in a tree: what's ready to assign, what's in flight, which issues are open, which stubs to finish or delete. `status:` is the field that dashboard groups by, so it has to say something true and specific about each doc.

**This vocabulary will keep evolving.** It may turn out to be too many values, or not enough. Add a value when a real state keeps appearing that none of these name; retire one when nobody uses it. Record the change here, so the dashboard and every sweep read the same list.

## The problem this addresses

`context-v/` accumulates plans, specs, explorations, and prompts over months. Without a status convention, every doc stays at its authored-day default (`Draft`) forever, and an agent landing cold cannot tell what's shipped (historical), what's in flight (needs attention), what was deliberately deferred (*not* a gap), and what's stale.

The discipline: **every meaningful state change on a document is reflected in `status:`, with companion fields that explain when, why, and what's left.**

## The status values

`status:` is a **Train-Case display string** for humans, not a machine enum. Don't switch on its values in code; spelling and casing drift across files. A dashboard should group by these values and show anything else as-is, unmapped, rather than guess.

Different kinds of doc live different lives, so the values come in families.

### Work that gets planned and shipped (specs, plans, prompts)

| Value | Meaning |
|---|---|
| `Stub` | A placeholder: title and intent, little or no body, and nobody writing it yet. A to-do, not a doc. |
| `Draft` | Being written. Default for new files that have real content. |
| `In-Review` | Drafted and being discussed or refined before execution. Mostly specs. |
| `Signed-Off` | Someone explicitly approved it; execution authorized. |
| `Ready` | Complete enough to execute, nobody has started, and no approval is needed. The "assign this" queue. |
| `Implementing` | Execution in progress. |
| `Shipped` | All deliverables landed; nothing material remains. |
| `Partially-Shipped` | Some deliverables landed, others did not. Requires a `## Remaining work` section (below). |

**`Ready` vs. `Signed-Off`:** both mean "can start." `Signed-Off` records that a person approved it; `Ready` says it's simply complete enough to pick up. With one operator and a team of agents, `Ready` is the common case.

### Issues

| Value | Meaning |
|---|---|
| `Open` | Found and not yet fixed. |
| `Resolved` | Fixed, or settled as won't-fix, with the resolution recorded in the body. |

### Decisions

| Value | Meaning |
|---|---|
| `Decided` | The decision is made and recorded. Further change happens through a new decision that supersedes it. |

### Standing documents (reminders, habits, contracts, loops, blueprints, notes, sitemap)

These never ship; they are either in force or a description of how things are.

| Value | Meaning |
|---|---|
| `Active` | A rule or practice in force. Agents **follow** it. Reminders, habits, contracts, loops. |
| `Reference` | An accurate explanation of how things are. Agents **consult** it. Notes, architecture blueprints, sitemap docs. |

**`Active` vs. `Reference`:** ask what an agent should do with it. "Do it this way" is `Active`; "here's why it is this way" is `Reference`.

### Any document

| Value | Meaning |
|---|---|
| `Deferred` | Explicitly on hold for a named reason (a dependency, a pending decision). Not stale, not abandoned. Requires `deferral_note:`. |
| `Stale` | No longer reflects current direction, not yet retired. Use sparingly; `Superseded` or `Archived` is usually better. |
| `Superseded` | Replaced by a newer document. Requires `superseded_by:`. |
| `Archived` | Retired. Kept for the record, no longer load-bearing. A consumed handoff ends here. |

Project-specific values are fine if they earn their keep. Use Train-Case and document the meaning in the project's agent instructions (`AGENTS.md`, `CLAUDE.md`) or a reference doc. If one spreads to a second repo, it belongs in this list.

## Common variants and what they map to

Values found in the tree that mean the same thing as a value above. A normalization sweep may make the **plain renames** with no reading. The **read first** rows depend on what the doc says, so they go to a status sweep where the user confirms each one.

| Found | Maps to | |
|---|---|---|
| `shipped`, `open`, any lowercase or spaced form | the Train-Case value | plain rename |
| `In-Progress` | `Implementing` | plain rename |
| `Implemented` | `Shipped` | plain rename |
| `Authoritative` | `Active` | plain rename |
| `As-observed-from-filesystem` | `Reference` | plain rename |
| `Open · Jotted` | `Open` | plain rename |
| `Published` | `Active` or `Reference` | read first. Never keep it: it collides with the `publish:` key |
| `Idea`, `Exploration` | `Stub` or `Draft` | read first |
| `Proposed` | `In-Review` or `Draft` | read first |
| `Planned`, `Planning` | `Ready` or `Draft` | read first |
| `Attempted` | `Deferred` or `Stale` | read first |
| `Unproven`, `Untested`, `Proven-Once` (loops) | `Draft` or `Active` | read first |
| `Partially-Resolved` | `Open` | read first; say what's left in the body |

## The lifecycles

```
Stub → Draft → (In-Review →) (Signed-Off | Ready →) Implementing → Shipped   # planned work
Draft → Implementing → Partially-Shipped → … → Shipped                      # partial outcome
Draft → Deferred → [later: Implementing → Shipped | Superseded | Archived]
Open → Resolved                                                             # issues
Draft → Decided → [later: Superseded]                                       # decisions
Draft → Active | Reference → [later: Superseded | Archived]                 # standing docs
```

**Status reflects reality**; not every doc passes through every value. A plan that ships in the session it was written goes straight from `Draft` to `Shipped`.

## Companion fields

When status changes, its companion fields change in the same edit.

| When status is | Required companion fields |
|---|---|
| `Stub` | `publish: false` (strongly suggested: a stub has nothing for a reader yet) |
| `Draft` / `In-Review` / `Ready` | none |
| `Shipped` | `date_first_published: YYYY-MM-DD` (the ship date); optionally `post_ship_note:` for things learned after ship, and `date_work_completed:` if known |
| `Partially-Shipped` | `date_first_published:` for the first shipped slice; a `## Remaining work (as of YYYY-MM-DD)` section at the end of the body |
| `Resolved` | the resolution in the body; `date_work_completed:` if known |
| `Deferred` | `deferral_note:` naming the reason and any expected unblocker |
| `Superseded` | `superseded_by: [[Successor-Doc]]` (and `supersedes:` on the successor) |
| `Stale` / `Archived` | optional `archive_note:` if context isn't obvious |

In every case, **update `date_modified` (and `date_last_updated` if the file uses it) in the same edit.** Status changes are meaningful edits.

## The `## Remaining work` section

For `Partially-Shipped` docs, append at the end of the body:

```markdown
## Remaining work (as of YYYY-MM-DD)

This plan is partially shipped. What's done and what's left:

### Shipped
- **Step / phase name.** One-line description of what landed.

### Not yet shipped
- **Step / phase name.** What it is, why it's still outstanding, any blocker.

### Side artifacts this plan produced
- Optional. Ancillary deliverables that ended up belonging elsewhere.
```

The heading date anchors the snapshot. When another slice ships, update the section in place (don't add a second one) and bump the date. When everything ships, set `status: Shipped`, optionally fold the section into `post_ship_note:`, and remove it.

## When to update status

1. **You ship a substantial portion** of the deliverables. Don't wait for 100%; `Partially-Shipped` exists for the in-between.
2. **You start writing a `Stub`.** It's a `Draft` now.
3. **You finish a plan and nobody needs to approve it.** Mark it `Ready` so it shows up in the queue.
4. **You fix an issue.** Set `Resolved` and say how in the body.
5. **You explicitly defer** a plan. Set `Deferred` and write the `deferral_note`.
6. **You replace** a doc. Set `Superseded` on the old one with `superseded_by:`, and `supersedes:` on the new one.
7. **You're doing a status sweep** (below) and find a doc whose status doesn't match reality.

## When NOT to update status

- **As a side effect of unrelated work.** Surface the gap to the user; don't silently normalize.
- **On docs someone else authored** whose ship-state you're unsure of. Ask first.
- **To "tidy up"** without confirming the work shipped. `Shipped` is a claim that should map to a real event: a commit, a release tag, a changelog entry.

## Sweep cadence

A periodic status sweep through a project's `context-v/` pays off, typically before authoring a new plan (to see what's already live) or after a coherent chunk of work lands. The procedure: list docs whose status is `Stub`, `Draft`, `In-Review`, `Ready`, `Implementing`, `Partially-Shipped`, or `Open`; for each, check the commits, releases, or changelog for evidence of progress; propose the status changes and companion fields to the user; apply the ones they confirm. The "read first" rows of the variants table belong here too. In the Lossless tree the full procedure is the habit `lossless-monorepo/context-v/habits/Maintain-Status-Discipline-Across-Context-V-Files.md`.

## Anti-patterns

- **`Draft` forever.** Plans that shipped weeks ago still say `Draft`. → Sweep and promote.
- **`Stub` with a body.** Stubs go stale fastest of all: the moment someone writes the doc, it isn't one. A dashboard should flag any `Stub` with a substantial body. → Promote to `Draft` or further.
- **`Shipped` without `date_first_published`.** No anchor for "when." → Add the date.
- **`Partially-Shipped` without `## Remaining work`.** The point is to enumerate what's left. → Write the section.
- **`Deferred` with no `deferral_note`.** "Why, and for how long?" must be answerable. → Add the note.
- **`Published` as a status.** It reads as the `publish:` key. → `Active` or `Reference`.
- **Silent status changes during unrelated edits.** → Surface, don't normalize.
- **Promoting status without a ship event.** → Point to a real commit, release, or changelog entry.

See also `frontmatter-spec.md` (field definitions) and `developing-a-spec.md` (the spec-specific progression).
