# Connecting to HubSpot — three channels

All facts from HubSpot's MCP docs as of 2026-09-30 unless marked *(verify)*.

## Channel 1 — HubSpot's native Claude connector (default for a team)

HubSpot's own connector in Claude's connector directory, running on
`mcp.hubspot.com`. Free, works on every HubSpot tier including Free (with a
paid Claude plan) *(verify current plan requirements)*.

1. Claude → Settings → Connectors → browse → **HubSpot** → Connect.
2. HubSpot sign-in → pick the account (portal) → grant permissions → authorize.
3. Verify: ask Claude to run `get_user_details`. It must return **their**
   user on the **right portal**. A person with access to several portals can
   pick the wrong one here.

**Why default:** no client ID, no secret, nothing for us to run. Each person
is themselves, so HubSpot's permissions and audit trail stay correct.
**Offboarding:** deactivate their HubSpot user. The connector stops working
on the next call.

## Channel 2 — a custom MCP connector (when the native one won't do)

For MCP clients without the native connector (MCP Inspector, Claude Code,
your own agent), or when the client wants a connector they own and name.

1. In the client's HubSpot: **Development → MCP Connectors → Create MCP
   connector.** Name, optional description and icon, **redirect URL(s)**. The
   first redirect is the default. For MCP Inspector add
   `http://localhost:6274/oauth/callback/debug`.
2. The details page shows a **client ID and secret**. Store both in the
   client-stack `.env` (`HUBSPOT_MCP_CLIENT_ID`, `HUBSPOT_MCP_CLIENT_SECRET`),
   never in a doc.
3. Point the client at `https://mcp.hubspot.com` with those credentials. In
   Claude's *Add custom connector* they go under **Advanced settings**,
   because HubSpot publishes **no dynamic client registration**.

Things that break it:

- **No PKCE.** HubSpot requires S256 PKCE on every flow. Clients that don't
  do it fail at the authorization step.
- **Redirect mismatch.** The client's redirect must match one configured on
  the connector exactly.
- **Refresh tokens are single-use and rotate** (OAuth 2.1). A client that
  reuses an old refresh token gets logged out and must re-authorize.
- **Scopes are derived, not chosen.** They come from the server's tools at
  install time plus what the user grants. When HubSpot adds tools, users
  **reinstall** to pick up the new scopes.

Quick test: run MCP Inspector, transport **Streamable HTTP**, URL
`https://mcp.hubspot.com/`, paste client ID + secret, run the guided OAuth,
**List Tools**, then call `get_user_details`.

## Channel 3 — operator private app (REST, scripts, repairs)

For the operator only: schema discovery, merges, deletes, Sensitive Data
accounts, anything MCP doesn't expose.

1. Client's HubSpot → **Development → Private apps** *(verify menu path)* →
   create, choose the minimum scopes, copy the token (`pat-…`).
2. Store it as `HUBSPOT_PRIVATE_APP_TOKEN` in `<client_stack>/hubspot/.env`.
3. `Authorization: Bearer $HUBSPOT_PRIVATE_APP_TOKEN` against
   `https://api.hubapi.com`.

Writes from this channel are attributed to the app, not to a person. That's
correct for repairs and wrong for a team member's day-to-day logging.

## Which to use

| Situation | Channel |
|---|---|
| A team member wants Claude to work their CRM | 1 |
| MCP client without the native connector, or Claude Code against HubSpot | 2 |
| Bulk repair, merge, delete, schema audit, Sensitive Data account | 3 |
| Our own wrapper in front of HubSpot (one Lossless connector per client) | The wrapper is a client of Channel 2 and adds what MCP lacks; until it exists, use 1 |
