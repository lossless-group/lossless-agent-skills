# Cloudflare Artifacts — operations across every surface, tiered

Source: Cloudflare's Artifacts docs (REST API page updated 2026-10-22, Workers
binding, Wrangler commands updated 2026-05-18), fetched 2026-10-25. Tiers are
this skill's: **0** read · **1** create/write · **2** destructive · **3**
account-level or lasting. See SKILL.md § Safety.

REST paths are relative to `https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID`.
`NS` = `/artifacts/namespaces/:namespace`. All JSON uses the Cloudflare v4
envelope (`result`, `success`, `errors`, `messages`, optional `result_info`).
File, raw, and blob routes return bytes.

## Namespaces

| Operation | Tier | REST | Wrangler | Binding |
|---|---|---|---|---|
| Create (with optional `jurisdiction: "eu" \| "us"`) | 1, or **3** with a jurisdiction | `POST /artifacts/namespaces` `{namespace, jurisdiction?}` | — | — (implicit on first `create`) |
| List | 0 | `GET /artifacts/namespaces?limit=&cursor=` | `artifacts namespaces list` | — |
| Get (returns `namespace`, `jurisdiction`: `"unrestricted"` when none was set, `repo_count`, `created_at`, `updated_at`; tested 2026-10-25) | 0 | `GET NS` | `artifacts namespaces get <NAME>` | — |
| Delete (must be empty; `409` if not) | **2** | `DELETE NS` → `204` | — | — |

## Repos

| Operation | Tier | REST | Wrangler | Binding (`env.ARTIFACTS`, one namespace) |
|---|---|---|---|---|
| Create `{name, description?, default_branch?, read_only?}`, returns `remote` + `token` | 1 | `POST NS/repos` | `artifacts repos create <NAME> --namespace` | `create(name, opts?)` |
| List (`limit` ≤200, `cursor`, `search`, `sort` created_at\|updated_at\|last_push_at\|name, `direction`) | 0 | `GET NS/repos` | `artifacts repos list --namespace` | `list(opts?)` |
| Get (includes `remote`, `read_only`, `source`, `last_push_at`) | 0 | `GET NS/repos/:name` | `artifacts repos get <NAME> --namespace` | `get(name)` → handle; `handle.info()` |
| Delete (`202`, asynchronous) | **2** | `DELETE NS/repos/:name` | `artifacts repos delete <NAME> --namespace` (prompts unless `--force`) | `delete(name)` |
| Fork `{name, description?, read_only?, default_branch_only?}` | 1 | `POST NS/repos/:name/fork` | — | `handle.fork(name, opts?)` |
| Import public HTTPS `{url, branch?, depth?, read_only?}`, asynchronous | 1 (**3** into a shared baseline) | `POST NS/repos/:name/import` | — | `import(params)` |

## Repo content (no clone needed)

| Operation | Tier | REST | Binding |
|---|---|---|---|
| Commit history | 0 | `GET NS/repos/:name/log?ref=&limit=&offset=` | `handle.log(opts?)` |
| One commit | 0 | `GET NS/repos/:name/commit/:hash` | `handle.readCommit(hash)` |
| Tree | 0 | `GET NS/repos/:name/tree/:hash` | `handle.readTree(hash)` |
| Blob (bytes) | 0 | `GET NS/repos/:name/blob/:hash` | `handle.readBlob(hash)` |
| File at a ref (bytes, octet-stream) | 0 | `GET NS/repos/:name/file?ref=&path=` | `handle.readFile(args)` |
| File at a ref (bytes, guessed type) | 0 | `GET NS/repos/:name/raw/:ref/:path` | — |

## Repo tokens (for git only)

| Operation | Tier | REST | Wrangler | Binding |
|---|---|---|---|---|
| Mint `{repo, scope? (default **write**), ttl? (60–31,536,000 s, default 86,400)}` | 0 for short `read`; 1 for short `write`; **3** for `write` > 1 day | `POST NS/tokens` → `{id, plaintext, scope, expires_at}` | `artifacts repos issue-token <REPO> --namespace --scope --ttl` | `handle.createToken(scope?, ttl?)` |
| List (`state` active\|expired\|revoked\|all, `per_page` ≤100, `page`) | 0 | `GET NS/repos/:name/tokens` | — | `handle.listTokens()` |
| Revoke | 1 (**2** if another agent may hold it) | `DELETE NS/tokens/:id` | — | `handle.revokeToken(tokenOrId)` |

## Git (data plane)

| Operation | Tier | Token |
|---|---|---|
| clone, fetch, pull (protocol v1 and v2) | 0 | `read` or `write` |
| push (receive-pack v1 only) | 1 on your own repo; **2** for force-push or ref deletion on someone else's | `write` |

Header form (preferred; full token string):
`git -c http.extraHeader="Authorization: Bearer $ARTIFACTS_TOKEN" <cmd> "$ARTIFACTS_REMOTE"`

URL form (one-shot only; token without `?expires=`):
`https://x:${ARTIFACTS_TOKEN%%\?expires=*}@<ACCOUNT_ID>.artifacts.cloudflare.net/git/<ns>/<repo>.git`

## Worker binding config

```jsonc
{
  "artifacts": [{ "binding": "ARTIFACTS", "namespace": "default" }]
}
```

```toml
[[artifacts]]
binding = "ARTIFACTS"
namespace = "default"
```

One binding per namespace. Deployed Workers use the binding directly. Only
local `wrangler dev`, `deploy`, and `types` need Wrangler to be logged in.

## Limits (2026-10-21)

| | |
|---|---|
| Control-plane rate | 2,000 requests / 10 s per namespace |
| Git rate | 2,000 requests / 10 s per repo |
| Storage per repo | 1 GB (repos created on or after 2026-09-29); 10 GB for older repos |
| Storage per account | 1 TB, raisable |
| Repos, namespaces | Unlimited |
