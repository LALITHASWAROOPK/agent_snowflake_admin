# Building a Multi-Agent Snowflake Admin Assistant with Cortex AI

## Introduction

Managing a Snowflake account involves juggling multiple concerns: tracking costs, optimizing warehouse performance, ensuring security compliance, and monitoring operational metrics. What if you could ask natural language questions and get intelligent, actionable answers from specialized AI agents?

In this post, I'll show you how to build a **multi-agent Snowflake administration system** using Snowflake Cortex AI, where specialized agents work together to provide comprehensive insights.

## The Problem: One-Size-Fits-All Doesn't Work

Traditional monitoring dashboards force you to know what you're looking for. They require:
- Understanding which metrics to check
- Knowing where to find them
- Manually correlating data across different domains
- Interpreting raw numbers without context

What we really want is to ask questions like:
- *"How much could I save this month?"*
- *"Are there any security anomalies?"*
- *"Which warehouses are wasting credits?"*

And get intelligent, actionable answers.

## The Solution: Specialized AI Agents

Instead of building one monolithic agent that tries to do everything, we create a **team of specialized agents**:

### 🔧 Admin Agent
**Focus:** Operational metrics and monitoring
- Warehouse usage and credits
- Query history and performance
- Storage metrics
- User spend attribution

### 💰 Cost Optimizer Agent
**Focus:** Waste detection and cost reduction
- Idle warehouse detection
- Auto-suspend recommendations
- Warehouse rightsizing
- Query optimization opportunities

### 🔐 Security & Governance Agent
**Focus:** Access control and compliance
- Role and privilege auditing
- Failed login monitoring
- Anomaly detection
- Unauthorized access tracking

### 🧠 Orchestrator Agent
**Focus:** Intelligent routing
- Understands user intent
- Routes to appropriate specialist(s)
- Aggregates multi-agent responses

## The Architecture

Here's how the agents work together:

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

### Example Flow: "How much could I save?"

1. **User asks** via GitHub Copilot Chat: *"How much could I save this month?"*
2. **Orchestrator analyzes** the question and identifies it as a cost optimization query
3. **Routes to Cost Optimizer Agent** which:
   - Queries idle warehouse metrics
   - Calculates wasted credits
   - Identifies optimization opportunities
4. **Returns actionable answer:** *"You could save ~$5,200/month by:*
   - *Setting auto-suspend to 5 minutes on ANALYTICS_WH (saves $3,100)*
   - *Downsizing REPORTING_WH from Large to Medium (saves $2,100)"*

### Example Flow: Multi-Domain Query

**Question:** *"Give me a security and cost audit"*

The Orchestrator recognizes this spans multiple domains:
1. Routes to **Cost Optimizer** → Returns idle credits, oversized warehouses
2. Routes to **Security Agent** → Returns excessive privileges, failed logins
3. **Aggregates results** into comprehensive report:

```
Cost Findings:
  - $4,200 in idle credits (last 7 days)
  - 3 warehouses running oversized
  - 12 queries with critical optimization opportunities

Security Findings:
  - 5 users with unused ACCOUNTADMIN privileges
  - 23 failed login attempts from unknown IPs
  - 2 users inactive for 60+ days with active roles
```

## Building the Foundation: Semantic Views

Each specialist agent is powered by **semantic views** that abstract complex SQL into natural language concepts.

### Cost Optimizer Semantic Views

```sql
-- Idle Warehouse Detection
CREATE SEMANTIC VIEW SV_IDLE_WAREHOUSE_ANALYSIS
  TABLES (iw AS V_IDLE_WAREHOUSES)
  FACTS (
    iw.idle_credits AS iw.idle_credits,
    iw.idle_percentage AS iw.idle_percentage,
    iw.idle_cost_usd AS iw.idle_credits * <CREDIT_RATE_USD>
  )
  DIMENSIONS (
    iw.warehouse_name AS iw.warehouse_name,
    iw.uptime_date AS iw.uptime_date
  )
  ...
```

This allows the agent to understand questions like:
- "Which warehouses are idle?"
- "Show me waste by warehouse"
- "Calculate idle credits for last week"

### Security Semantic Views

```sql
-- Login Anomaly Detection
CREATE SEMANTIC VIEW SV_LOGIN_ANOMALIES
  TABLES (la AS V_LOGIN_ANOMALIES)
  FACTS (
    la.failed_attempts AS la.failed_attempts,
    la.distinct_ips AS la.distinct_ips
  )
  DIMENSIONS (
    la.anomaly_severity AS la.anomaly_severity,
    la.recommendation AS la.recommendation
  )
  ...
```

This enables security questions like:
- "Are there any suspicious login patterns?"
- "Show me brute force attempts"
- "Which users have anomalous behavior?"

## Creating the Specialist Agents

Each agent is a Snowflake Cortex Agent with carefully crafted instructions:

### Cost Optimizer Agent

```sql
CREATE AGENT COST_OPTIMIZER_AGENT
  FROM SPECIFICATION
  $$
  instructions:
    response: "You are a Cost Optimizer assistant. Analyze 
              compute spend, identify waste, and provide actionable 
              recommendations for auto-suspend settings, warehouse 
              sizing, and query optimization."
    
    orchestration: "Route idle warehouse analysis to 
                   IdleWarehouseAnalyst; auto-suspend recommendations 
                   to AutoSuspendAnalyst; warehouse sizing to 
                   WarehouseSizingAnalyst..."

  tools:
    - tool_spec: { 
        type: "cortex_analyst_text_to_sql", 
        name: "IdleWarehouseAnalyst",
        description: "Detect idle warehouses and waste" 
      }
    - tool_spec: { 
        type: "cortex_analyst_text_to_sql",
        name: "AutoSuspendAnalyst",
        description: "Recommend auto-suspend configuration" 
      }
    ...

  tool_resources:
    IdleWarehouseAnalyst:
      semantic_view: "SV_IDLE_WAREHOUSE_ANALYSIS"
    ...
  $$;
```

### Security & Governance Agent

```sql
CREATE AGENT SECURITY_AGENT
  FROM SPECIFICATION
  $$
  instructions:
    response: "You are a Security & Governance assistant. 
              Monitor role assignments, detect privilege anomalies, 
              track failed logins, and identify unauthorized access 
              attempts."

  tools:
    - tool_spec: { 
        type: "cortex_analyst_text_to_sql",
        name: "LoginAnomalyDetector",
        description: "Detect login anomalies and potential attacks" 
      }
    - tool_spec: { 
        type: "cortex_analyst_text_to_sql",
        name: "ExcessivePrivilegeAnalyst",
        description: "Identify excessive or unused privileges" 
      }
    ...
  $$;
```

## The Orchestrator: Tying It All Together

The Orchestrator Agent is the brains of the operation:

```sql
CREATE AGENT ORCHESTRATOR_AGENT
  FROM SPECIFICATION
  $$
  instructions:
    response: |
      You are an intelligent Orchestrator for Snowflake 
      administration. Your role is to:
      1. Understand the user's natural language question
      2. Determine which specialized agent(s) should handle it
      3. Route the request appropriately
      4. Aggregate and present the results
      
      Available specialized agents:
      - AdminAgent: Operational metrics, query history, credits
      - CostOptimizerAgent: Waste detection, optimization, savings
      - SecurityAgent: Access control, privilege auditing, compliance
      
      Routing guidelines:
      - "credits spent", "warehouse usage" → AdminAgent
      - "waste", "idle", "optimization" → CostOptimizerAgent
      - "security", "roles", "privileges" → SecurityAgent
      - Multi-domain questions → multiple agents in parallel

  tools:
    - tool_spec: { type: "function", name: "AdminAgent", ... }
    - tool_spec: { type: "function", name: "CostOptimizerAgent", ... }
    - tool_spec: { type: "function", name: "SecurityAgent", ... }
  $$;
```

### Routing Function

To enable agent-to-agent communication, we create a routing function:

```sql
CREATE FUNCTION F_ROUTE_TO_AGENT(AGENT_NAME VARCHAR, QUESTION VARCHAR)
RETURNS VARIANT
LANGUAGE PYTHON
AS
$$
def route_request(snowpark_session, agent_name, question):
    payload = {
        "messages": [{
            "role": "user",
            "content": [{"type": "text", "text": question}]
        }]
    }
    
    query = f"""
        SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
            '{agent_name}',
            '{json.dumps(payload)}'
        )
    """
    
    return snowpark_session.sql(query).collect()[0]
$$;
```

## Integrating with GitHub Copilot

To make these agents accessible from your IDE, we build an MCP (Model Context Protocol) server:

```python
# MCP Server (simplified)
class SnowflakeAgentServer:
    def list_tools(self):
        return [
            {
                "name": "ask_orchestrator",
                "description": "Ask the Orchestrator (routes intelligently)",
                "parameters": {"question": "string"}
            },
            {
                "name": "ask_cost_optimizer",
                "description": "Direct query to Cost Optimizer",
                "parameters": {"question": "string"}
            },
            {
                "name": "ask_security",
                "description": "Direct query to Security Agent",
                "parameters": {"question": "string"}
            }
        ]
    
    def call_tool(self, tool_name, question):
        agent_map = {
            "ask_orchestrator": ORCHESTRATOR_AGENT_FQN,
            "ask_cost_optimizer": COST_OPTIMIZER_AGENT_FQN,
            "ask_security": SECURITY_AGENT_FQN,
        }
        
        return ask_agent(question, agent_map[tool_name])
```

Now you can use GitHub Copilot Chat:

```
@workspace How much are we spending on idle warehouses?
@workspace Show me security anomalies from last week
@workspace Give me optimization recommendations
```

## Real-World Example: Optimization Workflow

Let's walk through a complete optimization workflow:

### Step 1: Discovery
**Ask:** *"What are my biggest cost optimization opportunities?"*

**Orchestrator routes to Cost Optimizer Agent**

**Response:**
```
Top 3 Opportunities:
1. ANALYTICS_WH: 67% idle time → $3,100/month wasted
   Recommendation: Set auto_suspend = 5 minutes
   
2. REPORTING_WH: Running Large with 25% avg load
   Recommendation: Downsize to Medium → Save $2,100/month
   
3. Query QUERY_ID_XYZ: Spilling 45GB to remote storage
   Recommendation: Add clustering on ORDER_DATE → 80% faster, 60% less cost
```

### Step 2: Verification
**Ask:** *"Show me detailed idle patterns for ANALYTICS_WH"*

**Response:**
```
ANALYTICS_WH Idle Analysis (Last 7 Days):
- Total runtime: 168 hours
- Active query time: 55 hours
- Idle time: 113 hours (67%)
- Suspend/resume events: 342
- Median idle period: 8 minutes
- Wasted credits: 226 credits ($3,164)

Recommendation: Current auto_suspend appears to be 10+ minutes.
Setting it to 5 minutes would save ~$2,200/month.
```

### Step 3: Implementation
**Ask Admin to make the change:**
```sql
ALTER WAREHOUSE ANALYTICS_WH SET AUTO_SUSPEND = 300; -- 5 minutes
```

### Step 4: Validation (1 week later)
**Ask:** *"Did ANALYTICS_WH optimization work?"*

**Response:**
```
ANALYTICS_WH Post-Optimization (Last 7 Days):
- Idle time: 38 hours (23%) ← was 67%
- Wasted credits: 48 credits ($672) ← was $3,164
- Estimated monthly savings: $2,492
- Additional suspend/resume events: +89 (acceptable)

✓ Optimization successful!
```

## Real-World Example: Security Audit

### Step 1: Routine Check
**Ask:** *"Are there any security concerns I should know about?"*

**Orchestrator routes to Security Agent**

**Response:**
```
🔴 Critical Issues (2):
1. User 'john.doe' has ACCOUNTADMIN but hasn't logged in for 73 days
   Action: Revoke or investigate

2. 15 failed login attempts for 'admin_user' from 5 different IPs in last hour
   Action: Possible brute force attack - lock account

⚠️ High Priority (3):
1. 5 users have 6+ role assignments
2. 23 queries failed with "insufficient privileges" from 'analyst_role'
3. User 'contractor_temp' still has access 45 days after contract end

✓ Low Priority (8):
...
```

### Step 2: Investigation
**Ask:** *"Show me details on the failed login attempts for admin_user"*

**Response:**
```
Failed Login Analysis - admin_user:
Time Range: 2026-04-15 14:23 - 14:47 (24 minutes)
Failed Attempts: 15
Distinct IPs: 5 (suspicious!)
  - 203.0.113.45 (Russia) - 8 attempts
  - 198.51.100.23 (Unknown) - 4 attempts
  - 192.0.2.67 (Proxy) - 3 attempts

Error Pattern: "Invalid username or password" (all attempts)
Severity: CRITICAL - Possible credential stuffing attack

Recommendations:
1. Lock account immediately
2. Force password reset
3. Enable MFA if not already active
4. Review network policy to block suspicious IPs
```

### Step 3: Remediation
```sql
-- Lock account
ALTER USER admin_user SET DISABLED = TRUE;

-- Update network policy
ALTER NETWORK POLICY company_policy 
  SET BLOCKED_IP_LIST = ('203.0.113.45', '198.51.100.23', '192.0.2.67');

-- Review after resolution
ALTER USER admin_user SET DISABLED = FALSE;
```

## Deployment: From Prototype to Production

### Local Development
```bash
# 1. Deploy SQL objects
snowsql -f sql/06_create_cost_optimizer_views.sql
snowsql -f sql/07_create_cost_optimizer_semantic_views.sql
# ... (all SQL files in order)

# 2. Configure environment
cat > .env <<EOF
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_ORCHESTRATOR_AGENT_FQN=DB.SCHEMA.ORCHESTRATOR_AGENT
...
EOF

# 3. Start MCP server
python mcp/server.py
```

### Production (AWS)

For multi-user production deployment:

1. **Containerize** the MCP server
2. **Deploy to AWS App Runner** for auto-scaling
3. **Protect with Amazon Cognito** for JWT authentication
4. **Host frontend UI on AWS Amplify**

See [aws-hosting.md](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/docs/aws-hosting.md) for complete production setup.

## Performance & Cost Considerations

### Agent Execution Costs
- Each agent query executes on Snowflake compute
- Semantic views optimize query generation
- Typical query: 0.001 - 0.01 credits

### Optimization Tips
1. **Use Direct Agent Calls** when domain is known
   - Orchestrator adds routing overhead
   - Direct calls are ~30% faster

2. **Cache Frequent Queries**
   - Use Snowflake result caching
   - Set appropriate cache TTL

3. **Budget Controls**
   - Apply tags to agents
   - Set spending limits
   - Configure alerts at 80% threshold

Example budget setup:
```sql
CREATE BUDGET AGENT_BUDGET;
CALL AGENT_BUDGET!SET_SPENDING_LIMIT(100); -- 100 credits/month
CALL AGENT_BUDGET!SET_NOTIFICATION_THRESHOLD(80);
```

## Key Takeaways

### 1. Specialization Wins
Separate agents for distinct domains are easier to build, maintain, and reason about than one monolithic agent.

### 2. Orchestration Matters
Users shouldn't need to know which agent to ask. Intelligent routing provides seamless UX.

### 3. Semantic Views are Foundation
Well-designed semantic views make agents powerful. They abstract complexity and enable natural language queries.

### 4. Start Simple, Scale Up
Begin with one specialist agent, validate the approach, then add more. Our journey:
- Week 1: Admin Agent only
- Week 2: Added Cost Optimizer
- Week 3: Added Security Agent
- Week 4: Added Orchestrator

### 5. Integrate Everywhere
MCP protocol enables integration with:
- GitHub Copilot (IDE)
- VS Code Chat
- Slack bots
- Custom web UIs
- API endpoints

## What's Next?

### Expanding the Agent Team
- **Performance Tuning Agent**: Query optimization deep dives
- **Data Quality Agent**: Monitor freshness, completeness, accuracy
- **Schema Governance Agent**: Track DDL changes, review permissions

### Advanced Capabilities
- **Predictive Analytics**: Forecast costs, predict capacity needs
- **Automated Remediation**: Agents that fix issues, not just report them
- **Learning & Adaptation**: Agents that learn from user feedback

### Community & Open Source
This multi-agent architecture is template-based and fully reusable. Fork it, customize it, extend it!

Repository: [github.com/LALITHASWAROOPK/agent_snowflake_admin](https://github.com/LALITHASWAROOPK/agent_snowflake_admin)

## Conclusion

Building a multi-agent Snowflake administration system demonstrates the power of **specialized AI + intelligent orchestration**. Instead of wrestling with dashboards and SQL queries, you can simply ask:

- *"How much could I save?"*
- *"Are there security risks?"*
- *"What should I optimize first?"*

And get intelligent, actionable answers from a team of AI specialists working together.

The future of Snowflake administration isn't just automated—it's **conversational, intelligent, and proactive**.

---

**Try it yourself!** All code, SQL, and deployment guides are available in the [GitHub repository](https://github.com/LALITHASWAROOPK/agent_snowflake_admin). Questions? Open an issue on GitHub.

**Want to learn more?**
- [Multi-Agent Architecture Docs](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/docs/multi-agent-architecture.md)
- [AWS Production Deployment Guide](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/docs/aws-hosting.md)
- [Complete SQL Scripts](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/tree/main/sql)
- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex)
