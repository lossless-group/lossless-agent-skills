#!/usr/bin/env -S pnpx tsx
/**
 * Jina Reader wrapper.
 *
 * Converts any URL to clean markdown via r.jina.ai. Faster + cheaper than Firecrawl
 * when you just need a page's content. Use Firecrawl when you need structured extraction.
 *
 * Reads JINA_API_KEY from env (optional — Jina Reader has a free tier without auth, but the
 * key gives higher rate limits). Sourced from ~/.secrets via .zshenv.
 *
 * Usage:
 *   ./jina-reader.ts <url>
 *   ./jina-reader.ts <url> --cache-dir ~/.claude/skills/crawl-fetch-ingest/cache/{firm-slug}/jina
 *
 * Output: markdown to stdout. Exits non-zero on error.
 */

import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

const READER_BASE = "https://r.jina.ai";

function parseArgs(argv: string[]): { url: string; cacheDir?: string } {
  const args = argv.slice(2);
  if (args.length === 0) {
    console.error("Usage: jina-reader.ts <url> [--cache-dir <path>]");
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

async function readCache(cacheDir: string, url: string): Promise<string | null> {
  const path = join(cacheDir, `${hashUrl(url)}.md`);
  if (!existsSync(path)) return null;
  try {
    return await readFile(path, "utf8");
  } catch {
    return null;
  }
}

async function writeCache(cacheDir: string, url: string, content: string): Promise<void> {
  const path = join(cacheDir, `${hashUrl(url)}.md`);
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, content, "utf8");
}

async function fetchReader(url: string, apiKey?: string): Promise<string> {
  const endpoint = `${READER_BASE}/${url}`;
  const headers: Record<string, string> = { Accept: "text/markdown" };
  if (apiKey) headers.Authorization = `Bearer ${apiKey}`;
  const res = await fetch(endpoint, { headers });
  if (!res.ok) {
    throw new Error(`Jina Reader returned ${res.status}: ${await res.text()}`);
  }
  return res.text();
}

async function main() {
  const { url, cacheDir } = parseArgs(process.argv);
  const apiKey = process.env.JINA_API_KEY;

  if (cacheDir) {
    const cached = await readCache(cacheDir, url);
    if (cached) {
      process.stdout.write(cached);
      return;
    }
  }

  const content = await fetchReader(url, apiKey);
  if (cacheDir) await writeCache(cacheDir, url, content);
  process.stdout.write(content);
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});
