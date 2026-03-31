# SSO Quickstart

Use this if your Snowflake account uses SSO.

## 1. Configure .env

```env
SNOWFLAKE_ACCOUNT=<your_account>
SNOWFLAKE_USER=<your_user_email>
SNOWFLAKE_AUTHENTICATOR=externalbrowser
SNOWFLAKE_ROLE=<DEVELOPER_ROLE>
SNOWFLAKE_WAREHOUSE=<EXEC_WAREHOUSE>
SNOWFLAKE_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>
MCP_PORT=3000
```

## 2. Start MCP Server

```powershell
./scripts/start-mcp.ps1
```

## 3. Validate

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:3000/health -Method Get
```

## 4. Test Tool Call

```powershell
$payload = @{ name = 'ask_admin'; arguments = @{ question = 'Show warehouse credits for last month.' } } | ConvertTo-Json -Depth 6
Invoke-RestMethod -Uri http://127.0.0.1:3000/mcp/tools/call -Method Post -Body $payload -ContentType 'application/json'
```
