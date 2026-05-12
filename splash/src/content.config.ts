import { defineCollection, z } from 'astro:content';
import { readFile, glob as fsGlob } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { parseFrontmatter } from '@loaders/frontmatter';

// ─── Lenient preprocessors — never throw on author-written frontmatter ────
// SKILL.md frontmatter varies (name vs title, status presence, tags shapes).
// Lenient in, structured out — the loader's fallback path keeps the page
// rendering even when validation fails.

const lenientString = z.preprocess(
  (v) => (v === '' || v === null ? undefined : v),
  z.string().optional(),
);

const lenientStringArray = z.preprocess(
  (v) => {
    if (v === '' || v === null || v === undefined) return undefined;
    if (Array.isArray(v)) return v.map(String);
    if (typeof v === 'string') return [v];
    return v;
  },
  z.array(z.string()).optional(),
);

const lenientDate = z.preprocess(
  (v) => {
    if (v === undefined || v === null || v === '') return undefined;
    if (v instanceof Date) return Number.isNaN(v.getTime()) ? undefined : v;
    if (typeof v === 'number') {
      const d = new Date(v);
      return Number.isNaN(d.getTime()) ? undefined : d;
    }
    if (typeof v === 'string') {
      const t = v.trim();
      if (t === '' || t === '[]' || t === '~' || t === 'TBD' || t === 'tbd') return undefined;
      const d = new Date(t);
      return Number.isNaN(d.getTime()) ? undefined : d;
    }
    return undefined;
  },
  z.date().optional(),
);

const lenientNumber = z.preprocess(
  (v) => (v === '' || v === null ? undefined : v),
  z.number().optional(),
);

const lenientBoolean = z.preprocess(
  (v) => (v === '' || v === null ? undefined : v),
  z.boolean().optional(),
);

// ─── Paths — splash/ lives one level inside the repo root ─────────────────

const SPLASH_DIR = process.cwd();
const PARENT_DIR = resolve(SPLASH_DIR, '..');
const PARENT_CHANGELOG = resolve(PARENT_DIR, 'changelog');

// ─── Skills loader — auto-discover <repo>/<slug>/SKILL.md (depth 1 + 2) ───
// Depth 1: top-level skills (this repo's own).
// Depth 2: submodule-hosted skills (e.g. chroma-agent-skills/chroma-cloud/).
// Skip splash/, node_modules/, dist/, .astro/, .git/.

const SKILL_EXCLUDES = new Set([
  'splash', 'node_modules', 'dist', '.astro', '.git', 'public',
]);

interface LocalLoaderOptions {
  dir: string;
  collectionName: string;
  provenance: string;
}

function skillsLoader() {
  return {
    name: 'skills-loader',
    load: async ({ store, parseData, logger }: any): Promise<void> => {
      store.clear();
      let loaded = 0;
      let skipped = 0;

      const patterns = ['*/SKILL.md', '*/*/SKILL.md'];

      for (const pattern of patterns) {
        try {
          for await (const file of fsGlob(pattern, { cwd: PARENT_DIR })) {
            const topDir = file.split('/')[0];
            if (SKILL_EXCLUDES.has(topDir)) continue;

            const abs = resolve(PARENT_DIR, file);
            const text = await readFile(abs, 'utf8');
            const { data, body } = parseFrontmatter(text);

            if ((data as any).publish === false) { skipped++; continue; }

            // Slug: parent directory path with slashes replaced — keeps
            // chroma-agent-skills/chroma-cloud distinct from siblings.
            const id = dirname(file).replace(/\//g, '__');
            const merged = {
              ...data,
              // Normalize: SKILL.md uses `name`, the rest of the site uses `title`.
              title: (data as any).title ?? (data as any).name ?? id,
              from: (data as any).from ?? 'lossless-agent-skills',
              from_path: (data as any).from_path ?? file,
              dir_name: dirname(file),
            };

            const parsed = await safeParse({ id, data: merged }, parseData, logger);
            store.set({ id, data: parsed, body });
            loaded++;
          }
        } catch (err) {
          if ((err as NodeJS.ErrnoException).code !== 'ENOENT') throw err;
        }
      }

      logger.info(`[skills] ${loaded} loaded — ${skipped} skipped(publish:false).`);
    },
  };
}

function localLoader(options: LocalLoaderOptions) {
  return {
    name: `local-loader:${options.collectionName}`,
    load: async ({ store, parseData, logger }: any): Promise<void> => {
      store.clear();
      let loaded = 0;
      let skipped = 0;

      try {
        for await (const file of fsGlob('**/*.md', { cwd: options.dir })) {
          const abs = resolve(options.dir, file);
          const text = await readFile(abs, 'utf8');
          const { data, body } = parseFrontmatter(text);
          const idBase = file.replace(/\.md$/, '');

          if ((data as any).publish === false) { skipped++; continue; }

          const merged = {
            ...data,
            from: (data as any).from ?? options.provenance,
            from_path: (data as any).from_path ?? file,
          };

          const id = idBase;
          const parsed = await safeParse({ id, data: merged }, parseData, logger);
          store.set({ id, data: parsed, body });
          loaded++;
        }
      } catch (err) {
        if ((err as NodeJS.ErrnoException).code !== 'ENOENT') throw err;
      }

      logger.info(`[${options.collectionName}] ${loaded} loaded — ${skipped} skipped(publish:false).`);
    },
  };
}

async function safeParse(
  args: { id: string; data: unknown },
  parseData: (a: { id: string; data: unknown }) => Promise<unknown>,
  logger: { warn: (msg: string) => void },
): Promise<Record<string, unknown>> {
  try {
    return (await parseData(args)) as Record<string, unknown>;
  } catch (err) {
    logger.warn(`schema couldn't validate ${args.id} (${(err as Error).message}); storing raw frontmatter.`);
    return { ...(args.data as Record<string, unknown>) };
  }
}

// ─── Schemas ──────────────────────────────────────────────────────────────

const provenanceFields = {
  from: lenientString,
  from_path: lenientString,
};

const skillSchema = z
  .object({
    ...provenanceFields,

    // SKILL.md spec uses `name` + `description`. We normalize `name` → `title`
    // in the loader so the rest of the site can stay consistent.
    title: lenientString,
    name: lenientString,
    description: lenientString,
    lede: lenientString,
    status: lenientString,
    dir_name: lenientString,

    tags: lenientStringArray,
    authors: lenientStringArray,

    image: lenientString,
    image_prompt: lenientString,
  })
  .passthrough();

const changelogSchema = z
  .object({
    ...provenanceFields,

    title: lenientString,
    lede: lenientString,
    summary: lenientString,
    description: lenientString,

    date: lenientDate,
    date_authored_initial_draft: lenientDate,
    date_authored_current_draft: lenientDate,
    date_authored_final_draft: lenientDate,
    date_first_published: lenientDate,
    date_last_updated: lenientDate,
    date_created: lenientDate,
    date_modified: lenientDate,

    category: lenientString,
    status: lenientString,
    at_semantic_version: lenientString,
    semantic_version: lenientString,
    augmented_with: lenientStringArray,
    publish: lenientBoolean,
    usage_index: lenientNumber,

    tags: lenientStringArray,
    authors: lenientStringArray,
    files_added: lenientStringArray,
    files_modified: lenientStringArray,
    files_removed: lenientStringArray,
    files_changed: lenientStringArray,

    image: lenientString,
    image_prompt: lenientString,
    image_text: lenientString,
    banner_image: lenientString,
    portrait_image: lenientString,
    square_image: lenientString,
  })
  .passthrough();

// ─── Collections ──────────────────────────────────────────────────────────

const skills = defineCollection({
  loader: skillsLoader(),
  schema: skillSchema,
});

const changelog = defineCollection({
  loader: localLoader({
    collectionName: 'changelog',
    dir: PARENT_CHANGELOG,
    provenance: 'lossless-agent-skills',
  }),
  schema: changelogSchema,
});

export const collections = {
  skills,
  changelog,
};
