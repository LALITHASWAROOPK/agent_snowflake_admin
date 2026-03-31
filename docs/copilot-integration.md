# Copilot MCP Integration (Generic)

## Prerequisites

- VS Code with GitHub Copilot and Copilot Chat
- Python 3.9+
- Snowflake user with agent usage permissions

## Setup

1. Install dependencies:

```bash
pip install -r mcp/requirements.txt
```

2. Configure `.env` in the repo root:

```env
SNOWFLAKE_ACCOUNT=<your_account>
SNOWFLAKE_USER=<your_user>
SNOWFLAKE_AUTHENTICATOR=externalbrowser
SNOWFLAKE_ROLE=<DEVELOPER_ROLE>
SNOWFLAKE_WAREHOUSE=<EXEC_WAREHOUSE>
SNOWFLAKE_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>
MCP_PORT=3000
```

3. Start MCP server:

```powershell
./scripts/start-mcp.ps1
```

4. Health check:

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:3000/health -Method Get
```

## Example Questions

- What are total compute credits by warehouse in the last 30 days?
- Which users consumed the most credits this month?
- What are serverless credits by service type?
- How many failed logins occurred in the last 7 days?
- What are replication credits by database?
