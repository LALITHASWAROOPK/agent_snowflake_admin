# Generic Admin Agent Architecture

## Overview

This template uses Snowflake Cortex Agent + semantic views + account usage views to answer cost and operations questions in natural language.

## Data Flow

1. User asks a Admin question in Copilot Chat.
2. MCP server forwards the question to `SNOWFLAKE.CORTEX.DATA_AGENT_RUN`.
3. The agent selects the right tool.
4. Tool queries a semantic view backed by `SNOWFLAKE.ACCOUNT_USAGE`.
5. Agent returns a concise answer with metrics.

## Tooling Scope

- Warehouse compute cost and performance
- Storage usage and inactive storage
- Serverless usage (tasks, pipes, auto-clustering, search optimization, MV refresh)
- User-level spend attribution
- Warehouse operations events
- Login/session activity
- Data transfer and replication
- Rate sheet pricing

## Required Inputs

- A target database and schema for created views
- An execution warehouse for analyst tools
- Agent owner/admin role and analyst/developer role
- Optional cost-allocation tag key for warehouse attribution

## Notes

- Account usage latency: typically a few hours.
- Some organizations may restrict access to `ORGANIZATION_USAGE.RATE_SHEET_DAILY`.
- If semantic views are not enabled in your account/region, replace with standard views and route tools to them.
