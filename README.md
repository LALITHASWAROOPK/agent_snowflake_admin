# Snowflake Multi-Agent Admin Assistant

A comprehensive **multi-agent AI system** for Snowflake administration powered by Snowflake Cortex AI. Features specialized agents for cost optimization, security governance, and operational monitoring, coordinated by an intelligent orchestrator.

## 🌟 What's New: Multi-Agent Architecture

Instead of a single monolithic agent, this system uses **four specialized agents** working together:

- **🧠 Orchestrator Agent**: Intelligent router that understands your questions and routes to the right specialist(s)
- **🔧 Admin Agent**: Warehouse usage, query history, credits, storage, and operational metrics
- **💰 Cost Optimizer Agent**: Idle warehouse detection, auto-suspend recommendations, rightsizing, cost savings
- **🔐 Security & Governance Agent**: Role auditing, privilege monitoring, login anomalies, compliance tracking

### Architecture

```
User Question (natural language)
        ↓
  Orchestrator Agent
    ↙      ↓      ↘
Admin    Cost    Security
Agent    Agent    Agent
    ↘      ↓      ↙
 Aggregated Response
```

See [Multi-Agent Architecture Documentation](docs/multi-agent-architecture.md) for details.

## What This Template Includes

- **4 Cortex AI Agents** with specialized capabilities
- **24 Semantic Views** for natural language query understanding
- **Cost Analysis**: compute, storage, serverless, user spend, operations, sessions, transfer, replication
- **Cost Optimization**: idle warehouses, auto-suspend recommendations, rightsizing, query optimization
- **Security & Governance**: role auditing, privilege tracking, login monitoring, anomaly detection
- **Optional Budget Guardrails** for agent spending control
- **MCP Bridge** for GitHub Copilot Chat integration
- **AWS Hosting Blueprint** for multi-user deployment (App Runner + Cognito + Amplify)

## Repository Layout

### SQL Scripts (Execute in Order)
- `sql/01_create_views.sql`: Base views from `SNOWFLAKE.ACCOUNT_USAGE`
- `sql/02_create_semantic_views.sql`: Semantic views for Admin Agent
- `sql/03_create_agent.sql`: Admin Cortex Agent
- `sql/04_create_budget.sql`: Optional budget setup
- `sql/05_grants.sql`: Generic grants
- `sql/06_create_cost_optimizer_views.sql`: Cost optimization base views
- `sql/07_create_cost_optimizer_semantic_views.sql`: Cost optimization semantic views
- `sql/08_create_security_governance_views.sql`: Security & governance base views
- `sql/09_create_security_governance_semantic_views.sql`: Security semantic views
- `sql/10_create_cost_optimizer_agent.sql`: Cost Optimizer Agent
- `sql/11_create_security_governance_agent.sql`: Security & Governance Agent
- `sql/12_create_orchestrator_agent.sql`: Orchestrator Agent (routes to specialists)

### MCP Server & Integration
- `mcp/server.py`: Multi-agent MCP server exposing 4 tools
- `mcp/requirements.txt`: Python dependencies
- `scripts/start-mcp.ps1`: Windows PowerShell startup script
- `.vscode/mcp.json`: VS Code MCP integration config

### Skills (Copilot Instructions)
- `skills/admin/SKILL.md`: Admin agent guidance
- `skills/cost-optimizer/SKILL.md`: Cost optimization strategies
- `skills/security-governance/SKILL.md`: Security best practices
- `skills/orchestrator/SKILL.md`: Multi-agent usage patterns

### Documentation
- `docs/multi-agent-architecture.md`: Complete architecture documentation
- `docs/blog-post-multi-agent.md`: Blog post with examples and use cases
- `docs/aws-hosting.md`: Production deployment guide
- `docs/architecture.md`: Original design documentation
- `docs/copilot-integration.md`: GitHub Copilot setup guide
- `docs/sso-quickstart.md`: SSO configuration

### Deployment
- `Dockerfile`: Container image for hosted deployment
- `apprunner.yaml`: AWS App Runner configuration

## Quick Start

### 1. Replace Placeholders in SQL Files

Update all SQL scripts with your values:
- `<APP_DB>` → your database name (e.g., `ADMIN_DB`)
- `<APP_SCHEMA>` → your schema name (e.g., `AGENTS`)
- `<AGENT_NAME>` → Admin agent name (e.g., `ADMIN_AGENT`)
- `<COST_OPTIMIZER_AGENT_NAME>` → Cost agent name (e.g., `COST_OPTIMIZER_AGENT`)
- `<SECURITY_AGENT_NAME>` → Security agent name (e.g., `SECURITY_AGENT`)
- `<ORCHESTRATOR_AGENT_NAME>` → Orchestrator name (e.g., `ORCHESTRATOR_AGENT`)
- `<ADMIN_ROLE>` → Admin role name (e.g., `ACCOUNTADMIN`)
- `<DEVELOPER_ROLE>` → Developer role name (e.g., `DEVELOPER`)
- `<EXEC_WAREHOUSE>` → Execution warehouse (e.g., `COMPUTE_WH`)
- `<CREDIT_RATE_USD>` → Your credit rate in USD (e.g., `3.50`)

### 2. Execute SQL Scripts in Order

```sql
-- Foundation (Admin Agent)
@sql/01_create_views.sql
@sql/02_create_semantic_views.sql
@sql/03_create_agent.sql
@sql/04_create_budget.sql
@sql/05_grants.sql

-- Cost Optimizer Agent
@sql/06_create_cost_optimizer_views.sql
@sql/07_create_cost_optimizer_semantic_views.sql
@sql/10_create_cost_optimizer_agent.sql

-- Security & Governance Agent
@sql/08_create_security_governance_views.sql
@sql/09_create_security_governance_semantic_views.sql
@sql/11_create_security_governance_agent.sql

-- Orchestrator (must be last)
@sql/12_create_orchestrator_agent.sql
```

### 3. Configure Environment Variables

Create a `.env` file (not committed to source control):

```bash
# Snowflake Connection
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_AUTHENTICATOR=snowflake  # or 'externalbrowser', 'oauth'
SNOWFLAKE_ROLE=DEVELOPER
SNOWFLAKE_WAREHOUSE=COMPUTE_WH

# Agent FQNs
SNOWFLAKE_ADMIN_AGENT_FQN=ADMIN_DB.AGENTS.ADMIN_AGENT
SNOWFLAKE_COST_OPTIMIZER_AGENT_FQN=ADMIN_DB.AGENTS.COST_OPTIMIZER_AGENT
SNOWFLAKE_SECURITY_AGENT_FQN=ADMIN_DB.AGENTS.SECURITY_AGENT
SNOWFLAKE_ORCHESTRATOR_AGENT_FQN=ADMIN_DB.AGENTS.ORCHESTRATOR_AGENT

# MCP Server
MCP_PORT=3000
AUTH_MODE=none  # or 'cognito' for production
ALLOWED_ORIGINS=*
```

### 4. Start MCP Server

```powershell
# Windows
.\scripts\start-mcp.ps1

# Or directly with Python
pip install -r mcp/requirements.txt
python mcp/server.py
```

You should see:
```
Multi-Agent Snowflake Admin MCP server listening on port 3000

Configured Agents:
  🧠 Orchestrator: ADMIN_DB.AGENTS.ORCHESTRATOR_AGENT
  🔧 Admin Agent: ADMIN_DB.AGENTS.ADMIN_AGENT
  💰 Cost Optimizer: ADMIN_DB.AGENTS.COST_OPTIMIZER_AGENT
  🔐 Security & Governance: ADMIN_DB.AGENTS.SECURITY_AGENT

Available MCP tools:
  - ask_orchestrator (recommended - intelligent routing)
  - ask_admin (direct)
  - ask_cost_optimizer (direct)
  - ask_security (direct)

Server ready!
```

### 5. Use in GitHub Copilot Chat

Add to your `.vscode/mcp.json` or VS Code settings:

```json
{
  "mcpServers": {
    "snowflake-admin": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

Then ask questions in Copilot Chat:

```
@workspace How much could I save by optimizing idle warehouses?
@workspace Show me security anomalies from last week
@workspace Which warehouses should I rightsize?
@workspace Give me a complete cost and security audit
```

## Example Use Cases

### Cost Optimization
```
Q: "Which warehouses are wasting credits?"
A: "ANALYTICS_WH has 67% idle time, wasting $3,100/month. 
    Recommendation: Set auto_suspend = 5 minutes"

Q: "How much could I save this month?"
A: "Potential savings: $7,400/month
    - Idle warehouse optimization: $5,200
    - Rightsizing 3 warehouses: $2,200"

Q: "Find my most expensive queries"
A: "Top query (QUERY_ID_XYZ): 45GB spilling to remote storage.
    Add clustering on ORDER_DATE → 80% faster, 60% less cost"
```

### Security & Compliance
```
Q: "Who has ACCOUNTADMIN privileges?"
A: "5 users with ACCOUNTADMIN:
    - john.doe: No activity in 73 days (Critical - revoke)
    - jane.smith: Active (4 queries today)
    - ..."

Q: "Are there any security anomalies?"
A: "🔴 CRITICAL: 15 failed login attempts for 'admin_user' 
    from 5 different IPs in last hour. Possible brute force attack."

Q: "Show me inactive users with access"
A: "8 users inactive for 30+ days:
    - contractor_temp: Last login 45 days ago (contract ended)
    - ..."
```

### Operational Monitoring
```
Q: "How many credits did we use yesterday?"
A: "Yesterday's credits: 1,247 credits ($4,364)
    Breakdown:
    - Compute: 892 credits (72%)
    - Storage: 245 credits (20%)
    - Serverless: 110 credits (8%)"

Q: "Show me query performance for COMPUTE_WH"
A: "COMPUTE_WH (last 7 days):
    - 12,453 queries executed
    - Avg execution: 8.3 seconds
    - P95 execution: 42 seconds
    - 234 queries queued (1.9%)"
```

### Multi-Domain Analysis
```
Q: "Give me a complete health check"
A: "Snowflake Account Health Report:

    💰 Cost Analysis:
    - 7-day spend: $15,234 (↑12% vs previous week)
    - Idle waste: $4,200 (28% of spend)
    - Top opportunity: ANALYTICS_WH optimization ($3,100/mo savings)

    🔐 Security Status:
    - 5 excessive privilege grants found
    - 23 failed login attempts (3 anomalies flagged)
    - 2 inactive users with active roles

    🔧 Performance:
    - 8 warehouses active
    - 3 recommended for rightsizing
    - 12 queries with critical optimization opportunities"
```

## Benefits of Multi-Agent Architecture

### 🎯 Specialization
- Each agent focuses on one domain (cost, security, operations)
- Deeper expertise per domain
- Easier to maintain and extend

### 🧠 Intelligent Routing
- Users don't need to know which agent to ask
- Orchestrator handles domain detection automatically
- Single interface for all questions

### ⚡ Parallel Execution
- Multi-domain questions handled efficiently
- Orchestrator calls multiple agents simultaneously
- Faster comprehensive analysis

### 📈 Scalability
- Add new specialist agents without changing existing ones
- Orchestrator routing logic easily extended
- Semantic views updated independently

### 🔧 Flexibility
- Use Orchestrator for general questions
- Direct access to specialist agents for focused analysis
- Mix and match for custom workflows

## Deploy for Multi-User Access (AWS)

Use the production path in `docs/aws-hosting.md`:

1. Containerize with `Dockerfile`
2. Deploy backend on AWS App Runner
3. Protect API with Amazon Cognito JWTs (`AUTH_MODE=cognito`)
4. Host frontend chat page on AWS Amplify

See [AWS Hosting Documentation](docs/aws-hosting.md) for complete guide.

## Documentation

- **[Multi-Agent Architecture](docs/multi-agent-architecture.md)** - Complete architecture documentation
- **[Blog Post](docs/blog-post-multi-agent.md)** - Detailed blog post with examples
- **[AWS Hosting](docs/aws-hosting.md)** - Production deployment guide
- **[Copilot Integration](docs/copilot-integration.md)** - GitHub Copilot setup
- **[SSO Quickstart](docs/sso-quickstart.md)** - SSO configuration

## Notes

- `SNOWFLAKE.ACCOUNT_USAGE` data can be delayed by 45 minutes to 3 hours
- Rate sheet availability depends on account and edition
- Semantic view syntax may vary by Snowflake release; adjust as needed
- For hosted deployments, avoid `externalbrowser` auth and use service auth (password or OAuth)
- Each agent query consumes compute credits (typical: 0.001-0.01 credits per query)
- Consider applying budget tags to agents for cost tracking (see `sql/04_create_budget.sql`)

## Troubleshooting

### Orchestrator Not Routing Correctly
- Verify all agent FQN environment variables are set correctly
- Check that all specialist agents are created in Snowflake
- Ensure grants are in place: `GRANT USAGE ON AGENT <agent> TO AGENT <orchestrator>`

### Agent Returns No Results
- Verify semantic views are created successfully
- Check ACCOUNT_USAGE access grants for your role
- Consider data latency (ACCOUNT_USAGE delayed up to 3 hours)

### MCP Connection Errors
- Verify Snowflake credentials in `.env`
- Check network connectivity to Snowflake account
- Review authentication mode configuration

### Performance Issues
- Use direct agent calls instead of orchestrator for known domains
- Monitor warehouse usage for agent execution
- Consider result caching for frequently asked questions

## Contributing

To add a new specialist agent:

1. Create base views (`sql/*_views.sql`)
2. Create semantic views (`sql/*_semantic_views.sql`)
3. Create agent definition (`sql/*_agent.sql`)
4. Add tool to MCP server (`mcp/server.py`)
5. Create skill documentation (`skills/*/SKILL.md`)
6. Update orchestrator routing logic in agent instructions

## License

This template is provided as-is for educational and commercial use.
