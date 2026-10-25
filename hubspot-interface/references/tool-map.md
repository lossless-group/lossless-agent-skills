# HubSpot remote MCP — tool map, tiered

Source: HubSpot's published list of public tools
(developers.hubspot.com, "Integrate AI tools with the HubSpot MCP server",
last modified 2026-09-30, fetched 2026-10-25). **32 tools.** Availability
varies by subscription, user permissions, and client app. `get_user_details`
is the truth for any given session. Some MCP clients add provider-specific
tools not listed here.

Tiers are this skill's, not HubSpot's: **0** read · **1** record write ·
**2** account-wide schema · **3** public or outbound. See SKILL.md § Safety.

## Account, schema, and discovery

| Tool | Tier | Notes |
|---|---|---|
| `get_user_details` | 0 | Call first. User, account, per-object read/write, available tools |
| `get_organization_details` | 0 | Teams, job titles, seat counts, timezone, currency, account type |
| `discover_hubspot_schema` | 0 | Object types and your read/write access to each |
| `search_properties` | 0 | Keyword search over property definitions, ≤5 keywords |
| `get_properties` | 0 | Full definitions incl. enum values. Large, so ask for named properties |
| `search_owners` | 0 | Owners by name, email, or ID, ≤100 |
| `tool_guidance` | 0 | Usage guidance. Required before `query_crm_data`, associations, attribution |
| `manage_custom_properties` | **2** | Creates properties for every user in the account |
| `manage_custom_pipelines` | **2** | Creates/edits pipelines. Free-tools accounts can only edit the default |
| `manage_onboarding` | 1 | Onboarding status, goals, task progression |

## CRM records and activities

| Tool | Tier | Notes |
|---|---|---|
| `search_crm_objects` | 0 | 5 groups × 6 filters, AND within / OR across, 200 per page |
| `get_crm_objects` | 0 | By ID, ≤100 per call |
| `query_crm_data` | 0 | SQL-ish aggregates. No joins, aliases, subqueries, association traversal, or currency conversion |
| `manage_crm_objects` | 1 | Create/update records and activities; associations (call `tool_guidance` first). HubSpot shows a change summary and requires confirmation |
| `manage_segment` | 1 / **2** | Static segment create and membership edits: 1. Dynamic segments can feed workflows and emails: treat as 2 |

## Conversations and signals

| Tool | Tier | Notes |
|---|---|---|
| `get_conversation_channel_metadata` | 0 | Inboxes and channels. Call before filtering conversations |
| `search_conversations` | 0 | Private content. Inbox access can be per user/team. Blocked when Sensitive Data is on |
| `search_intent_signals` | 0 | Buyer intent signals by company/contact |

## Marketing, campaigns, and content

| Tool | Tier | Notes |
|---|---|---|
| `read_campaign_data` | 0 | Campaign analytics, asset metrics, contacts |
| `get_campaign_attribution_reports` | 0 | Closed-won attribution only; long-running, polls |
| `manage_campaign_objects` | **3** | Creates/updates campaigns and asset associations |
| `get_marketing_email_analytics` | 0 | Aggregates, MX-group health, per-contact engagement |
| `manage_marketing_email` | **3** | Drafts, clones, A/B variants. No send tool is listed, but drafts are one click from outbound |
| `get_content_analytics_report` | 0 | Pages and blog analytics |
| `manage_landing_page` | **3** | Publish requires confirmation; then `render_asset` |
| `manage_website_page` | **3** | Includes site navigation (`NAV_*`). Claude/ChatGPT/Gemini only |
| `manage_blog_post` | **3** | New posts are drafts; publish needs description + author. Claude/ChatGPT/Gemini only |
| `render_asset` | 0 | Read-only preview card after the last edit/publish. Claude/ChatGPT/Gemini only |

## AEO (Marketing Hub Pro/Enterprise)

| Tool | Tier | Notes |
|---|---|---|
| `get_aeo_metrics` | 0 | Share of voice, prompt trends, competitors |
| `manage_aeo_prompts` | 1 | View and create tracked prompts |
| `manage_aeo_recommendations` | **3** | Can start content generation (blog, social) |

## Other

| Tool | Tier | Notes |
|---|---|---|
| `submit_feedback` | **3** | Sends text to HubSpot. Only when the person asks |

## Not in the MCP surface (REST, operator only)

Delete, restore, merge, property history, bulk association reads, and
anything in a Sensitive Data account's activities. See SKILL.md § Operator
channel.
