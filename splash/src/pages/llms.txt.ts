/**
 * /llms.txt — index of lossless-agent-skills content for LLM consumers.
 * Spec: https://llmstxt.org/
 *
 * The human-editable prose template lives at `src/llms/llms.md`. This file is
 * the dumb assembler — loads the template, computes dynamic values, substitutes
 * tokens. To tweak voice or framing, edit the markdown, not this file.
 */

import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { STATIC_SEO } from '@lib/seo';
import { toDate } from '@lib/date';
import template from '../llms/llms.md?raw';

export const GET: APIRoute = async () => {
  const site = import.meta.env.SITE ?? 'https://lossless-group.github.io';
  const base = import.meta.env.BASE_URL ?? '/';
  const root = new URL(base, site).toString().replace(/\/$/, '');

  // ─── Skills (alpha by title) ────────────────────────────────────────────
  const skills = await getCollection('skills');
  skills.sort((a, b) => {
    const ta = ((a.data.title ?? a.id) as string).toLowerCase();
    const tb = ((b.data.title ?? b.id) as string).toLowerCase();
    return ta.localeCompare(tb);
  });

  const skillsLines: string[] = [];
  for (const entry of skills) {
    const data = entry.data as any;
    const title = data.title ?? data.name ?? entry.id;
    const url = `${root}/skills/${entry.id}/`;
    const lede = data.description ?? data.lede;
    skillsLines.push(lede ? `- [${title}](${url}): ${lede}` : `- [${title}](${url})`);
  }

  // ─── Changelog (date_modified desc — matches the rendered list) ─────────
  const changelogAll = await getCollection('changelog');
  const changelog = changelogAll.filter((e) => (e.data as any).publish !== false);
  changelog.sort((a, b) => {
    const da = toDate(
      (a.data as any).date_modified ??
        (a.data as any).date_first_published ??
        (a.data as any).date_created ??
        (a.data as any).date ??
        (a.data as any).date_authored_current_draft ??
        (a.data as any).date_authored_initial_draft,
    );
    const db = toDate(
      (b.data as any).date_modified ??
        (b.data as any).date_first_published ??
        (b.data as any).date_created ??
        (b.data as any).date ??
        (b.data as any).date_authored_current_draft ??
        (b.data as any).date_authored_initial_draft,
    );
    const ta = da ? da.getTime() : 0;
    const tb = db ? db.getTime() : 0;
    if (tb !== ta) return tb - ta;
    return a.id < b.id ? 1 : -1;
  });

  const changelogLines: string[] = [];
  for (const entry of changelog) {
    const data = entry.data as any;
    const title = data.title ?? entry.id;
    const url = `${root}/changelog/${entry.id}/`;
    const lede = data.lede ?? data.summary ?? data.description;
    changelogLines.push(lede ? `- [${title}](${url}): ${lede}` : `- [${title}](${url})`);
  }

  const tokens: Record<string, string> = {
    SITE_NAME: STATIC_SEO.siteName,
    SKILL_COUNT: String(skills.length),
    CHANGELOG_COUNT: String(changelog.length),
    SEARCH_URL: `${root}/search/`,
    LLMS_FULL_URL: `${root}/llms-full.txt`,
    LLMS_INDEX_URL: `${root}/llms.txt`,
    SKILLS_INDEX: skillsLines.join('\n').trimEnd(),
    CHANGELOG_INDEX: changelogLines.join('\n').trimEnd(),
  };

  const body = template.replace(/\{\{(\w+)\}\}/g, (match, name) =>
    Object.prototype.hasOwnProperty.call(tokens, name) ? tokens[name] : match,
  );

  return new Response(body, {
    headers: { 'Content-Type': 'text/markdown; charset=utf-8' },
  });
};
