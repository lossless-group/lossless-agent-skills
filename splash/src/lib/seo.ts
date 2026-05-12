/**
 * Static SEO copy for the lossless-agent-skills splash.
 *
 * OG imagery: ImageKit-hosted JPEGs, four canonical formats from the
 * `generate-consistent-og-images` skill, all overlay-text-composited via
 * the `overlay-svg-text` skill. Per the `open-graph-share-seo-geo` skill:
 * absolute URLs, JPEG (not WebP — Slack/X don't unfurl WebP reliably),
 * og:image:type matches the bytes the unfurler receives, multiple
 * og:image entries are emitted in priority order so chat-preview clients
 * (WhatsApp, iMessage, Slack) land on the Square variant while Twitter
 * uses the 16:9 Banner via the separate twitter:image tag.
 */

export const OG_IMAGES = {
  banner: {
    url: 'https://ik.imagekit.io/xvpgfijuw/Lossless-Agent-Skills/ogimage__Lossless-Agent-Skills--BannerImage.jpg',
    width: 1312,
    height: 736,
    type: 'image/jpeg',
    alt: 'Lossless Agent Skills — humanoid teenager robots at the gym, building skills',
  },
  bannerTall: {
    url: 'https://ik.imagekit.io/xvpgfijuw/Lossless-Agent-Skills/ogimage__Lossless-Agent-Skills--BannerImageTall.jpg',
    width: 896,
    height: 1120,
    type: 'image/jpeg',
    alt: 'Lossless Agent Skills — humanoid teenager robots overhead-pressing barbells',
  },
  portrait: {
    url: 'https://ik.imagekit.io/xvpgfijuw/Lossless-Agent-Skills/ogimage__Lossless-Agent-Skills--PortraitImage.jpg',
    width: 736,
    height: 1312,
    type: 'image/jpeg',
    alt: 'Lossless Agent Skills — robots squatting and bench-pressing in a row',
  },
  square: {
    url: 'https://ik.imagekit.io/xvpgfijuw/Lossless-Agent-Skills/ogimage__Lossless-Agent-Skills--SquareImage.jpg',
    width: 1024,
    height: 1024,
    type: 'image/jpeg',
    alt: 'Lossless Agent Skills — humanoid teenager robots pumping iron at the gym',
  },
} as const;

/**
 * Priority-ordered stack emitted as multiple og:image meta tags.
 * First entry is what most aggregators pick (WhatsApp, iMessage, Slack,
 * Discord — chat-preview clients that scrape og: tags top-down).
 * Per Lossless open-graph-share-seo-geo skill: chat-preview surfaces are
 * the primary target; landscape banner is the fallback.
 */
export const OG_IMAGE_STACK = [
  OG_IMAGES.square,       // 1:1 — WhatsApp / iMessage / Slack / Discord
  OG_IMAGES.banner,       // 16:9 — Twitter fallback / Slack / generic
  OG_IMAGES.bannerTall,   // 4:5 — LinkedIn / Facebook best-fit portrait
  OG_IMAGES.portrait,     // 9:16 — Stories / Reels / TikTok alt
] as const;

/** Primary og:image (first of the stack). */
export const DEFAULT_OG = OG_IMAGES.square;

/** Twitter Card image — summary_large_image requires 16:9. */
export const TWITTER_OG = OG_IMAGES.banner;

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
