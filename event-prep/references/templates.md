# Event-prep templates

Skeletons only. Replace `<…>`. Delete sections that don't apply instead of leaving them
empty.

---

## Series note: `content/sources/Events/<Series>.md`

```markdown
---
url: "<series homepage>"
og_title: "<fetched>"
og_description: "<fetched>"
og_image: "<fetched or null>"
og_favicon: "<fetched>"
og_last_fetch: "<ISO timestamp>"
date_created: <YYYY-MM-DD>
date_modified: <YYYY-MM-DD>
maintained_by: "[[<organizer note>|<Organizer>]]"
tags:
  - Event-Series
---
[[Sources/Events/<Series> <Year>|<Series> <Year>]]

[[<organizer>]] · [[<topic concept>]]

[[moc/Events and Conferences MoC]]
```

---

## Prep map: `<routed folder>/<Series> <Year>.md`

```markdown
---
title: <Series> <Year> Event Map
url: <instance page>
date_created: <YYYY-MM-DD>
date_modified: <YYYY-MM-DD>
publish: false
tags:
  - Event-Instance
  - Event-Map
---
# <Series> <Year> Event Map

**Event:** [[Sources/Events/<Series>|<Series>]] <Year> (<dates>), <venue, city>. <Format, size>. **Pre-event prep** for <whom>: built from <sources>, web research, and the <instance> Twenty CRM. Nobody here has been met yet.

**Lens:** <Whom> wants <N> kinds of contact. **<Kind 1>** = <definition>. **<Kind 2>** = <definition>.

**Priority key:** *A* = seek out, prepared ask. *B* = worth a deliberate conversation. *C* = only if it happens naturally. *CRM* = already in the <instance> Twenty CRM.

## Segments at a glance

| Segment | Organizations |
|---|---|
| [[#<Segment 1>]] | <Org>, <Org> (CRM), … |

## <Segment 1>

<Optional one-line framing.>

| Organization | What they do | Role at event | Contacts | <Lens> relevance | Pri. |
|---|---|---|---|---|---|
| <Org> | <one line> | <Speaker / Sponsor / Host> | <Name> (<Title>). **CRM:** <existing contact> | <the specific fact> | A |

---

## Operator prep

### The one-line positioning

> <one sentence for this room>

<How to angle it for this audience.>

### Top <N> conversations, in order

| # | Who | Ask | Opening line |
|---|---|---|---|
| 1 | <Name>, <Org> | <concrete ask> | "<sayable line that cites a fact>" |

### Sessions to attend

| Session | Why | When |
|---|---|---|

**Skip:** <what, and why>.

### Protocol

- **<Person or group>:** <address, deference, routing, follow-up>.

### Logistics

| | Recommendation |
|---|---|
| **Arrive** | |
| **Depart** | |
| **Hotel** | |
| **Pass** | |

### Before the event

1. <outreach, warm-path check, materials>

### Dates to hold

- **<Date>:** <what>.

### After the event

Log every conversation in the <instance> Twenty CRM against the `<instance name>` event, then re-sync this map from the CRM.

*Sources: <event pages> (fetched <date>); <instance> Twenty CRM (<records>), pulled <date>; web research <date> (<domains>). Unverified: <list>.*
```

---

## Recap map (after re-sync)

Keep the header and segments. Swap the priority key for the touchpoint key, and add:

```markdown
**Touchpoint key:** *Met in person* = conversation or card. *Booth / badge* = visited or photographed. *Speaker / host / pitch* = seen on stage, not met. *Observed attendee* = on a list or slide, not confirmed met.

## Off-Theme or Unverified

| Organization | What they do | Role at event | Contacts |
|---|---|---|---|

## Unaffiliated contacts

- <Name>: <what they are>. <Role at event>.

## Observed themes

- **<Theme.>** <Evidence: which orgs, what was on the floor.>

*Source: <instance> Twenty CRM, eventInstance `<name>`, pulled <date>, re-synced <date>.*
```

---

## Proposed-CRM-writes table (show before any write)

| # | Object | Action | Record | Key fields | Evidence |
|---|---|---|---|---|---|
| 1 | event_series | create | <Series> | organizer, website, region | <url> |
| 2 | event_instance | create | <Series> <Year> | dates, location, costTicket | <url> |
| 3 | company | enrich / create | <Org> | domain, description | fetched <url> |
| 4 | event_participation | create | <Org> / <Person> @ <instance> | role SPEAKER, metInPerson false | speakers page |
