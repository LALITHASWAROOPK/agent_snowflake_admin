---
title: "From One Agent to Many: Building a Multi-Agent Team for Snowflake Administration (Part 2)"
published: false
description: "Add a Cost Optimizer Agent and Orchestrator to create an intelligent multi-agent system for Snowflake cost optimization"
tags: snowflake, ai, cost-optimization, cortex
series: Snowflake AI Agents
cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/articles/placeholder.jpg
---

# From One Agent to Many: Building a Multi-Agent Team for Snowflake Administration (Part 2)

In [Part 1](https://dev.to/swaroop_krishna_e2f4b83b2/ask-your-snowflake-account-anything-build-an-ai-admin-agent-with-cortex-github-copilot-1mk6), we built an **Admin Agent** that answers questions about Snowflake usage, credits, and query history. It's incredibly useful for monitoring operational metrics.

But what if you want to go beyond monitoring and actually **find waste** and **recommend optimizations**?

In this post, I'll show you how to:
1. Build a **Cost Optimizer Agent** specialized in finding inefficiencies
2. Create an **Orchestrator Agent** that intelligently routes questions to the right specialist
3. Make them work together as a team

By the end, you'll have a multi-agent system where you can ask:
- *"How much could I save?"* → Routes to Cost Optimizer
- *"Show me last month's credits"* → Routes to Admin Agent  
- *"Give me a complete analysis"* → Routes to both agents

Let's build it! 🚀

## Why Add a Second Agent?

The Admin Agent from Part 1 is great at answering *"what happened?"* questions:
- "How many credits did we use?"
- "Show me query counts by warehouse"
- "What's our storage trend?"

But it doesn't analyze patterns or recommend actions. For that, we need a **specialist** focused on optimization.

Enter the **Cost Optimizer Agent** - designed to:
- Detect idle warehouses wasting credits
- Recommend auto-suspend settings
- Identify oversized warehouses
- Find queries that need optimization

**Why separate agents instead of one big agent?**

1. **FoArchitecture: Three Agents Working Together

Here's what we're building:

```
User Question (natural language)
        ↓
  Orchestrator Agent
    ↙           ↘
Admin Agent   Cost Optimizer Agent
    ↘           ↙
  Combined Response
```

**Admin Agent** (from Part 1):
- Already built and working
- Handles operational metrics
- Answers "what happened?" questions

**Cost Optimizer Agent** (new):
- Analyzes patterns for waste
- Recommends optimizations
- Answers "what should I fix?" questions

**Orchestrator Agent** (new):
- Routes questions to appropriate specialist
- Can call multiple agents for comprehensive answers
- Users don't need to know which agent to ask

**Example Questions:**
- "Which warehouses have high idle time?"
- "Are any warehouses oversized for their workload?"
- "Show me queries with excessive spillage"

## Technical Example: Analyzing Warehouse Idle Time

Let me show you how these agents work together to identify and quantify optimization opportunities.

### The Pattern (Same as Part 1)

**Step 1: Base View** - Calculate idle time by comparing warehouse uptime vs. query execution
- Join `WAREHOUSE_METERING_HISTORY` (credits consumed) with `QUERY_ATTRIBUTION_HISTORY` (actual work done)
- The gap = idle credits

**Step 2: Semantic View** - Map the data to natural language
- FACTS: `idle_credits`, `idle_percentage`, `idle_cost_usd`
- DIMENSIONS: `warehouse_name`, `uptime_date`
- METRICS: sum of idle credits, average idle percentage

**Step 3: Create Agent** - Connect the semantic view to the Cortex agent
- Agent instructions: "Find waste and recommend fixes"
- Tool: `IdleWarehouseAnalyst` using the semantic view

**Step 4: Test It**

```sql
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'COST_OPTIMIZER_AGENT',
    '{"messages":[{"role":"user","content":[{"type":"text","text":"Which warehouses have high idle time?"}]}]}'
);
```

> 📁 **Full SQL Implementation:** [sql/06_create_cost_optimizer_views.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/06_create_cost_optimizer_views.sql) | [sql/07_create_cost_optimizer_semantic_views.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/07_create_cost_optimizer_semantic_views.sql) | [sql/10_create_cost_optimizer_agent.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/10_create_cost_optimizer_agent.sql)

**Example Response:**
```
BRONZE_LOADER_WH Analysis (Last 30 Days):

Idle Time: 68% 
Idle Credits: 892 credits
Pattern: Warehouse runs continuously but data loads are batch-based

Recommendation: Set AUTO_SUSPEND = 300 seconds (5 minutes)
Reasoning: Bronze data loads complete, then warehouse sits idle 
           waiting for next batch

Estimated savings: ~600 credits/month
```

Great! Now we have two specialized agents. But there's a problem...

## Part 2: Adding the Orchestrator

**The Problem:** Now users need to know which agent to ask:
- Questions about credits → Ask Admin Agent
- Questions about optimization → Ask Cost Optimizer Agent

That doesn't scale. What if someone asks *"Why are my costs high?"* - which agent should handle that?

**The Solution:** An Orchestrator Agent that routes questions automatically.

### The Pattern

**Step 1: Routing Function** - Python UDF that lets one agent call another
- Takes agent FQN and question as parameters
- Calls `SNOWFLAKE.CORTEX.DATA_AGENT_RUN` programmatically
- Returns the agent's response

**Step 2: Orchestrator Agent** - Meta-agent that routes to specialists
- Instructions define routing logic (keywords: "idle"→Cost, "credits"→Admin)
- Tools reference the routing function
- Can call multiple agents for comprehensive analysis

**Step 3: Grant Permissions** - Allow orchestrator to invoke specialist agents

> 📁 **Full Implementation:** [sql/12_create_orchestrator_agent.sql](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/sql/12_create_orchestrator_agent.sql)

## Part 3: Seeing It All Work Together

Now let's test the complete system.

### Example 1: Simple Routing

**Question:** *"How many credits did BRONZE_LOADER_WH use last month?"*

**What Happens:**
1. Orchestrator receives question
2. Identifies this as operational metrics (keywords: "credits", "use")
3. Routes to **Admin Agent**
4. Admin Agent queries `SV_WAREHOUSE_COST_ANALYSIS`
5. Returns credit numbers

**Response:**
```
BRONZE_LOADER_WH Credit Usage (Last 30 Days):
Total Credits: 1,312
Average Daily: 43.7 credits
Active Days: 30 of 30 (runs daily for ETL loads)
```

### Example 2: Optimization Routing

**Question:** *"Is BRONZE_LOADER_WH wasting credits?"*

**What Happens:**
1. Orchestrator receives question
2. Identifies this as optimization (keywords: "wasting")
3. Routes to **Cost Optimizer Agent**
4. Cost Optimizer queries `SV_IDLE_WAREHOUSE_ANALYSIS`
5. Returns analysis with recommendations

**Response:**
```
BRONZE_LOADER_WH Waste Analysis:

Idle Percentage: 68%
Idle Credits: 892 credits
Pattern: Batch ETL jobs complete quickly, warehouse stays running

Recommendation:
ALTER WAREHOUSE BRONZE_LOADER_WH SET AUTO_SUSPEND = 300;

Estimated Monthly Savings: ~600 credits
Reasoning: Bronze loads are periodic - warehouse doesn't need to 
           stay running between batch jobs
```

### Example 3: Multi-Agent Analysis

**Question:** *"Give me a complete analysis of BRONZE_LOADER_WH"*

**What Happens:**
1. Orchestrator recognizes need for comprehensive analysis
2. Routes question to **BOTH** agents:
   - Admin Agent: Get usage metrics
   - Cost Optimizer: Get efficiency analysis
3. Aggregates both responses

**Response:**
```
BRONZE_LOADER_WH Complete Analysis:

📊 USAGE (from Admin Agent):
- Total Credits (30 days): 1,312
- Average Daily: 43.7 credits
- Primary Workload: Bronze layer ETL (raw data ingestion)
- Load Schedule: Hourly batches from source systems
- Active Days: 30 of 30

💰 EFFICIENCY (from Cost Optimizer):
- Idle Time: 68%
- Wasted Credits: 892 credits
- Pattern: Loads complete in ~15 min, then idle for 45 min
- Current auto_suspend: Not set (or >30 min)

RECOMMENDATION:
ETL warehouse with batch workload pattern. Jobs complete quickly 
but warehouse stays running between batches.

Action: SET AUTO_SUSPEND = 300 (5 minutes)
Impact: ~600 credits/month savings with no performance impact
```

Beautiful! The user just asked one question and got insights from two specialists.

##   Technical Architecture: How It Actually Works

Let me break down the three layers that make these agents work.

### Layer 1: Base Views (Data Calculation)

These views do the actual computational work by querying `ACCOUNT_USAGE`. For example, idle warehouse detection compares:
- `WAREHOUSE_METERING_HISTORY` (when warehouse was running)
- `QUERY_ATTRIBUTION_HISTORY` (when queries were executing)
- The gap = wasted compute

### Layer 2: Semantic Views (Natural Language Mapping)

These teach the agent what the data means:
- **FACTS**: Raw values (idle_credits, idle_percentage)
- **DIMENSIONS**: Grouping columns (warehouse_name, date)  
- **METRICS**: Aggregations (SUM, AVG)

### Layer 3: Agents (Natural Language Interface)

Each agent:
1. Receives natural language question
2. Determines which semantic view to query
3. Cortex Analyst generates SQL automatically
4. Executes and returns natural language answer

### MCP Integration (Optional)

For easier access, you can build an **MCP (Model Context Protocol) server** to integrate with GitHub Copilot:

```python
# Simplified MCP Server Pattern
def ask_agent(question: str, agent_fqn: str) -> dict:
    payload = {"messages": [{"role": "user", "content": [{"type": "text", "text": question}]}]}
    result = conn.cursor().execute(f"SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN('{agent_fqn}', '{json.dumps(payload)}')")
    return json.loads(result.fetchone()[0])
```

> 📁 **Full MCP Server:** [mcp/server.py](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/mcp/server.py)

## How the Agents Work Together

Here's the beautiful part: **the Admin Agent provides context, and the Cost Optimizer provides action**.

### Example: Analyzing Bronze ETL Warehouse

**Question:** *"Should I optimize BRONZE_LOADER_WH?"*

**Admin Agent** provides context:
```
BRONZE_LOADER_WH Usage:
  - Credits (30 days): 1,312
  - Workload: Bronze layer ETL
  - Schedule: Hourly batch loads
```

**Cost Optimizer** provides analysis:
```
Efficiency Analysis:
  - Idle time: 68%
  - Pattern: 15-min loads, 45-min idle gaps
  - Recommendation: SET AUTO_SUSPEND = 300
  - Expected savings: ~600 credits/month
```

**Together, they provide:**
1. **Context** - What the warehouse does (bronze ETL)
2. **Root cause** - Batch pattern creates idle gaps
3. **Solution** - Auto-suspend between batches
4. **Impact** - Savings estimate without performance impact

This combination ensures you get both **what's happening** and **what to do about it** in one conversation.

## Quick Start: Adding to Your Existing Agent

If you built the Admin Agent from Part 1, here's the deployment sequence:

```bash
# 1. Cost Optimizer Agent
sql/06_create_cost_optimizer_views.sql          # Base views
sql/07_create_cost_optimizer_semantic_views.sql # Semantic layer
sql/10_create_cost_optimizer_agent.sql          # Agent

# 2. Orchestrator Agent  
sql/12_create_orchestrator_agent.sql            # Routing agent + function

# 3. Test it
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'ORCHESTRATOR_AGENT',
    '{"messages":[{"role":"user","content":[{"type":"text","text":"Which warehouses are idle?"}]}]}'
);
```

> 📁 **All SQL scripts:** [GitHub Repository](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/tree/main/sql)

You now have a working multi-agent system!

## Agent Execution Costs

Each agent query executes on a Snowflake warehouse and consumes credits:

**Typical costs:**
- Simple query (1 warehouse, 1 dimension): ~0.001-0.002 credits
- Complex query (joins, aggregations): ~0.005-0.01 credits
- Very complex analysis (multiple time ranges): ~0.01-0.05 credits

**Example usage:**
- 100 agent queries/day
- Average 0.005 credits per query
- Total: 0.5 credits/day = ~15 credits/month
- At $3.50/credit: ~$52/month

The agents themselves cost very little to run compared to the insights they provide.

## Key Lessons Learned

### 1. Orchestration Makes It Seamless
Without the Orchestrator, users need to know:
- Which agent handles which questions
- How to call different agents
- When to use multiple agents

With the Orchestrator:
- Just ask naturally
- Routing happens automatically
- Multi-agent queries work transparently

### 2. Agent Communication Is Key
The routing function enables:
- One agent calling another
- Aggregating responses
- Building complex workflows

Pattern: **Function → Agent calls other agents via that function**

### 3. Start with Two, Scale to Many
This architecture scales easily:
- Each new agent is independent
- Orchestrator routing rules are additive
- No changes needed to existing agents

### 4. Test Routing Logic
Make sure to test:
- Edge cases (ambiguous questions)
- Multi-agent scenarios
- Direct vs. orchestrated access
- Response aggregation quality

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

## Code Repository

All SQL scripts and complete implementation available at:
[GitHub Repository](https://github.com/LALITHASWAROOPK/agent_snowflake_admin)

Includes:
- Base view SQL for idle detection
- Additional views for warehouse sizing, query optimization
- Semantic view definitions
- All three agent configurations
- MCP server code for Copilot integration
- Step-by-step deployment guide
- **API endpoints** - Integrate with existing dashboards
- **Scheduled queries** - Automated monitoring with alerts
- **GitHub Copilot** - Ask questions directly from your IDE[github.com/LALITHASWAROOPK/agent_snowflake_admin](https://github.com/LALITHASWAROOPK/agent_snowflake_admin)

**Includes:**
- All SQL scripts (base views, semantic views, agents)
- MCP server for GitHub Copilot integration
- Deployment guide
- Example questions and expected outputs

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

This is just the beginning. You can extend this architecture with:
- Security agents for compliance
- Performance agents for query optimization  
- Data quality agents for monitoring freshness
- Custom agents for your specific needs

The pattern stays the same: **Views → Semantic Views → Agent → Orchestrator**

---

**Questions or feedback?** Drop a comment below!

**Find this helpful?** Give it a ❤️ and stay tuned for Part 3: Security & Governance Agent

**Want to discuss?** Connect with me on [LinkedIn](your-linkedin) or [Twitter](your-twitter)

---

## Quick Reference: Agent Responsibilities

| Agent | Purpose | Example Questions |
|-------|---------|------------------|
| **Admin** | Operational metrics | "How many credits did BRONZE_LOADER_WH use?" |
| **Cost Optimizer** | Waste detection | "Is BRONZE_LOADER_WH running idle?" |
| **Orchestrator** | Intelligent routing | "Analyze BRONZE_LOADER_WH efficiency" |

---

*Part 1: [Build an AI Admin Agent](https://dev.to/swaroop_krishna_e2f4b83b2/ask-your-snowflake-account-anything-build-an-ai-admin-agent-with-cortex-github-copilot-1mk6)*  
*Part 2: Multi-Agent Architecture (this post)*  
*Part 3: Security & Governance Agent (coming soon)*
