/**
 * Static SEO copy for the lossless-agent-skills splash.
 *
 * OG image: replace the placeholder below with an ImageKit-hosted JPEG once
 * generated. Per the open-graph-share-seo-geo skill: absolute URL, JPEG
 * (not WebP — Slack/X don't unfurl WebP reliably), og:image:type matches the
 * bytes the unfurler actually receives.
 */

export const OG_IMAGES = {
  banner: {
    url: 'https://lossless-group.github.io/lossless-agent-skills/og-banner.jpg',
    width: 1200,
    height: 630,
    type: 'image/jpeg',
    alt: 'Lossless Agent Skills — terminal-style catalog banner',
  },
} as const;

export const DEFAULT_OG = OG_IMAGES.banner;

export const STATIC_SEO = {
  brand: 'Lossless Agent Skills',
  titleSuffix: ' — Lossless Agent Skills',
  siteName: 'Lossless Agent Skills',

  root: {
    title: 'Lossless Agent Skills',
    description:
      'A shared library of Agent Skills used by Lossless team members and AI coding agents on Lossless projects. Tool-agnostic — works with Claude Code, pi-coding-agent, OpenAI Codex, and anything following the Agent Skills standard.',
  },

  skills: {
    title: 'Skills',
    description:
      'The full catalog — every skill in this collection, with status, tags, and a one-line lede.',
  },

  changelog: {
    title: 'Changelog',
    description:
      'What shipped, when, and why — entry-by-entry notes for the Lossless Agent Skills collection.',
  },
} as const;
