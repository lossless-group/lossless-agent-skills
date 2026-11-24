---
name: refactor-memo-to-form-requirements
description: Turn a finished long-form investment memo into the structured form a fund administrator requires for a deal, starting with Decile Hub's deal memo (nine 1/2/4/5 rating categories plus 29 questions in four groups). Use when fund admin asks for a memo on a deal and the Hub shows a form instead of (or as well as) an upload; when someone says "fill in the deal memo form", "Decile wants ratings", "the memo needs to go into Decile", or "backfill the memo for <company>"; or when a portfolio company's SPV, fund or follow-on deal needs its memo record completed. Encodes picking the memo version closest to the investment date (backfilled memos for early portfolio companies post-date the investment), mapping memo sections onto form questions, separating what the memo can answer from what only the partner can attest, drafting ratings for the partner to confirm, and never overwriting human-written answers.
---

# Refactor a Memo to Form Requirements

Fund admins don't always accept a memo as a file. Decile Hub's fund admin team wants
every **deal** (one investment event, with its own paperwork, into one company) to carry
a deal memo, and the Hub records that memo as a **form**: ratings plus question answers.
This skill takes the memo we already wrote and refactors it into that form without
inventing anything.

The form is in [`references/decile-hub-deal-memo-form.md`](references/decile-hub-deal-memo-form.md).
Read it first. It covers the nine rating categories, the 29 questions, which questions
only the partner can answer, and the tool for each field.

Compose with `decilehub-interface` (safety tiers and record model for the Decile MCP) and
MemoPop's own server instructions (call `list_skills` there before changing a memo).

## The one rule that makes this skill exist

**Use the memo that best matches the investment date.** A deal memo records the case
as it stood when we invested, so the source has to be the memo written closest to that
date.

- **Going forward**, a memo is written at investment, so a version dated on or just before
  the investment date will exist. Use it.
- **Early portfolio companies didn't get a memo at investment.** We are backfilling them,
  so every version on the server post-dates the investment (e.g. CogSciAI's compiled memo
  is headed "Retrospective Justification", dated 2026-08-28, for a late-2024 SAFE). For
  these, take the **earliest** version after the investment date, and keep later facts
  (rounds, revenue, hires, news after the investment date) out of the form answers. Tell
  the partner it is a backfill.
- A version dated **on or before** the investment date beats one dated after, even when
  the later one is closer in days. It shows what we knew when we wired the money.

## Procedure

### 1. Pin the deal

1. `list_deal_memos` with `organization_id` (find the org with `search_people_orgs` or
   `list_organizations`). Each row has `fund_name` and `investment_type`.
2. Choose the memo for **this** deal: the right vehicle (SPV vs. main fund) and the right
   type (`initial` / `follow on`). A company can have several memos (CogScAI has 5454 for
   the SPV and 83128 for Fund I). If more than one fits, ask which deal.
3. `get_deal_memo` for its stage, the answers already there, `linked_positions` and `deal`.
   A `closed` memo refuses writes; stop and say so.

### 2. Establish the investment date

Use the first of these that exists, and say which one you used:

1. `linked_positions[].acquisition_date` on the memo.
2. The fund's position in the company: `list_investment_positions` (`fund_id` is the
   **entity** id from `list_entities`, with `q` = company name) → `acquisition_date`.
   Legacy-portfolio funds answer 422; use `list_portfolio_company_investments` instead.
3. The funding round `close_date` on the organization.
4. The dated deal docs in the deal's dataroom (we prefix files `YYYYMMDD_`, e.g.
   `20241213_CogSciAI_SPV--Seed/`).
5. Ask the partner.

### 3. List the candidate memos and their dates

Collect every candidate, with its date:

- **MemoPop** (the firm's memo server): `list_deals` → the deal slug. Read the compiled
  memo with `get_artifact(deal, artifact_id: "compile.assemble")`. Earlier compiles come
  back by passing `version: 1, 2, …`. The memo's own date is the `**Date:**` line in its
  header, and the line above it says whether it is a regular memo or a "Retrospective
  Justification" (a backfill). Use that date, not the deal's `updated_at`; imports reset
  `updated_at` for every deal at once.
- **The Decile memo itself.** Answers already on the memo carry `updated_at` and an
  author. These are often the *contemporaneous* record: CogScAI's SPV memo has five
  Overview answers written by the deal lead on 2024-10-21, two months before the SPV
  closed, while the MemoPop memo is a 2026 backfill.
- **Materials** already attached to the memo or the org (`list_deal_memo_attachments`).

Pick the source by the rule above, and tell the partner which one you chose and why in
one line. When the existing Decile answers are older than the MemoPop memo and closer to
the investment date, they win for the questions they answer. The MemoPop memo fills the
gaps.

### 4. Map memo to form

`list_deal_memo_questions` on the target memo gets this memo's question ids. Then, per
question:

| Situation | Action |
|---|---|
| Answer already present, written by a person (`ai_generated: false`) | **Keep it.** Propose an edit only if the partner asks, and show old vs. new. |
| Owner is **memo** | Draft from the chosen memo's sections. Reuse its sentences and figures, cite the source file names where the memo does, and keep within what the memo says. |
| Owner is **terms** | Take from the deal docs or the memo's Funding & Terms section (round, security, cap, discount, amount, signing date). If a number isn't in the documents, leave the answer out and list it as missing. |
| Owner is **partner** | Don't draft an attestation (conflicts, economic interest, compensation, compliance, management issues, value-add, the Mensarius Oath). Ask, or leave it unanswered and list it. |
| The memo has nothing on it | Leave it unanswered and list it. Never pad. |

Typical sources in our memos, by template. The MemoPop deal shows which template it used:

- **`decile-group-deal-memo-template`**: its sections were built to answer Decile's
  questions. Map them section to question directly.
- **`direct-early-stage-12Ps`**: problem/product → Origins and Offering; milestones →
  Offering's roadmap and Opportunity; geography, competitors, barriers, timing → Opening;
  founders → Organization; cash, use of funds, terms → Funding & Terms; macro risk and
  "the bet" → Risks & What Could Go Wrong.

Write plain text with blank lines between paragraphs (HTML also works). Keep answers to a
few short paragraphs: fund admin reads them as answers, so don't paste whole memo
sections.

### 5. Draft the ratings

Draft one score per category (**1, 2, 4 or 5; there is no 3**) with a one- or
two-sentence comment grounded in the memo, plus a short overall note. Base them on the
memo's scorecard *analysis* (the per-dimension reasoning), not its headline numbers.

`rate_deal_memo` writes **as the API key's user**, so the rating is that partner's.
Show the partner the full draft table and write it only after they confirm or adjust it.

### 6. Show, confirm, write, verify

1. Show the partner every drafted answer and the ratings table, grouped as the Hub groups
   them, along with the list of what was left unanswered and why.
2. On confirmation, write the answers in one `answer_deal_memo_questions` call (all or
   nothing) with `ai_generated: true`, then call `rate_deal_memo`.
3. Attach the source memo as a Material (`upload_deal_memo_attachment`, `kind: material`)
   if it isn't already there, so the full text travels with the deal.
4. Re-read with `get_deal_memo` and `get_deal_memo_ratings`, and report what landed.

**Don't** submit for review, submit to IC, close the memo, or link a position as part of
this skill. Each of those changes the memo's stage, and linking a position can close it as
Invested. Offer them as next steps.

## Gotchas

- **Question ids differ per memo**, even for identical text and the same template. Always
  re-list them.
- **The compiled memo's headline scorecard can be wrong.** CogSciAI's compile shows every
  dimension at "0.0/5" and "Recommendation: PASS" for a deal we invested in. Never carry a
  headline score or recommendation into the form; use the per-dimension analysis.
- **`update_deal_memo` doesn't fill the Memo tab.** Only `answer_deal_memo_questions` does.
- **Category keys are exact** (`Founders/Team`, `Thesis Alignment`). The ratings
  categories come from the memo's config, so read them with `get_deal_memo_ratings` before
  writing; if they differ from the reference, the live config wins.
- **Other clients have other templates.** The reference documents Humain Ventures'
  template. For another Decile tenant, read their template live and add a sibling
  reference file rather than editing this one.
