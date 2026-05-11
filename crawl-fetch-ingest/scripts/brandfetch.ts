#!/usr/bin/env -S pnpx tsx
/**
 * Brandfetch API wrapper.
 *
 * Fetches brand assets (logo SVG/PNG, brand colors, fonts, social profiles) for a domain.
 * This is tier 4 of the logo cascade documented in SKILL.md "Logo asset cascade".
 *
 * Reads BRANDFETCH_API_KEY from env (sourced from ~/.secrets via .zshenv).
 * Free tier: 1k requests/month. Get a key at https://brandfetch.com/developers.
 *
 * Usage:
 *   ./brandfetch.ts <domain>
 *   ./brandfetch.ts <domain> --cache-dir ~/.claude/skills/crawl-fetch-ingest/cache/{firm-slug}/brandfetch
 *   ./brandfetch.ts <domain> --best-svg     # print only the best SVG URL (or non-zero if none)
 *   ./brandfetch.ts <domain> --best-raster  # print only the best raster URL (or non-zero if none)
 *   ./brandfetch.ts <domain> --save-all --out-dir <dir> --company-name "<Display Name>"
 *                                            # download each available asset (wordmark, appIcon, favicon)
 *                                            # to <out-dir> using the role-prefixed naming convention
 *                                            # documented in schema/company.md.
 *
 * Default output: full JSON response from Brandfetch (cached).
 * --best-svg / --best-raster modes: one URL on stdout, suitable for `curl -o`.
 * --save-all mode: prints a JSON manifest of {role, path, source_url} entries written to disk.
 *
 * Exit codes:
 *   0  — success
 *   1  — API error
 *   2  — bad arguments / missing API key
 *   3  — --best-svg or --best-raster requested but none available in the response
 */

import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

const API_BASE = "https://api.brandfetch.io/v2/brands";

interface BrandfetchLogo {
  type?: string; // "logo" | "icon" | "symbol" | "other"
  theme?: string; // "light" | "dark"
  formats?: Array<{
    src: string;
    background?: string | null; // "transparent" | hex | null
    format: string; // "svg" | "png" | "webp" | "jpeg"
    height?: number;
    width?: number;
    size?: number;
  }>;
}

interface BrandfetchResponse {
  name?: string;
  domain?: string;
  description?: string;
  longDescription?: string;
  logos?: BrandfetchLogo[];
  colors?: Array<{ hex: string; type: string; brightness: number }>;
  fonts?: Array<{ name: string; type: string; origin: string }>;
  links?: Array<{ name: string; url: string }>;
  qualityScore?: number;
}

function parseArgs(argv: string[]): {
  domain: string;
  cacheDir?: string;
  mode: "json" | "best-svg" | "best-raster" | "save-all";
  outDir?: string;
  companyName?: string;
} {
  const args = argv.slice(2);
  if (args.length === 0) {
    console.error(
      "Usage: brandfetch.ts <domain> [--cache-dir <path>] [--best-svg | --best-raster | --save-all --out-dir <dir> --company-name \"<Display Name>\"]"
    );
    process.exit(2);
  }
  let domain = args[0];
  // Normalize: strip protocol + path, keep only host
  domain = domain.replace(/^https?:\/\//, "").replace(/\/.*$/, "");
  let cacheDir: string | undefined;
  let mode: "json" | "best-svg" | "best-raster" | "save-all" = "json";
  let outDir: string | undefined;
  let companyName: string | undefined;
  for (let i = 1; i < args.length; i++) {
    if (args[i] === "--cache-dir" && args[i + 1]) {
      cacheDir = args[i + 1];
      i++;
    } else if (args[i] === "--best-svg") {
      mode = "best-svg";
    } else if (args[i] === "--best-raster") {
      mode = "best-raster";
    } else if (args[i] === "--save-all") {
      mode = "save-all";
    } else if (args[i] === "--out-dir" && args[i + 1]) {
      outDir = args[i + 1];
      i++;
    } else if (args[i] === "--company-name" && args[i + 1]) {
      companyName = args[i + 1];
      i++;
    }
  }
  if (mode === "save-all" && (!outDir || !companyName)) {
    console.error("--save-all requires --out-dir <dir> and --company-name \"<Display Name>\"");
    process.exit(2);
  }
  return { domain, cacheDir, mode, outDir, companyName };
}

/**
 * Convert a free-form display name into the Train-Case form used in asset filenames.
 * Rules:
 *   - Normalize Unicode to ASCII (strip diacritics — "Béa" → "Bea")
 *   - Strip leading non-alphanumeric chars (".inne" → "inne")
 *   - Split on whitespace / hyphen / slash / dot — these all become hyphens
 *   - Title-case each resulting word (first letter caps, rest lowercase)
 *   - Drop any remaining non-alphanumeric / non-hyphen chars
 * Examples:
 *   "Foundation Health"   -> "Foundation-Health"
 *   "9am Health"          -> "9am-Health"
 *   "9am.health"          -> "9am-Health"
 *   ".inne"               -> "Inne"
 *   "EVERYMAN"            -> "Everyman"
 *   "thymia"              -> "Thymia"
 *   "Béa Fertility"       -> "Bea-Fertility"
 *   "Calm/Storm Ventures" -> "Calm-Storm-Ventures"
 *   "aeon*"               -> "Aeon"
 */
function trainCase(displayName: string): string {
  return displayName
    .normalize("NFD").replace(/[̀-ͯ]/g, "")  // strip diacritics
    .replace(/^[^A-Za-z0-9]+/, "")
    .split(/[\s\-/.]+/)
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join("-")
    .replace(/[^A-Za-z0-9-]/g, "");
}

/**
 * Categorize Brandfetch logos into the four roles used by the file-naming convention.
 *
 *   wordmark  — type=logo (the spelled-out name, possibly combined with an icon)
 *   appIcon   — type=symbol or type=icon (when distinct from wordmark)
 *   favicon   — explicitly favicon-scale icon (we approximate with the smallest icon format)
 *   trademark — fallback for the single-mark case (no separate appIcon)
 */
interface AssetPick {
  role: "trademark" | "wordmark" | "appIcon" | "favicon";
  url: string;
  format: string;
  background?: string | null;
}

function pickAssetsForSaving(data: BrandfetchResponse): AssetPick[] {
  if (!data.logos) return [];
  const logos = data.logos;
  const hasLogo = logos.some((l) => l.type === "logo");
  const hasSymbol = logos.some((l) => l.type === "symbol" || l.type === "icon");

  const picked: AssetPick[] = [];

  // Format priority within a logo entry: SVG > PNG (transparent) > WebP > anything else
  const pickBestFormat = (logo: BrandfetchLogo): { src: string; format: string; background?: string | null } | null => {
    const formats = logo.formats ?? [];
    const transparentSvg = formats.find((f) => f.format === "svg" && (f.background === "transparent" || f.background == null));
    if (transparentSvg) return { src: transparentSvg.src, format: "svg", background: transparentSvg.background };
    const anySvg = formats.find((f) => f.format === "svg");
    if (anySvg) return { src: anySvg.src, format: "svg", background: anySvg.background };
    const transparentPng = formats.find((f) => f.format === "png" && (f.background === "transparent" || f.background == null));
    if (transparentPng) return { src: transparentPng.src, format: "png", background: transparentPng.background };
    const anyPng = formats.find((f) => f.format === "png");
    if (anyPng) return { src: anyPng.src, format: "png", background: anyPng.background };
    const anyOther = formats[0];
    return anyOther ? { src: anyOther.src, format: anyOther.format, background: anyOther.background } : null;
  };

  if (hasLogo && hasSymbol) {
    // Both wordmark and standalone icon → save each with its dedicated role
    const wordmarkLogo = logos.find((l) => l.type === "logo" && l.theme === "light")
      ?? logos.find((l) => l.type === "logo");
    const symbolLogo = logos.find((l) => (l.type === "symbol" || l.type === "icon") && l.theme === "light")
      ?? logos.find((l) => l.type === "symbol" || l.type === "icon");
    const wordmark = wordmarkLogo ? pickBestFormat(wordmarkLogo) : null;
    const appIcon = symbolLogo ? pickBestFormat(symbolLogo) : null;
    if (wordmark) picked.push({ role: "wordmark", url: wordmark.src, format: wordmark.format, background: wordmark.background });
    if (appIcon) picked.push({ role: "appIcon", url: appIcon.src, format: appIcon.format, background: appIcon.background });
  } else {
    // Single-mark case → trademark
    const primary = logos.find((l) => l.type === "logo" && l.theme === "light")
      ?? logos.find((l) => l.type === "logo")
      ?? logos.find((l) => l.type === "symbol" || l.type === "icon")
      ?? logos[0];
    const best = primary ? pickBestFormat(primary) : null;
    if (best) picked.push({ role: "trademark", url: best.src, format: best.format, background: best.background });
  }

  // Favicon — Brandfetch sometimes returns a dedicated icon with no theme; we treat the
  // smallest icon-type asset as the favicon if one exists distinct from the appIcon.
  const faviconCandidates = logos
    .filter((l) => l.type === "icon")
    .flatMap((l) => l.formats ?? []);
  if (faviconCandidates.length > 0) {
    // Prefer SVG, else smallest PNG
    const svg = faviconCandidates.find((f) => f.format === "svg");
    if (svg) {
      // Only add if not already present as appIcon
      if (!picked.some((p) => p.role === "appIcon" && p.url === svg.src)) {
        picked.push({ role: "favicon", url: svg.src, format: "svg", background: svg.background });
      }
    } else {
      const png = faviconCandidates.filter((f) => f.format === "png").sort((a, b) => (a.width ?? 0) - (b.width ?? 0))[0];
      if (png && !picked.some((p) => p.role === "appIcon" && p.url === png.src)) {
        picked.push({ role: "favicon", url: png.src, format: "png", background: png.background });
      }
    }
  }

  return picked;
}

function hashKey(key: string): string {
  return createHash("sha1").update(key).digest("hex").slice(0, 16);
}

async function readCache(cacheDir: string, key: string): Promise<unknown | null> {
  const path = join(cacheDir, `${hashKey(key)}.json`);
  if (!existsSync(path)) return null;
  try {
    return JSON.parse(await readFile(path, "utf8"));
  } catch {
    return null;
  }
}

async function writeCache(cacheDir: string, key: string, data: unknown): Promise<void> {
  const path = join(cacheDir, `${hashKey(key)}.json`);
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, JSON.stringify(data, null, 2), "utf8");
}

async function fetchBrand(domain: string, apiKey: string): Promise<BrandfetchResponse> {
  const endpoint = `${API_BASE}/${encodeURIComponent(domain)}`;
  const res = await fetch(endpoint, {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  if (!res.ok) {
    throw new Error(`Brandfetch returned ${res.status}: ${await res.text()}`);
  }
  return (await res.json()) as BrandfetchResponse;
}

/**
 * Pick the best SVG logo from a Brandfetch response.
 * Priority: type=logo + theme=light > type=logo + any theme > type=symbol > type=icon.
 * Within each tier, prefers transparent background.
 */
function pickBestSvg(data: BrandfetchResponse): string | null {
  if (!data.logos) return null;
  const tiers: Array<(l: BrandfetchLogo) => boolean> = [
    (l) => l.type === "logo" && l.theme === "light",
    (l) => l.type === "logo",
    (l) => l.type === "symbol",
    (l) => l.type === "icon",
    () => true,
  ];
  for (const match of tiers) {
    for (const logo of data.logos.filter(match)) {
      const formats = logo.formats ?? [];
      // Prefer transparent-bg SVG, then any SVG
      const transparentSvg = formats.find(
        (f) => f.format === "svg" && (f.background === "transparent" || f.background == null)
      );
      if (transparentSvg) return transparentSvg.src;
      const anySvg = formats.find((f) => f.format === "svg");
      if (anySvg) return anySvg.src;
    }
  }
  return null;
}

function pickBestRaster(data: BrandfetchResponse): string | null {
  if (!data.logos) return null;
  // Prefer the largest transparent-bg PNG; fall back to any PNG, then webp.
  let best: { src: string; score: number } | null = null;
  for (const logo of data.logos) {
    if (logo.type !== "logo" && logo.type !== "symbol" && logo.type !== "icon") continue;
    for (const f of logo.formats ?? []) {
      if (f.format === "svg") continue;
      const transparent = f.background === "transparent" || f.background == null;
      const sizeScore = (f.width ?? 0) * (f.height ?? 0);
      const formatScore = f.format === "png" ? 100000 : f.format === "webp" ? 50000 : 0;
      const transparencyScore = transparent ? 200000 : 0;
      const score = sizeScore + formatScore + transparencyScore;
      if (!best || score > best.score) best = { src: f.src, score };
    }
  }
  return best?.src ?? null;
}

async function main() {
  const { domain, cacheDir, mode, outDir, companyName } = parseArgs(process.argv);
  const apiKey = process.env.BRANDFETCH_API_KEY;
  if (!apiKey) {
    console.error("BRANDFETCH_API_KEY not set. Source ~/.secrets first (and restart Claude Code).");
    process.exit(2);
  }

  let data: BrandfetchResponse | null = null;
  if (cacheDir) {
    const cached = (await readCache(cacheDir, domain)) as BrandfetchResponse | null;
    if (cached) data = cached;
  }

  if (!data) {
    data = await fetchBrand(domain, apiKey);
    if (cacheDir) await writeCache(cacheDir, domain, data);
  }

  if (mode === "best-svg") {
    const url = pickBestSvg(data);
    if (!url) {
      console.error(`brandfetch: no SVG logo available for ${domain}`);
      process.exit(3);
    }
    process.stdout.write(url + "\n");
    return;
  }

  if (mode === "best-raster") {
    const url = pickBestRaster(data);
    if (!url) {
      console.error(`brandfetch: no raster logo available for ${domain}`);
      process.exit(3);
    }
    process.stdout.write(url + "\n");
    return;
  }

  if (mode === "save-all") {
    const trainCased = trainCase(companyName!);
    const picks = pickAssetsForSaving(data);
    if (picks.length === 0) {
      console.error(`brandfetch: no usable assets for ${domain}`);
      process.exit(3);
    }
    await mkdir(outDir!, { recursive: true });
    const manifest: Array<{ role: string; path: string; source_url: string; format: string; background: string | null }> = [];
    for (const pick of picks) {
      const filename = `${pick.role}__${trainCased}.${pick.format}`;
      const out = join(outDir!, filename);
      const res = await fetch(pick.url);
      if (!res.ok) {
        console.error(`brandfetch: failed to download ${pick.url}: ${res.status}`);
        continue;
      }
      const buf = Buffer.from(await res.arrayBuffer());
      await writeFile(out, buf);
      manifest.push({
        role: pick.role,
        path: out,
        source_url: pick.url,
        format: pick.format,
        background: pick.background ?? null,
      });
    }
    process.stdout.write(JSON.stringify({ company: companyName, train_case: trainCased, assets: manifest }, null, 2));
    return;
  }

  process.stdout.write(JSON.stringify(data, null, 2));
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});
