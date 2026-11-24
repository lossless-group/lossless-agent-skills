---
title: "Decile Hub Deal Memo Form (Humain Ventures)"
lede: "The fields Decile Hub's fund admin team expects on every deal memo: nine rated categories plus a note on the Ratings tab, and 29 questions in four groups on the Memo tab."
date_created: 2026-11-24
date_modified: 2026-11-24
status: Verified
authors:
  - Michael Staton
augmented_with:
  - Claude Code on Claude Opus 5.5
tags:
  - Decile-Hub
  - Deal-Memos
  - Fund-Admin
  - SPVs
verified_against:
  - "Deal memo 5454, CogScAI SPV (deal_memo_config_id 208484), read 2026-11-24"
  - "Deal memo 83128, Humain Ventures Fund I, LP, read 2026-11-24"
---

# Decile Hub Deal Memo Form (Humain Ventures)

When Decile's fund admin team asks for an investment memo on a deal, the Hub doesn't
just take a file. Each deal memo has two form surfaces to fill in: the **Ratings tab** and
the **Memo tab**. You can still attach the long-form memo as a file (Materials), but on
its own it leaves both tabs empty.

**Scope.** Both surfaces were read live from the `humain` account on 2026-11-24. The
CogScAI SPV memo (5454) and a Humain Ventures Fund I memo (83128) have identical
categories and questions. So this is the account's **standard template**, used for SPVs
and the main fund alike, not something SPV-specific. Another Decile client has its own
template; read theirs live before assuming this one.

**Question ids are per memo.** The same question has a different id on every memo
(e.g. "What problem is the company solving?" is `5130117` on memo 5454 and `10025243` on
83128). Always call `list_deal_memo_questions` on the memo you are filling in. Never
reuse ids from this file or another memo.

---

## 1. Ratings tab

Written with `rate_deal_memo`, read with `get_deal_memo_ratings`.

**Scale: 1, 2, 4 or 5.** There is no 3, on purpose: Decile forces a lean one way or the
other. `null` clears a score. Each category takes an optional comment, and the rating as
a whole takes an optional note.

Ratings belong to a **rater**: `rate_deal_memo` scores as the API key's user. A rating is
one partner's judgment, so an agent drafts the scores and comments and the partner
confirms them before anything is written.

| # | Category (exact key) | What it asks |
|---|---|---|
| 1 | `Founders/Team` | Strength of the founders and team |
| 2 | `Product/Service` | Functionality, uniqueness, and value proposition |
| 3 | `Velocity` | Progress speed relative to top startups |
| 4 | `Market` | Size of the market opportunity |
| 5 | `Traction` | Company progress over time |
| 6 | `Competition` | Offering superiority relative to competitors |
| 7 | `Thesis Alignment` | Does this align with the fund's thesis? |
| 8 | `Venture Scale` | Potential for a venture-worthy return |
| 9 | `Societal Impact` | Refer to the UN SDGs: <https://sdgs.un.org/goals> |
| — | *Additional Notes* | The rating's overall `note` |

The category keys are case- and punctuation-exact (`Founders/Team`, not `Team`). An
unknown key is refused with 422 and the valid values. Ratings stay hidden from you until
you rate the memo or it closes.

---

## 2. Memo tab (the memo body)

Written with `answer_deal_memo_questions` (ids from `list_deal_memo_questions`). These
answers **are** the memo as fund admin reads it. `update_deal_memo` only edits scalar
fields (counterfactual, links, funding rounds, investment type) and doesn't fill this tab.

**Owner** marks who must supply the answer:
- **memo**: drafts from the investment memo's research and prose.
- **partner**: an attestation or judgment only the GP can give (conflicts, compensation,
  conviction, value-add). Decile flags these `enrich_with_ai: false`. Draft only from
  something the partner has already written; otherwise ask.
- **terms**: comes from the deal docs (SAFE, term sheet, SPV docs), not the narrative.

### 2.1 Company and Situation Overview

| # | Question | Owner |
|---|---|---|
| 1 | What problem is the company solving? | memo |
| 2 | What is the product/service? Does it solve the pain point/need? | memo |
| 3 | What are the key business and product milestones over the next 12 - 24 months? | memo |
| 4 | What is the company's target geography/demographic? | memo |
| 5 | Who are their main competitors? What is the company's competitive advantage/key differentiation that sets them apart? | memo |
| 6 | Barriers to entry (two meanings - for the startup and the barrier they have established)? | memo |
| 7 | What relevant experience and expertise do the founders bring to the table? Do they understand the customer? | memo, partner confirms |
| 8 | What is their current cash on hand, if available? How much runway does the company have? | terms / memo |
| 9 | What are the current and target unit economics of the business? | memo |
| 10 | How do they plan to fund their growth and achieve profitability? What will funds be used for? (i.e., key hires, working capital) | memo |

### 2.2 Key Risks and Potential Conflicts

| # | Question | Owner |
|---|---|---|
| 1 | Please describe any management team issues. | partner |
| 2 | Does the company comply with applicable laws and regulations in its industry? | partner |
| 3 | What are the macroeconomic risk factors for the company? | memo |
| 4 | Is the company currently or will become a limited liability company, limited partnership, or other passthrough entity? | terms |
| 5 | Are there any conflicts of interest that would arise from this investment? | partner |

### 2.3 General

| # | Question | Owner |
|---|---|---|
| 1 | Who are the other major investors in this round? Who are the noteworthy previous investors? | memo / terms |
| 2 | When do you need to sign the investment documents? | terms |
| 3 | Do you hold any economic interest in this company? | partner |
| 4 | Do you or will you receive compensation from this company? | partner |
| 5 | Does the cap table reflect best practices and support the capital journey? | partner / terms |
| 6 | Is the company entering the market at the right time? Why? | memo |
| 7 | What is the company's potential exit plan? | memo |

### 2.4 Evaluation

| # | Question | Owner |
|---|---|---|
| 1 | Is this investment within your fund thesis? | partner (memo supports) |
| 2 | What are the key terms of the investment (i.e., type of round, round size, valuation) | terms |
| 3 | Do you have conviction that this is a venture deal and will return for your fund? Why? | partner (memo supports) |
| 4 | What is "the bet" - what needs to happen for this investment to succeed? | partner (memo supports) |
| 5 | Does this investment round bring the company to a significant milestone where next round investors will be motivated to invest? | partner (memo supports) |
| 6 | How do you add value beyond the investment? | partner |
| 7 | Does the company support the Mensarius Oath? How do the company's products/services positively impact life on our planet? | memo, partner confirms the Oath |

---

## 3. Other memo fields fund admin may look at

| Field | Tool | Notes |
|---|---|---|
| Counterfactual | `update_deal_memo` | Free text. |
| Investment type | `update_deal_memo` | `initial`, `follow on`, `secondary`. Each deal into the same company is its own memo. |
| Funding rounds | `update_deal_memo` (`organization_attributes.company_funding_rounds_attributes`) | Round, security, cap, close date. |
| Materials | `upload_deal_memo_attachment` (`kind: material`) | Attach the long-form memo here too, so the full text travels with the deal. |
| Term sheet / financing docs | `upload_deal_memo_attachment` (`kind: term_sheet`) | |
| Linked position | `link_deal_memo_position` | Linking can **close** the memo as Invested and move the Deal to Portfolio; confirm first. |

## 4. One company, several memos

A deal memo belongs to **one fund**. A company invested in through both the main fund and
an SPV has one memo per vehicle. CogScAI has two: 5454 (CogScAI SPV, opened 2024-10-21,
first five Overview answers by the deal lead) and 83128 (Fund I, opened 2026-11-17 as a
copy of 5454's answers). Follow-ons get their own memos too. Fill each memo for its own
deal and its own date.
