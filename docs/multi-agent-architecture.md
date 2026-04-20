# Multi-Agent Snowflake Administration Architecture

## Overview

This repository implements a **multi-agent architecture** for comprehensive Snowflake administration, combining specialized AI agents with intelligent orchestration to provide cost optimization, security governance, and operational insights.

## Agent Team

### 🧠 Orchestrator Agent
**Role:** Intelligent router and coordinator  
**Capabilities:**
- Understands natural language questions
- Routes to appropriate specialist agent(s)
- Aggregates multi-agent responses
- Provides holistic insights

### 🔧 Admin Agent
**Role:** Operational metrics and monitoring  
**Capabilities:**
- Warehouse usage and credits analysis
- Query history and performance
- Storage metrics (active/inactive)
- Serverless cost tracking
- User spend attribution
- Session activity monitoring
- Data transfer and replication costs

### 💰 Cost Optimizer Agent
**Role:** Waste detection and cost reduction  
**Capabilities:**
- Idle warehouse detection
- Auto-suspend recommendations
- Warehouse rightsizing analysis
- Query optimization opportunities
- Cost savings potential calculation
- Utilization trend analysis

### 🔐 Security & Governance Agent
**Role:** Access control and compliance  
**Capabilities:**
- Role hierarchy analysis
- Privilege grant auditing
- Failed login monitoring
- Login anomaly detection (brute force, credential compromise)
- Excessive privilege identification
- Data access pattern tracking
- Unauthorized access attempt monitoring
- User/role compliance auditing
- Network policy violation tracking

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                       │
│  (GitHub Copilot Chat, Web UI, API, Slack, etc.)            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  MCP Server (HTTP Bridge)                     │
│  Tools: ask_orchestrator, ask_admin, ask_cost_optimizer,    │
│         ask_security                                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│               🧠 Orchestrator Agent (Cortex)                 │
│  - Analyzes user intent                                      │
│  - Routes to specialist agent(s)                             │
│  - Aggregates responses                                       │
└─────┬─────────────────┬─────────────────┬───────────────────┘
      │                 │                 │
      ↓                 ↓                 ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐
│ 🔧 Admin     │ │ 💰 Cost      │ │ 🔐 Security &        │
│    Agent     │ │    Optimizer │ │    Governance        │
│              │ │    Agent     │ │    Agent             │
└──────┬───────┘ └──────┬───────┘ └──────┬───────────────┘
       │                │                │
       ↓                ↓                ↓
┌──────────────────────────────────────────────────────────────┐
│              Semantic Views (Cortex Analyst)                  │
│  ┌────────────────┐ ┌──────────────┐ ┌──────────────────┐  │
│  │ Warehouse Cost │ │ Idle WH      │ │ Role Hierarchy   │  │
│  │ Storage Cost   │ │ Auto-Suspend │ │ Privilege Grants │  │
│  │ Serverless     │ │ Oversize WH  │ │ Failed Logins    │  │
│  │ User Spend     │ │ Query Opt    │ │ Login Anomalies  │  │
│  │ WH Operations  │ │ Cost Savings │ │ Excessive Privs  │  │
│  │ Session        │ │ Utilization  │ │ Data Access      │  │
│  │ Transfer       │ │              │ │ Unauth Access    │  │
│  │ Rate Pricing   │ │              │ │ User Audit       │  │
│  └────────────────┘ └──────────────┘ └──────────────────┘  │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ↓
┌──────────────────────────────────────────────────────────────┐
│                 Base Views (Data Sources)                     │
│  - SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY        │
│  - SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY                     │
│  - SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY         │
│  - SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE                     │
│  - SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY                     │
│  - SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES/USERS             │
│  - SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY                    │
│  - SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_EVENTS_HISTORY          │
└──────────────────────────────────────────────────────────────┘
```

## Data Flow

### Example: "How much could I save this month?"

```
1. User asks question via GitHub Copilot Chat
2. MCP Server receives: ask_orchestrator("How much could I save this month?")
3. Orchestrator Agent analyzes intent → Cost optimization domain
4. Orchestrator routes to Cost Optimizer Agent
5. Cost Optimizer Agent:
   - Uses IdleWarehouseAnalyst (SV_IDLE_WAREHOUSE_ANALYSIS)
   - Uses CostSavingsSummary (SV_COST_SAVINGS_SUMMARY)
   - Generates SQL via Cortex Analyst
   - Executes queries on base views
6. Results aggregated and returned through Orchestrator
7. User receives: "You could save ~$X/month by optimizing idle warehouses..."
```

### Example: "Give me a security and cost audit"

```
1. User asks multi-domain question
2. Orchestrator routes to BOTH Cost Optimizer AND Security agents in parallel
3. Cost Optimizer returns: Idle credits, optimization opportunities
4. Security Agent returns: Excessive privileges, failed logins
5. Orchestrator aggregates:
   "Cost Findings: $X idle, Y warehouses oversized
    Security Findings: Z users with unused ACCOUNTADMIN, N failed logins"
```

## Component Breakdown

### SQL Objects (06-12_*.sql)
- **06_create_cost_optimizer_views.sql**: 6 base views for cost analysis
- **07_create_cost_optimizer_semantic_views.sql**: 6 semantic views for Cost Optimizer
- **08_create_security_governance_views.sql**: 9 base views for security
- **09_create_security_governance_semantic_views.sql**: 9 semantic views for Security
- **10_create_cost_optimizer_agent.sql**: Cost Optimizer Agent definition
- **11_create_security_governance_agent.sql**: Security & Governance Agent definition
- **12_create_orchestrator_agent.sql**: Orchestrator Agent + routing function

### MCP Server (mcp/server.py)
- Exposes 4 tools: `ask_orchestrator`, `ask_admin`, `ask_cost_optimizer`, `ask_security`
- Routes to appropriate Snowflake Cortex Agent
- Handles authentication (password, OAuth, Cognito)
- Rate limiting and CORS support

### Skills (skills/*/SKILL.md)
- **admin**: Operational metrics guidance
- **cost-optimizer**: Cost optimization strategies
- **security-governance**: Security compliance best practices
- **orchestrator**: Multi-agent routing and usage

## Deployment Steps

### 1. Deploy SQL Objects (in order)
```sql
-- Existing (01-05)
@sql/01_create_views.sql
@sql/02_create_semantic_views.sql
@sql/03_create_agent.sql
@sql/04_create_budget.sql
@sql/05_grants.sql

-- New Cost Optimizer
@sql/06_create_cost_optimizer_views.sql
@sql/07_create_cost_optimizer_semantic_views.sql
@sql/10_create_cost_optimizer_agent.sql

-- New Security & Governance
@sql/08_create_security_governance_views.sql
@sql/09_create_security_governance_semantic_views.sql
@sql/11_create_security_governance_agent.sql

-- Orchestrator (must be last)
@sql/12_create_orchestrator_agent.sql
```

### 2. Configure Environment Variables
```bash
# Snowflake Connection
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_ROLE=<DEVELOPER_ROLE>
SNOWFLAKE_WAREHOUSE=<EXEC_WAREHOUSE>

# All Agent FQNs
SNOWFLAKE_ADMIN_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>
SNOWFLAKE_COST_OPTIMIZER_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>
SNOWFLAKE_SECURITY_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>
SNOWFLAKE_ORCHESTRATOR_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>

# MCP Server
MCP_PORT=3000
AUTH_MODE=none  # or 'cognito'
```

### 3. Start MCP Server
```powershell
.\scripts\start-mcp.ps1
```

### 4. Configure GitHub Copilot
Add to `.vscode/mcp.json` (or global settings):
```json
{
  "mcpServers": {
    "snowflake-admin": {
      "url": "http://localhost:3000/mcp"
    }
  }
}
```

### 5. Use in GitHub Copilot Chat
```
@workspace How much could I save by optimizing idle warehouses?
@workspace Show me security anomalies from the last week
@workspace Give me a complete cost and security audit
```

## Production Deployment (AWS)

See [aws-hosting.md](aws-hosting.md) for:
- AWS App Runner deployment
- Amazon Cognito authentication
- AWS Amplify frontend hosting
- Multi-user production architecture

## Benefits of Multi-Agent Architecture

### Separation of Concerns
- Each agent specializes in one domain
- Easier to maintain and extend
- Clear ownership of metrics

### Intelligent Routing
- Users don't need to know which agent to ask
- Orchestrator handles domain detection
- Single interface for all questions

### Parallel Execution
- Multi-domain questions handled efficiently
- Orchestrator can call multiple agents simultaneously
- Faster comprehensive analysis

### Scalability
- Add new specialist agents without changing existing ones
- Orchestrator routing logic easily extended
- Semantic views can be updated independently

### Composability
- Direct access to specialist agents when needed
- Orchestrator for general questions
- Mix and match for custom workflows

## Example Use Cases

### Daily Operations (Admin Agent)
- "How many credits did we use yesterday?"
- "Show me query performance for COMPUTE_WH"
- "What's our storage breakdown by database?"

### Cost Optimization (Cost Optimizer Agent)
- "Which warehouses are wasting credits?"
- "Should I change my auto-suspend settings?"
- "Find my most expensive queries"

### Security & Compliance (Security Agent)
- "Who has ACCOUNTADMIN privileges?"
- "Show me failed login attempts this week"
- "Are there any users with excessive role assignments?"

### Comprehensive Analysis (Orchestrator)
- "Give me a complete health check of my Snowflake account"
- "What are my biggest cost and security risks?"
- "Show me optimization opportunities across all areas"

## Monitoring & Observability

### Agent Performance
- Monitor warehouse usage for agent execution
- Track agent response times
- Review Cortex Analyst query generation quality

### Cost Tracking
- Apply budget tags to agents (see 04_create_budget.sql)
- Monitor agent credit consumption
- Set spending limits and alerts

### Security Auditing
- Track who uses which agents
- Log all agent queries
- Monitor for anomalous agent usage patterns

## Troubleshooting

### Common Issues

**Orchestrator not routing correctly:**
- Verify all agent FQNs in environment variables
- Check USAGE grants between orchestrator and specialist agents
- Review orchestrator instructions for routing keywords

**Agent returns empty results:**
- Verify semantic views are created
- Check ACCOUNT_USAGE access grants
- Consider latency (ACCOUNT_USAGE data delayed 45min-3hrs)

**MCP server connection errors:**
- Verify Snowflake credentials
- Check network connectivity
- Review authentication mode configuration

## Next Steps

1. **Add more specialist agents:**
   - Performance Tuning Agent
   - Data Quality Agent
   - Schema Management Agent

2. **Enhanced orchestration:**
   - Agent cascading (Cost Optimizer → Admin for baseline)
   - Contextual memory across agent calls
   - User preference learning

3. **Advanced analytics:**
   - Predictive cost forecasting
   - Anomaly detection with ML
   - Automated remediation recommendations

## Contributing

To add a new specialist agent:
1. Create base views (sql/*_views.sql)
2. Create semantic views (sql/*_semantic_views.sql)
3. Create agent definition (sql/*_agent.sql)
4. Add tool to MCP server (mcp/server.py)
5. Create skill documentation (skills/*/SKILL.md)
6. Update orchestrator routing logic
