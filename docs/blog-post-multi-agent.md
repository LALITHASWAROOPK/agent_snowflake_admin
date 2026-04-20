# From One Agent to Many: Adding Cost Optimization to Your Snowflake AI Assistant (Part 2)

## Introduction

In [Part 1](https://dev.to/swaroop_krishna_e2f4b83b2/ask-your-snowflake-account-anything-build-an-ai-admin-agent-with-cortex-github-copilot-1mk6), we built an **Admin Agent** that answers questions about Snowflake usage, credits, and query history. It's great for monitoring *what happened*, but what if you want to go beyond monitoring and actually **find waste** and **recommend optimizations**?

In this post, I'll show you how to:
1. Build a **Cost Optimizer Agent** specialized in finding inefficiencies
2. Create an **Orchestrator Agent** that intelligently routes questions to the right specialist
3. Make them work together as a team

By the end, you'll have a multi-agent system where you can ask:
- *"How much could I save?"* → Routes to Cost Optimizer
- *"Show me last month's credits"* → Routes to Admin Agent  
- *"Give me a complete analysis"* → Routes to both agents

## Why Add a Second Agent?

The Admin Agent from Part 1 is great at answering *"what happened?"* questions:
- "How many credits did we use?"
- "Show me query counts by warehouse"
- "What's our storage trend?"

But it doesn't analyze patterns or recommend actions. For that, we need a **specialist** focused on optimization.

## The Solution: Add a Cost Optimizer Specialist

Enter the **Cost Optimizer Agent** - designed to:
- Detect idle warehouses wasting credits
- Recommend auto-suspend settings
- Identify oversized warehouses
- Find queries that need optimization

Instead of one monolithic agent, we now have **two specialists working together**:

### 🔧 Admin Agent (from Part 1)
**Focus:** Operational metrics and monitoring
- Warehouse usage and credits
- Query history and performance
- Storage metrics
- User spend attribution

### 💰 Cost Optimizer Agent (new!)
**Focus:** Waste detection and cost reduction
- Idle warehouse detection
- Auto-suspend recommendations
- Warehouse rightsizing
- Query optimization opportunities

### 🧠 Orchestrator Agent (new!)
**Focus:** Intelligent routing
- Understands user intent
- Routes to appropriate specialist
- Aggregates responses from multiple agents

## The Architecture

Here's how these two agents work together:

```
User Question (natural language)
        ↓
  Orchestrator Agent
    ↙           ↘
Admin Agent   Cost Optimizer Agent
    ↘           ↙
  Combined Response
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

### Example Flow: Multi-Agent Query

**Question:** *"Give me a cost and usage analysis for ANALYTICS_WH"*

The Orchestrator recognizes this spans multiple domains:
1. Routes to **Admin Agent** → Returns credit usage, query counts, uptime
2. Routes to **Cost Optimizer** → Returns idle time, waste analysis, recommendations
3. **Aggregates results** into comprehensive report:

```
ANALYTICS_WH Analysis:

Usage Metrics (Admin Agent):
  - Total Credits (30 days): 1,856 credits
  - Average Daily: 61.9 credits
  - Query Count: 12,847 queries
  - Active Days: 30 of 30

Cost Optimization (Cost Optimizer Agent):
  - Idle Time: 67%
  - Wasted Credits: 1,243 credits ($4,351 at $3.50/credit)
  - Current auto_suspend: Not set (or >30 min)
  
Recommendation: SET AUTO_SUSPEND = 300 (5 minutes)
Estimated Monthly Savings: ~$2,900
```

## Building the Foundation: Semantic Views

The Cost Optimizer Agent is powered by **semantic views** that abstract complex SQL into natural language concepts.

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

> 📁 **Full SQL:** See [sql/06_create_cost_optimizer_views.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/06_create_cost_optimizer_views.sql) and [sql/07_create_cost_optimizer_semantic_views.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/07_create_cost_optimizer_semantic_views.sql) for complete implementation.

## Creating the Cost Optimizer Agent

The Cost Optimizer is a Snowflake Cortex Agent with carefully crafted instructions:

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

> 📁 **Full SQL:** See [sql/10_create_cost_optimizer_agent.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/10_create_cost_optimizer_agent.sql) for the complete agent definition.

## The Orchestrator: Tying It All Together

The Orchestrator Agent is the brains of the operation - it understands your question and routes it to the right specialist:

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
      - AdminAgent: Operational metrics, query history, credits, usage
      - CostOptimizerAgent: Waste detection, optimization, savings recommendations
      
      Routing guidelines:
      - "credits spent", "warehouse usage", "query count" → AdminAgent
      - "waste", "idle", "optimization", "savings" → CostOptimizerAgent
      - Questions needing both context and optimization → both agents
      
      Examples:
      - "How many credits did X warehouse use?" → AdminAgent only
      - "Is X warehouse wasting credits?" → CostOptimizerAgent only
      - "Analyze X warehouse efficiency" → Both agents (usage + waste)

  tools:
    - tool_spec: { type: "function", name: "AdminAgent", ... }
    - tool_spec: { type: "function", name: "CostOptimizerAgent", ... }
  $$;
```

> 📁 **Full SQL:** See [sql/12_create_orchestrator_agent.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/12_create_orchestrator_agent.sql)

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
                "name": "ask_admin",
                "description": "Direct query to Admin Agent",
                "parameters": {"question": "string"}
            },
            {
                "name": "ask_cost_optimizer",
                "description": "Direct query to Cost Optimizer",
                "parameters": {"question": "string"}
            }
        ]
    
    def call_tool(self, tool_name, question):
        agent_map = {
            "ask_orchestrator": ORCHESTRATOR_AGENT_FQN,
            "ask_admin": ADMIN_AGENT_FQN,
            "ask_cost_optimizer": COST_OPTIMIZER_AGENT_FQN,
        }
        
        return ask_agent(question, agent_map[tool_name])
```

Now you can use GitHub Copilot Chat:

```
@workspace How much are we spending on idle warehouses?
@workspace Show me optimization recommendations for ANALYTICS_WH
@workspace Compare usage vs waste for our top 5 warehouses
```

> 📁 **Full MCP Server:** See [mcp/server.py](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/mcp/server.py)

## Complete Optimization Workflow

Here's a full workflow showing how the agents work together to identify and fix waste:

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

## Deployment: From Prototype to Production

### Quick Start

If you built the Admin Agent from Part 1, here's how to add the Cost Optimizer:

```bash
# 1. Deploy Cost Optimizer views and semantic views
snowsql -f sql/06_create_cost_optimizer_views.sql
snowsql -f sql/07_create_cost_optimizer_semantic_views.sql

# 2. Create Cost Optimizer Agent
snowsql -f sql/10_create_cost_optimizer_agent.sql

# 3. Create Orchestrator (routes between agents)
snowsql -f sql/12_create_orchestrator_agent.sql

# 4. Test it!
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'ORCHESTRATOR_AGENT',
    '{"messages":[{"role":"user","content":[{"type":"text","text":"Which warehouses are idle?"}]}]}'
);
```

> 📁 **All SQL Scripts:** [https://github.com/LALITHASWAROOPK/agent_snowflake_admin/tree/main/sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/tree/main/sql)

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
Begin with one specialist agent, validate the approach, then add more:
- Part 1: Admin Agent only
- Part 2: Added Cost Optimizer + Orchestrator (this post)
- Part 3: Security Agent (coming next)

### 5. Integrate Everywhere
MCP protocol enables integration with:
- GitHub Copilot (IDE)
- VS Code Chat
- Slack bots
- Custom web UIs
- API endpoints

## What's Next?

In **Part 3**, I'll show you how to add a **Security & Governance Agent** that:
- Audits role assignments and privileges
- Detects failed login patterns (brute force attacks)
- Identifies inactive users with access
- Monitors for compliance violations

Then we'll have a complete **three-agent team**:
- 🔧 Admin - Operational metrics
- 💰 Cost Optimizer - Waste detection
- 🔐 Security - Compliance and access control

All coordinated by the Orchestrator.

### Expanding Further
- **Performance Tuning Agent**: Query optimization deep dives
- **Data Quality Agent**: Monitor freshness, completeness, accuracy
- **Automated Remediation**: Agents that fix issues, not just report them

## Conclusion

In Part 1, we built one agent. In Part 2, we:
1. ✅ Added a specialized **Cost Optimizer Agent**
2. ✅ Created an **Orchestrator** for intelligent routing
3. ✅ Made them work together as a team

**The multi-agent pattern is powerful because:**
- Each agent specializes in one domain
- Orchestrator handles routing automatically
- Easy to add new agents without changing existing ones
- Users get comprehensive answers from one question

**From the user's perspective:**
```
Before: "Which agent should I ask about idle warehouses?"
After: "Which warehouses are idle?" (Orchestrator figures it out)
```

In Part 3, we'll add a Security & Governance Agent to complete the team!

---

**Try it yourself!** All code, SQL, and deployment guides are available in the [GitHub repository](https://github.com/LALITHASWAROOPK/agent_snowflake_admin). Questions? Open an issue on GitHub.

**Want to learn more?**
- [Multi-Agent Architecture Docs](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/docs/multi-agent-architecture.md)
- [Complete SQL Scripts](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/tree/main/sql)
- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex)

---

*Part 1: [Build an AI Admin Agent](https://dev.to/swaroop_krishna_e2f4b83b2/ask-your-snowflake-account-anything-build-an-ai-admin-agent-with-cortex-github-copilot-1mk6)*  
*Part 2: Multi-Agent Architecture (this post)*  
*Part 3: Security & Governance Agent (coming soon)*
