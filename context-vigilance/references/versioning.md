# Versioning: Three or Four Parts

> **Field name:** the standard is **`at_semantic_version`** — it reads naturally as "this doc is *at* version X," and it's what ~4,140 files and every template use. Write that one.
>
> **`semantic_version` is a permanently-accepted alias** for the same property and the same value (~330 files). It is not a legacy spelling awaiting cleanup: **no migration is planned and none is wanted.** Resolving one extra key is free for a renderer; rewriting hundreds of files to unify the spelling buys nothing. Consumers read `at_semantic_version ?? semantic_version`.
>
> So: **write `at_`, read either, never rewrite a file just to change which name it uses.** Everything below applies identically to both.
>
> Bump it together with `date_authored_current_draft` — a version move and a substantive revision are the same event.

A version comes in one of **three formats**. The user picks; none is enforced. Your job is to read each one correctly and keep to the format a doc or repo already uses.

| Format | Shape | Example | Read it as | Where it comes from |
|---|---|---|---|---|
| Semantic Versioning | `major.minor.patch` | `0.1.0` | major 0, minor 1, patch 0 | [semver.org](https://semver.org/), the market standard. New work usually starts at `0.1.0`. |
| Four-part | `epoch.major.minor.patch` | `0.1.0.0` | epoch 0, major 1, minor 0, patch 0 | Our format for documents. Templates start at `0.0.0.1`. |
| Epoch SemVer | `{epoch * 1000 + major}.minor.patch` | `1002.3.0` | epoch 1, major 2, minor 3, patch 0 | Anthony Fu's [Epoch Semantic Versioning](https://antfu.me/posts/epoch-semver). |

**Count the parts before you read the digits.** `0.1.0` and `0.1.0.0` look alike, but the `1` is a minor in the first and a major in the second.

## Why Epoch SemVer exists

An epoch is useful: it marks a change bigger than a major one. But semver is everywhere, and npm, JSR, and other semver tools don't accept a four-part version, so using four parts means juggling two systems. Epoch SemVer keeps the epoch and stays a valid three-part version.

- **Below 1000 it's ordinary semver.** While the epoch is 0, `0.1.0` reads the same in both, so there's nothing to tell apart.
- **At 1000 or above, the first number holds the epoch:** divide by 1000 for the epoch; the remainder is the major. `1000.0.0` is the start of epoch 1.
- **An epoch bump adds 1000 and resets the rest:** `2.3.1` → `1000.0.0`, and `1002.3.0` → `2000.0.0`.

It's a good choice for new work, especially anything that also ships as a package. It isn't a migration: **existing versions stay as they are.**

## Which to use

- **Existing doc:** keep its format. Never convert a version, and never rewrite files to move a repo to another format.
- **New doc:** match the other docs in the repo. If there's nothing to match, ask the user or use the template's default.
- **Published package:** semver or Epoch SemVer, never four parts.

To compare across formats, translate in your head rather than in the file: four-part `e.M.m.p` is Epoch SemVer `{e * 1000 + M}.m.p`, so `1.2.3.4` is `1002.3.4`.

The bump rules are the same in every format, except that plain semver has no epoch. The rest of this page shows four-part; for the other formats, leave off the first number and move the epoch as above.

## Four-part format


```
epoch . major . minor . patch
  │       │       │       │
  │       │       │       └── typo, clarification, small wording fix
  │       │       └────────── new section, additive content
  │       └────────────────── restructure of the document
  └────────────────────────── total pivot — fundamentally different direction
```

## Starting version

Four-part documents start at `0.0.0.1`; semver and Epoch SemVer work usually starts at `0.1.0`.

## Epoch semantics

- **`0.x.x.x`** = proposal / not-yet-adopted. Doc exists but the team hasn't bought in.
- **`1.0.0.0`** = first accepted version. Promote a doc from epoch 0 to epoch 1 when it's been adopted as the way the project actually works.
- **`2.0.0.0`+** = total pivot. Not a restructure — a fundamentally different direction. Use when the previous epoch is being abandoned or replaced wholesale, not refined.

## When to bump which digit

| Change | Bump |
|---|---|
| Fix a typo, clarify a sentence, tighten wording | `patch` |
| Add a new section, add an example, append meaningful content | `minor` |
| Restructure sections, change the doc's organization, merge/split docs | `major` |
| Total pivot — the doc now argues for a fundamentally different approach | `epoch` |

## Cascading reset

Standard semver-style cascading is **encouraged but not enforced**:

- Bumping `minor` *should* reset `patch` to 0 (e.g., `0.0.1.5` → `0.0.2.0`)
- Bumping `major` *should* reset `minor` and `patch` (e.g., `0.0.2.5` → `0.1.0.0`)
- Bumping `epoch` *should* reset everything (e.g., `0.3.2.5` → `1.0.0.0`)

The team is ADHD-friendly about this. Don't block on it. Consistency within a single file is the real goal — if a file has been climbing without resets, keep climbing rather than retroactively fixing.

## When you can't decide

Bump the **patch**. Always safe. The worst outcome is under-signaling a change, which is better than blocking on the question.

## Don't decrement

Versions only go up. If you make a mistake, fix forward with a patch bump that explains the correction.

## Example progression

```
0.0.0.1   # initial proposal
0.0.0.2   # fixed a typo
0.0.1.0   # added "Decision Tree" section
0.0.1.1   # clarified one bullet in the new section
0.0.2.0   # added a second new section
0.1.0.0   # restructured into 3 parts instead of running prose
1.0.0.0   # team adopted it; promoted from proposal to canonical
1.0.0.1   # typo fix on the canonical version
2.0.0.0   # we abandoned this approach entirely; this doc now argues for the replacement
```

## What to do alongside the bump

Always update `date_modified` in the same edit.
