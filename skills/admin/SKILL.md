---
name: admin
description: Generic Snowflake Admin administration guidance for cost monitoring, budgets, warehouse optimization, storage, serverless usage, user spend, and semantic view operations.
---

# Generic Admin Guide

## Scope

Use this skill for:

- Compute credits and spend analysis
- Storage and inactive storage analysis
- Serverless and replication costs
- User spend attribution
- Budget monitoring and thresholds
- Agent and semantic view administration

## Generic Object Pattern

Replace placeholders in this template:

- `<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>`
- `<APP_DB>.<APP_SCHEMA>.SV_*`
- `<APP_DB>.<APP_SCHEMA>.V_*`
- `<ADMIN_ROLE>` and `<DEVELOPER_ROLE>`

## Common Conventions

- Credit to dollar conversion: `credits * <credit_rate_usd>`
- Default time filter: last 30 days unless specified
- Round credits to 2 decimals and storage to 4 decimals
- Validate account usage latency before asserting near-real-time status

## Budget Commands (Generic)

```sql
CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!GET_CONFIG();
CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!SET_SPENDING_LIMIT(<credits_limit>);
CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!GET_SPENDING_HISTORY();
```
