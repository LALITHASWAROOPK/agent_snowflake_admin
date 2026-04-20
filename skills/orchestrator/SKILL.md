---
name: orchestrator
description: Intelligent orchestrator for routing Snowflake administration questions to specialized agents (Admin, Cost Optimizer, Security & Governance).
---

# Orchestrator Guide

## Purpose

The Orchestrator Agent is the intelligent entry point for all Snowflake administration questions. It:
1. Understands natural language questions
2. Routes requests to the most appropriate specialist agent(s)
3. Aggregates responses when multiple agents are needed
4. Provides comprehensive, actionable insights

## Agent Architecture

```
User Question → Orchestrator Agent
                      ↓
        ┌─────────────┼─────────────┐
        ↓             ↓             ↓
   Admin Agent   Cost Optimizer  Security Agent
        ↓             ↓             ↓
        └─────────────┼─────────────┘
                      ↓
              Aggregated Response
```

## Routing Logic

### Admin Agent
**Routes to:** Operational metrics, current state, historical analysis
**Keywords:** credits, usage, queries, storage, warehouse activity, serverless costs, user spend
**Example Questions:**
- "How many credits did we use last month?"
- "What's our total storage usage?"
- "Show me query history for COMPUTE_WH"

### Cost Optimizer Agent
**Routes to:** Waste identification, optimization opportunities, cost savings
**Keywords:** idle, waste, optimize, savings, rightsizing, auto-suspend, expensive queries
**Example Questions:**
- "Which warehouses are running idle?"
- "How much could we save this month?"
- "Are my warehouses oversized?"

### Security & Governance Agent
**Routes to:** Access control, privilege management, compliance, auditing
**Keywords:** security, roles, privileges, failed logins, unauthorized, access, compliance
**Example Questions:**
- "Who has ACCOUNTADMIN privileges?"
- "Show me failed login attempts"
- "Are there any security anomalies?"

## Multi-Agent Queries

Some questions require input from multiple agents:

**Example:** "Give me a complete cost and security overview"
- Routes to: Admin Agent (for baseline metrics) + Cost Optimizer (for waste) + Security Agent (for compliance)

**Example:** "Show me expensive queries with access violations"
- Routes to: Cost Optimizer (for expensive queries) + Security Agent (for access violations)

## Generic Object Pattern

- Orchestrator: `<APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>`
- Admin Agent: `<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>`
- Cost Optimizer: `<APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>`
- Security Agent: `<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>`

## Best Practices

### When to Use Orchestrator
- **Use for general questions** - "What's happening in my Snowflake account?"
- **Use for complex analysis** - "Full cost and security audit"
- **Use when domain is unclear** - Let the orchestrator decide routing

### When to Use Specialist Agents Directly
- **Known domain** - If you know you need cost optimization, go directly to Cost Optimizer
- **Focused analysis** - For deep dives into a specific area
- **Performance** - Direct calls skip routing overhead

## Configuration

Set environment variables for all agents:
```bash
SNOWFLAKE_ORCHESTRATOR_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>
SNOWFLAKE_ADMIN_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>
SNOWFLAKE_COST_OPTIMIZER_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>
SNOWFLAKE_SECURITY_AGENT_FQN=<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>
```

## MCP Tool Usage

### Recommended (via Orchestrator)
```typescript
mcp.askOrchestrator({
  question: "What optimizations can I make to reduce costs?"
})
```

### Direct Access
```typescript
// Direct to Cost Optimizer
mcp.askCostOptimizer({
  question: "Show idle warehouses"
})

// Direct to Security
mcp.askSecurity({
  question: "List privileged role assignments"
})

// Direct to Admin
mcp.askAdmin({
  question: "Total credits used this month"
})
```

## Troubleshooting

### Orchestrator Not Routing Correctly
- Check agent FQN environment variables
- Verify all specialist agents are created in Snowflake
- Ensure grants are in place (orchestrator needs USAGE on specialist agents)

### Performance Issues
- Use direct agent calls for known domains
- Limit multi-agent queries to necessary combinations
- Monitor warehouse usage for agent execution

### Error Responses
- Verify semantic views are created
- Check warehouse permissions
- Ensure ACCOUNT_USAGE access is granted
