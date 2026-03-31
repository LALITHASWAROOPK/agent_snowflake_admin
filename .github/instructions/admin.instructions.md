---
applyTo: "**"
description: "Generic instructions for Snowflake Admin, cost monitoring, budget controls, warehouse optimization, and semantic-view based analytics."
---

# Generic Admin Instructions

Use generic placeholders instead of customer-specific values:

- Database/schema: `<APP_DB>.<APP_SCHEMA>`
- Agent: `<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>`
- Roles: `<ADMIN_ROLE>`, `<DEVELOPER_ROLE>`
- Warehouse: `<EXEC_WAREHOUSE>`
- Tag key: `<COST_TAG_NAME>`

When answering Admin questions:

- Prefer account usage sources and semantic views from this repository.
- Clearly separate compute, storage, serverless, transfer, and replication costs.
- If user asks for dollar amounts, apply account-specific credit rate where available.
- Mention latency caveat for `SNOWFLAKE.ACCOUNT_USAGE`.
