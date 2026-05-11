#!/usr/bin/env -S pnpx tsx
/**
 * OpenGraph.io REST wrapper.
 *
 * Reads OPENGRAPH_IO_API_KEY from env (sourced from ~/.secrets via .zshenv).
 *
 * Usage:
 *   ./og-fetch.ts <url>
 *   ./og-fetch.ts <url> --cache-dir ~/.claude/skills/crawl-fetch-ingest/cache/{firm-slug}/og
 *
 * Output: JSON to stdout. Exits non-zero on error.
 *
 * Cache: if --cache-dir is provided, the response is keyed on sha1(url) and stored
 * as <cache-dir>/<hash>.json. Cache is checked before the API call.
 */

import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

const API_BASE = "https://opengraph.io/api/1.1/site";

function parseArgs(argv: string[]): { url: string; cacheDir?: string } {
  const args = argv.slice(2);
  if (args.length === 0) {
    console.error("Usage: og-fetch.ts <url> [--cache-dir <path>]");
    process.exit(2);
  }
  const url = args[0];
  let cacheDir: string | undefined;
  for (let i = 1; i < args.length; i++) {
    if (args[i] === "--cache-dir" && args[i + 1]) {
      cacheDir = args[i + 1];
      i++;
    }
  }
  return { url, cacheDir };
}

function hashUrl(url: string): string {
  return createHash("sha1").update(url).digest("hex").slice(0, 16);
}

async function readCache(cacheDir: string, url: string): Promise<unknown | null> {
  const path = join(cacheDir, `${hashUrl(url)}.json`);
  if (!existsSync(path)) return null;
  try {
    return JSON.parse(await readFile(path, "utf8"));
  } catch {
    return null;
  }
}

async function writeCache(cacheDir: string, url: string, data: unknown): Promise<void> {
  const path = join(cacheDir, `${hashUrl(url)}.json`);
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, JSON.stringify(data, null, 2), "utf8");
}

async function fetchOg(url: string, apiKey: string): Promise<unknown> {
  const endpoint = `${API_BASE}/${encodeURIComponent(url)}?app_id=${apiKey}`;
  const res = await fetch(endpoint);
  if (!res.ok) {
    throw new Error(`OpenGraph.io returned ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

async function main() {
  const { url, cacheDir } = parseArgs(process.argv);
  const apiKey = process.env.OPENGRAPH_IO_API_KEY;
  if (!apiKey) {
    console.error("OPENGRAPH_IO_API_KEY not set. Source ~/.secrets first.");
    process.exit(2);
  }

  if (cacheDir) {
    const cached = await readCache(cacheDir, url);
    if (cached) {
      process.stdout.write(JSON.stringify({ ...cached, _cache: "hit" }, null, 2));
      return;
    }
  }

  const data = await fetchOg(url, apiKey);
  if (cacheDir) await writeCache(cacheDir, url, data);
  process.stdout.write(JSON.stringify(data, null, 2));
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});
