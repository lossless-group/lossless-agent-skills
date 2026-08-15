#!/usr/bin/env node
/**
 * prep-images.mjs — screenshots → resized, stripped, renamed, uploaded, embeddable.
 *
 * Does the MECHANICAL half of the pipeline. The judgement half — which images
 * matter, what each one is called, and what its alt text says — belongs to the
 * agent, and this script refuses to run without it (see --alt).
 *
 *   node prep-images.mjs \
 *     --slug plane-first-deploy \
 *     --repo self-host-stack \
 *     --src "~/Desktop/Screenshot 2026-08-14 at 9.11.31 PM.png" \
 *     --name "Railway__Usage-By-Project" \
 *     --alt "Railway usage dashboard showing $46.59 current usage across six client projects"
 *
 * Batch: repeat --src/--name/--alt as triples, in order.
 *
 * Flags:
 *   --slug     required. Content slug (changelog entry, page). Groups the set.
 *   --repo     required. Repo name; becomes the ImageKit folder root.
 *   --src      required, repeatable. Source image path (~ expanded).
 *   --name     required, repeatable. BEM semantic name: Block__Element--Modifier.
 *              Train-Cased automatically. e.g. "Plane__Work-Items--Empty"
 *   --alt      required, repeatable. Real alt text. Refuses placeholders.
 *   --format   jpg (default) | webp. Upload JPEG — ImageKit converts to WebP
 *              for browsers that accept it AND serves JPEG to those that do not.
 *              Uploading WebP makes the fallback a PNG up to 3x larger. Measured.
 *   --width    max width in px (default 1600). Images smaller are left alone.
 *   --quality  encoder quality (default 82).
 *   --staging  staging dir (default <cwd>/.image-staging)
 *   --emit     md (default) | lfm | html | figure | json
 *              lfm  → ::image{...} directive for Lossless sites (richest)
 *              html → <img> with width/height (best CLS outside LFM)
 *
 * Folder ops (no other flags needed):
 *   --list-folder  /repo/slug     list what is already uploaded there
 *   --purge-folder /repo/slug     delete everything there (irreversible)
 *   --dry-run  do everything except upload.
 */

import { readFileSync, existsSync, mkdirSync, statSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { basename, extname, join, resolve } from "node:path";
import { homedir } from "node:os";

// ---------- args ----------
const argv = process.argv.slice(2);
const many = { src: [], name: [], alt: [], caption: [] };
const one = {};
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (!a.startsWith("--")) continue;
  const k = a.slice(2);
  if (k === "dry-run") { one["dry-run"] = true; continue; }
  const v = argv[++i];
  if (k in many) many[k].push(v);
  else one[k] = v;
}

const cfg = {
  slug: one.slug,
  repo: one.repo,
  format: (one.format || "jpg").toLowerCase(),
  width: parseInt(one.width || "1600", 10),
  quality: parseInt(one.quality || "82", 10),
  staging: resolve(one.staging || join(process.cwd(), ".image-staging")),
  emit: one.emit || "md",
  dryRun: !!one["dry-run"],
};

const die = (m) => { console.error(`\n✗ ${m}\n`); process.exit(1); };

const FOLDER_OP = one["list-folder"] || one["purge-folder"];
if (!FOLDER_OP) {
if (!cfg.slug) die("--slug is required (the content slug this set belongs to)");
if (!cfg.repo) die("--repo is required (becomes the ImageKit folder root)");
if (!many.src.length) die("--src is required (at least one source image)");
if (many.name.length !== many.src.length) die("--name must be given once per --src");
if (many.alt.length !== many.src.length) die("--alt must be given once per --src");
if (!["webp", "jpg"].includes(cfg.format)) die("--format must be webp or jpg");
}

// Alt text is the entire accessibility and SEO payload. A placeholder is worse
// than nothing because it looks done. Reject the obvious ones.
const LAZY_ALT = /^(image|screenshot|photo|picture|graphic|img|untitled|tbd|todo)\b/i;
many.alt.forEach((alt, i) => {
  if (!alt || alt.trim().length < 15)
    die(`--alt[${i}] too short. Describe what the image SHOWS, not that it is an image.`);
  if (LAZY_ALT.test(alt.trim()))
    die(`--alt[${i}] starts with a placeholder word ("${alt.trim().split(/\s+/)[0]}"). Alt text describes content — a reader who cannot see the image should learn the same thing a viewer would.`);
});

const expand = (p) => (p.startsWith("~") ? join(homedir(), p.slice(1)) : p);
const kebab = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

// Train-Case each BEM segment while preserving the `__` and `--` separators.
// Matches the house convention already used by ogimage__Lossless-At--Banner.jpg.
//
// TITLE case, not naive capitalize-every-word: minor words (articles, short
// prepositions, conjunctions) stay lowercase unless they lead or close a
// segment. So `Image-of-Amy`, not `Image-Of-Amy`.
const MINOR = new Set([
  "a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "nor", "of",
  "on", "or", "per", "so", "the", "to", "v", "vs", "via", "with", "yet",
]);

const titleWord = (w, isFirst, isLast) =>
  !isFirst && !isLast && MINOR.has(w.toLowerCase())
    ? w.toLowerCase()
    : w[0].toUpperCase() + w.slice(1);

const trainCase = (s) =>
  String(s)
    .split(/(__|--)/)
    .map((part) => {
      if (part === "__" || part === "--") return part;
      const words = part.split(/[^a-zA-Z0-9]+/).filter(Boolean);
      return words
        .map((w, i) => titleWord(w, i === 0, i === words.length - 1))
        .join("-");
    })
    .join("");

// ISO 8601 BASIC format, UTC. Not a homemade "filesystem-safe variant" — basic
// format IS the standard answer to separators that break filenames and URLs.
// UTC because a local stamp with no offset is ambiguous forever after.
const isoStamp = () => new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");

// ---------- secrets ----------
const secretsPath = join(homedir(), ".secrets");
if (!existsSync(secretsPath)) die("~/.secrets not found — ImageKit credentials live there");
const secrets = readFileSync(secretsPath, "utf8");
const secret = (k) => secrets.match(new RegExp(`^(?:export\\s+)?${k}=(.*)$`, "m"))?.[1]?.trim().replace(/^["']|["']$/g, "");
const IK_PRIVATE = secret("IMAGEKIT_PRIVATE_KEY");
const IK_ENDPOINT = secret("IMAGEKIT_URL_ENDPOINT");
if (!cfg.dryRun && !IK_PRIVATE) die("IMAGEKIT_PRIVATE_KEY missing from ~/.secrets");

// ---------- tooling ----------
const has = (bin) => { try { execFileSync("command", ["-v", bin], { shell: true, stdio: "pipe" }); return true; } catch { return false; } };
if (cfg.format === "webp") {
  if (!has("cwebp")) die("cwebp not found (brew install webp). sips cannot write WebP.");
  console.error(
    "  ! --format webp: ImageKit serves a PNG fallback (measured 3x larger than the\n" +
    "    WebP) to clients that do not advertise WebP, including unfurlers. Prefer jpg\n" +
    "    and let the CDN negotiate. See the skill's Format section.",
  );
}

// ---------- folder operations (ImageKit folders are implicit on upload, but
// listing and purging need the management API) ----------
const ikAuth = () => `Basic ${Buffer.from(`${IK_PRIVATE}:`).toString("base64")}`;

async function listFolder(path) {
  const res = await fetch(
    `https://api.imagekit.io/v1/files?path=${encodeURIComponent(path)}&limit=100`,
    { headers: { Authorization: ikAuth() } },
  );
  const j = await res.json().catch(() => []);
  return Array.isArray(j) ? j : [];
}

if (one["list-folder"]) {
  const path = one["list-folder"];
  const files = await listFolder(path);
  if (!files.length) console.log(`(empty or missing): ${path}`);
  for (const f of files)
    console.log(`${f.fileId}  ${String(f.size).padStart(8)}B  ${f.name}`);
  process.exit(0);
}

if (one["purge-folder"]) {
  const path = one["purge-folder"];
  const files = await listFolder(path);
  if (!files.length) { console.log(`nothing to purge in ${path}`); process.exit(0); }
  console.log(`purging ${files.length} file(s) from ${path}`);
  for (const f of files) {
    const res = await fetch(`https://api.imagekit.io/v1/files/${f.fileId}`, {
      method: "DELETE",
      headers: { Authorization: ikAuth() },
    });
    console.log(`  ${res.ok ? "deleted" : "FAILED " + res.status}  ${f.name}`);
  }
  process.exit(0);
}

mkdirSync(cfg.staging, { recursive: true });

const kb = (p) => (statSync(p).size / 1024).toFixed(0);
const dims = (p) => {
  const out = execFileSync("sips", ["-g", "pixelWidth", "-g", "pixelHeight", p], { encoding: "utf8" });
  return {
    w: +(out.match(/pixelWidth:\s*(\d+)/)?.[1] || 0),
    h: +(out.match(/pixelHeight:\s*(\d+)/)?.[1] || 0),
  };
};

// ---------- process ----------
const STAMP = isoStamp();
const results = [];

for (let i = 0; i < many.src.length; i++) {
  const src = expand(many.src[i]);
  if (!existsSync(src)) die(`source not found: ${src}`);

  // Semantics first (filenames are a ranking signal), timestamp last (uniqueness,
  // and it removes the overwrite-a-live-URL hazard entirely).
  const stem = `${trainCase(many.name[i])}_${STAMP}`;
  const outPath = join(cfg.staging, `${stem}.${cfg.format}`);
  const before = kb(src);
  const srcDims = dims(src);

  // Resize into a temp PNG first so the encoder gets clean input, and strip
  // metadata — screenshots can carry window titles, device info, and location.
  const tmp = join(cfg.staging, `.tmp-${stem}.png`);
  execFileSync("sips", ["-s", "format", "png", src, "--out", tmp], { stdio: "pipe" });
  if (srcDims.w > cfg.width) execFileSync("sips", ["-Z", String(cfg.width), tmp], { stdio: "pipe" });
  if (has("exiftool")) {
    try { execFileSync("exiftool", ["-all=", "-overwrite_original", tmp], { stdio: "pipe" }); } catch {}
  }

  if (cfg.format === "webp") {
    execFileSync("cwebp", ["-q", String(cfg.quality), "-m", "6", tmp, "-o", outPath], { stdio: "pipe" });
  } else {
    execFileSync("sips", ["-s", "format", "jpeg", "-s", "formatOptions", String(cfg.quality), tmp, "--out", outPath], { stdio: "pipe" });
  }
  execFileSync("rm", ["-f", tmp]);

  const finalDims = dims(outPath);
  const after = kb(outPath);

  let url = null;
  if (!cfg.dryRun) {
    const folder = `/${kebab(cfg.repo)}/${kebab(cfg.slug)}`;
    const auth = Buffer.from(`${IK_PRIVATE}:`).toString("base64");
    const form = new FormData();
    form.append("file", new Blob([readFileSync(outPath)]), `${stem}.${cfg.format}`);
    form.append("fileName", `${stem}.${cfg.format}`);
    form.append("folder", folder);
    // The ISO stamp already makes every capture unique, so ImageKit's random
    // suffix would only add noise. Overwrite is safe for the same reason: a
    // collision means the identical capture, not a different one.
    form.append("useUniqueFileName", "false");
    form.append("overwriteFile", "true");
    form.append("tags", [kebab(cfg.repo), kebab(cfg.slug), "screenshot"].join(","));
    const res = await fetch("https://upload.imagekit.io/api/v1/files/upload", {
      method: "POST",
      headers: { Authorization: `Basic ${auth}` },
      body: form,
    });
    const j = await res.json().catch(() => ({}));
    if (!res.ok || !j.url) die(`upload failed for ${stem} (HTTP ${res.status}): ${JSON.stringify(j).slice(0, 240)}`);
    url = j.url;
  }

  results.push({
    stem, url, alt: many.alt[i].trim(),
    width: finalDims.w, height: finalDims.h,
    caption: many.caption[i] || null,
    localPath: outPath,
    beforeKb: +before, afterKb: +after,
    savedPct: Math.round((1 - after / before) * 100),
  });

  console.error(
    `  ${stem}.${cfg.format}  ${srcDims.w}×${srcDims.h} → ${finalDims.w}×${finalDims.h}  ` +
    `${before}KB → ${after}KB (−${results.at(-1).savedPct}%)${url ? "" : "  [dry-run]"}`,
  );
}

// ---------- emit ----------
console.error("");
const out = [];
for (const r of results) {
  const href = r.url || `DRY-RUN-NO-URL#${r.stem}`;  // parens in a placeholder break markdown link syntax
  if (cfg.emit === "json") continue;
  if (cfg.emit === "md") {
    // Plain markdown: maximum portability. No dimensions, so expect layout
    // shift — use html/figure where the renderer allows it.
    out.push(`![${r.alt}](${href})`);
  } else if (cfg.emit === "html") {
    out.push(
      `<img src="${href}" alt="${r.alt}" width="${r.width}" height="${r.height}" loading="lazy" decoding="async" />`,
    );
  } else if (cfg.emit === "lfm") {
    // Lossless Flavored Markdown ::image directive — the richest target on our
    // own sites. Rendered by src/components/markdown/MarkdownImage.astro, which
    // supports caption, source, source-url, float, caption-position and more.
    const parts = [`src="${href}"`, `alt="${r.alt}"`];
    if (r.caption) parts.push(`caption="${r.caption}"`);
    out.push(`::image{${parts.join(" ")}}`);
  } else if (cfg.emit === "figure") {
    out.push(
      `<figure>\n  <img src="${href}" alt="${r.alt}" width="${r.width}" height="${r.height}" loading="lazy" decoding="async" />\n  <figcaption>${r.alt}</figcaption>\n</figure>`,
    );
  }
}
if (cfg.emit === "json") console.log(JSON.stringify({ endpoint: IK_ENDPOINT, images: results }, null, 2));
else console.log(out.join("\n\n"));

const totalBefore = results.reduce((a, r) => a + r.beforeKb, 0);
const totalAfter = results.reduce((a, r) => a + r.afterKb, 0);
console.error(
  `\n${results.length} image(s)  ${totalBefore}KB → ${totalAfter}KB ` +
  `(−${Math.round((1 - totalAfter / totalBefore) * 100)}%)  staged in ${cfg.staging}`,
);
