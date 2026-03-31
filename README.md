# Snowflake Admin Agent Template (Generic)

A reusable Snowflake Cortex Agent template for Admin analysis using only generally available Snowflake metadata views.

## What This Template Includes

- Generic, reusable SQL objects and semantic views
- Cost analysis for compute, storage, serverless, user spend, operations, sessions, transfer, and replication
- Optional budget guardrails for an agent
- MCP bridge for GitHub Copilot Chat

## Repository Layout

- `sql/01_create_views.sql`: base generic views from `SNOWFLAKE.ACCOUNT_USAGE`
- `sql/02_create_semantic_views.sql`: semantic views over the base views
- `sql/03_create_agent.sql`: Cortex Agent with generic tool wiring
- `sql/04_create_budget.sql`: optional budget setup with placeholders
- `sql/05_grants.sql`: generic grants (replace role placeholders)
- `mcp/server.py`: tiny MCP server exposing `ask_admin`
- `.vscode/mcp.json`: VS Code MCP integration

## Quick Start

1. Replace placeholders in SQL files:
   - `<APP_DB>`
   - `<APP_SCHEMA>`
   - `<AGENT_NAME>`
   - `<ADMIN_ROLE>`
   - `<DEVELOPER_ROLE>`
   - `<EXEC_WAREHOUSE>`

2. Run SQL scripts in order:

```sql
@sql/01_create_views.sql
@sql/02_create_semantic_views.sql
@sql/03_create_agent.sql
@sql/04_create_budget.sql
@sql/05_grants.sql
```

3. Configure `.env` (not committed) and start MCP server:

```powershell
./scripts/start-mcp.ps1
```

## Notes

- `SNOWFLAKE.ACCOUNT_USAGE` data can be delayed by a few hours.
- Rate sheet availability depends on account and edition.
- Semantic view syntax can vary by Snowflake release; adjust as needed for your account.
