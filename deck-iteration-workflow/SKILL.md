---
name: deck-iteration-workflow
description: The Lossless Group's framework for developing slides-only Astro sites for fundraise processes, aligned with the calmstorm-decks project patterns and the iterative approach from the "Develop a Slides-only Astro Site for a Fundraise Process" specification. Use when creating or modifying slide decks, managing slide variants, or implementing the structured iteration workflow for fundraise material development.
---

# Deck Iteration Framework

A structured approach to developing slide decks for fundraise processes using the iterative methodology established in the calmstorm-decks project.

## When to use this skill

- Creating a new slides-only Astro site for fundraise processes
- Managing slide variants and iterations during development
- Implementing the phased workflow for slide deck development
- Working with the calmstorm-decks project patterns
- When the user mentions "deck iteration", "slide variants", or fundraise slide development workflows

## Overview

This framework provides a structured approach to developing slide decks for fundraise processes based on the patterns and workflows discovered in the calmstorm-decks project. It emphasizes iterative development, clean slate approaches, variant management, and phased implementation while avoiding common pitfalls from previous projects.

## Core Principles

1. **Start fresh** - Break from established patterns that have proven arduous and time-consuming
2. **Iterative perfection** - Get something playable and clean before adding complexity
3. **Variant generation** - Create multiple variants to explore design options quickly
4. **Phase-based development** - Follow a structured progression from simple HTML to complex features
5. **Design system foundation** - Build explicit design systems only after achieving aesthetic harmony

## Workflow Phases

### Phase 1: Plain HTML with Inline Tailwind Slides, all at once

**Approach:**
- Start with simple HTML and Tailwind for inline improvisation
- Use inline Tailwind classes exclusively (no @apply, no custom CSS)
- Follow built-in Tailwind tokens only to avoid premature lock-in
- Focus on clean design with generous whitespace and proper typography

**Styling Approach:**
- Inline Tailwind utilities only
- Use built-in tokens exclusively (no custom palettes)
- Calm/Storm visual language defaults:
  - Background: Pure white (`bg-white` / `#FFFFFF`)
  - Borders: Thin (1px), mid grey (`border-gray-300` or `border-gray-400`)
  - Primary text: Slightly darker grey (`text-gray-800` or `text-gray-900`)
  - Detail text: Lighter grey (`text-gray-500` or `text-gray-600`)
  - Corner radius: Boxy-leaning, `rounded` or `rounded-sm` (2-4px)

**Goal:** Iterate until design is clean and has aesthetic harmony on each slide, then move to the next slide.

### Phase 2: Incremental Astro Development

**Approach:**
1. Initialize Astro site and convert previous HTML slides to Astro files one by one
2. Extract text values from PDF reference and create frontmatter properties
3. Componentize repeating elements into Astro components without changing output
4. Build design-system and brand-kit pages as needed

**Key Practices:**
- Move text values displayed in tags to frontmatter variables
- Keep running list of all properties created to dedupe and reason about
- Convert HTML/Tailwind elements to Astro + HTML + Tailwind + CSS
- Only make components from consistently used design elements
- Iterate towards stable use of semantic tokens and design system elements

### Phase 3: Incremental Introduction of Dynamic Features

**Approach:**
- Add features one slide at a time
- Prioritize advanced CSS features over JavaScript or libraries
- Use JavaScript when necessary, but avoid unnecessary frameworks
- Adopt libraries like GSAP only with intention and purpose

**Key Constraints:**
- Avoid the neverending frustration trying to make complex features work
- Keep focus on clean, stable rendered output
- Only adopt advanced features when clear necessity is demonstrated

### Phase 4: Repeat with Full Deck

**Approach:**
- Apply the same methodology to the full deck of 34 slides
- Use learnings from teaser deck to inform full deck development

## Variant Management

### Naming Conventions:

1. **Base slide landing page:** Use slug string like `overview` to create `/overview/index.astro` for navigating variants
2. **Slide variants:** `pages/drafts/{slug}-{variant}.astro`
   - Example: `pages/drafts/overview/overview-v1.astro`

### Theme Organization:

When establishing themes:
- `pages/theme/{theme}/{slug}-{variant}-{theme}.astro`
- Example: `pages/modern/overview-v1-modern.astro`

### Canonical Promotion:

- Promote best variants to canonical status by removing variant suffix from filename
- Example: `overview-v1-modern.astro` becomes `overview-modern.astro`

### Variant Lifecycle:

1. Generate multiple variants without getting stuck (2-3 min creative burst)
2. Most variants shelved, but may be reused in client review processes
3. Promote best variants to canonical status
4. Prune "total losers" but preserve viable elements for future iterations

## Navigation System

### Core Requirements:
1. Next/previous buttons positioned in bottom right corner, low opacity by default, changes on hover
2. Key bindings for next/previous navigation
3. Slide counter (7 / 17)

### Implementation Guidelines:
- Start simple and evolve navigation system over time
- Maintain focus on getting something playable and functional first
- Only complex features added after basic functionality is established

## Design System & Brand Kit

### Timing:
- Begin building Design System and Brand Kit pages slowly
- Only add to design system after achieving aesthetic harmony
- Build it incrementally, not from the start

### Key Principle:
- Avoid the delays and struggles of creating robust design systems up front
- Build it in a way that doesn't cause delays and struggles during iteration

## Constraints & Considerations

### Technical Constraints:
1. **Performance Focus:** Focus on clean, functional decks rather than features
2. **Accessibility:** Maintain accessible navigation and content structure
3. **Cross-platform Compatibility:** Ensure decks work across different browsers and devices

### Business Constraints:
1. **Private Content:** Implement proper access controls for private decks
2. **Client Requirements:** Client needs "playable" decks that are clean and error-free
3. **Technology Savvy:** Balance complex authentication with simplicity for less tech-savvy users

### Avoiding Common Pitfalls:
1. **Reveal.js Avoidance:** Avoid repeated iterations with Reveal.js due to CSS conflicts and debugging issues
2. **Complex JavaScript:** Avoid premature use of JavaScript or animations that cause problems
3. **Design System Overhead:** Avoid getting stuck in design system creation without clear benefit

## AI Assistance Guidelines

### Creative Generation:
- Generate 2-10 variants per slide without getting stuck
- Use 2-3 minute bursts for creative generation
- Most variants will be shelved but may be useful in client reviews

### Pattern Application:
- Follow existing patterns from calmstorm-decks project
- Adapt patterns to each site's needs
- Copy and adapt rather than import and constrain

## Related Context

- [[context-v/specs/Develop-a-Slides-only-Astro-Site-for-a-Fundraise-Process]] - Core specification this framework implements
- [[context-v/prompts/New-Site-Quickstart-Guide]] - New site setup guide for Astro-Knots projects
- [[astro-knots]] - Astro development conventions
- [[context-vigilance]] - Context management framework