---
title: "From Optimization to Protection: Adding a Security and Governance Agent to Your Snowflake Multi-Agent Team (Part 3)"
published: false
description: "Add a Security and Governance Agent to your Snowflake multi-agent system for role audits, failed login detection, unauthorized access monitoring, and compliance insights."
tags: snowflake, ai, security, governance
series: Snowflake AI Agents
cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/articles/placeholder.jpg
---

# From Optimization to Protection: Adding a Security and Governance Agent to Your Snowflake Multi-Agent Team (Part 3)

In [Part 1](https://dev.to/swaroop_krishna_e2f4b83b2/ask-your-snowflake-account-anything-build-an-ai-admin-agent-with-cortex-github-copilot-1mk6), we built an Admin Agent for usage and cost visibility.
In [Part 2](https://dev.to/swaroop_krishna_e2f4b83b2/from-one-agent-to-many-building-a-multi-agent-team-for-snowflake-administration-part-2-379d), we added a Cost Optimizer Agent and an Orchestrator that routes questions to specialists.

Now we close the loop with the third specialist: a **Security and Governance Agent**.

This turns your assistant from "what happened" and "what to optimize" into a full team that also answers "what is risky right now".

This edition introduces the complete 3-part journey in one place:
1. Operations visibility (Part 1)
2. Cost optimization (Part 2)
3. Security and governance with alerting focus (Part 3)

By the end of this post, you will have:
1. A Security and Governance Agent with focused security tools
2. Security semantic views mapped to natural language
3. Orchestrator routing across Admin, Cost Optimizer, and Security agents
4. A practical triage workflow for failed logins, privilege risk, and unauthorized access

## Why Add a Security Specialist?

The first two agents are strong for operations and spend, but security requires a different lens:

- Access control and role hygiene
- Failed login patterns and anomaly detection
- Unauthorized access attempts
- Inactive users with active privileges
- Compliance-friendly audit summaries

Could one large agent do everything? Sometimes. But specialized agents are easier to maintain, safer to evolve, and easier to test.

## Final Team Architecture

```text
User Question (natural language)
        |
  Orchestrator Agent
   /      |        \
Admin   Cost     Security
Agent  Optimizer Governance
                 Agent
        \    |    /
      Unified Response
```

### Role of each specialist

- Admin Agent: usage, credits, storage, operational metrics
- Cost Optimizer Agent: idle compute, rightsizing, optimization opportunities
- Security and Governance Agent: roles, privileges, failed logins, unauthorized access, audits

## The Security Pattern (Same Foundation as Parts 1 and 2)

### Step 1: Base Views

Create security-focused views over `SNOWFLAKE.ACCOUNT_USAGE`, including:

- Role hierarchy and privilege grants
- Failed login attempts and anomaly severity
- Excessive or unused privileged access
- Unauthorized access attempts
- User and role audit summaries
- Network policy activity

Implementation file:
- `sql/08_create_security_governance_views.sql`

### Step 2: Semantic Views

Map these views into natural language dimensions, facts, and metrics so Cortex Analyst can reason over them.

Examples:

- `SV_LOGIN_ANOMALIES`
- `SV_EXCESSIVE_PRIVILEGES`
- `SV_UNAUTHORIZED_ACCESS_ATTEMPTS`
- `SV_USER_ROLE_AUDIT`

Implementation file:
- `sql/09_create_security_governance_semantic_views.sql`

### Step 3: Create the Security Agent

Define a dedicated agent with explicit analyst tools for each security domain:

```sql
CREATE OR REPLACE AGENT <APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>
  COMMENT = 'Security and Governance agent for access control and compliance'
  FROM SPECIFICATION
  $$
  instructions:
    response: "You are a Security and Governance assistant..."
    orchestration: "Route role hierarchy questions to RoleHierarchyAnalyst; \
                   privilege grants to PrivilegeGrantAnalyst; \
                   failed logins to FailedLoginAnalyst; \
                   login anomalies to LoginAnomalyDetector..."

  tools:
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "RoleHierarchyAnalyst" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "PrivilegeGrantAnalyst" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "FailedLoginAnalyst" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "LoginAnomalyDetector" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "ExcessivePrivilegeAnalyst" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "UnauthorizedAccessAnalyst" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "UserAuditAnalyst" }
  $$;
```

Implementation file:
- `sql/11_create_security_governance_agent.sql`

### Step 4: Route Through the Orchestrator

Your orchestrator now includes `SecurityAgent` as a first-class route target.

```sql
-- in sql/12_create_orchestrator_agent.sql
-- Questions about security, roles, privileges, failed logins, unauthorized access -> SecurityAgent
```

It can also fan out to multiple agents for blended questions.

## Example 1: Security-Only Routing

Question:
"Are there suspicious login failures in the last 7 days?"

What happens:
1. Orchestrator classifies this as security monitoring
2. Routes to SecurityAgent
3. SecurityAgent uses `SV_LOGIN_ANOMALIES`
4. Returns severity-based findings and recommendations

Example response:

```text
Login Anomaly Summary (Last 7 Days)

Critical: 2 users with >= 10 failed attempts/hour
High: 5 users with 5-9 failed attempts/hour
Pattern: Multiple failed attempts from distinct IPs for USER_X

Recommendation:
- Lock and verify impacted accounts
- Enforce MFA re-registration for affected users
- Review network policy and source IP ranges
```

## Example 2: Privilege Governance

Question:
"Which users have ACCOUNTADMIN or SECURITYADMIN but low recent usage?"

What happens:
1. Routed to SecurityAgent
2. Uses `SV_EXCESSIVE_PRIVILEGES`
3. Identifies high-risk assignments with low usage

Example response:

```text
Excessive Privilege Findings

Users flagged: 4
Critical: 2 users with no privileged role usage in 60+ days
High: 2 users with < 5 privileged queries in 90 days

Recommendation:
- Revoke unused privileged grants
- Replace standing privilege with just-in-time elevation
- Document business justification for remaining elevated users
```

## Example 3: Cross-Agent Investigation

Question:
"Why are costs up and is there any security risk around this?"

What happens:
1. Orchestrator identifies multi-domain intent
2. Routes to AdminAgent + CostOptimizerAgent + SecurityAgent
3. Aggregates usage, optimization, and security posture into one answer

Example response:

```text
Integrated Account Assessment

Operations (Admin Agent)
- Compute credits up 18% month-over-month
- Growth concentrated in two ETL warehouses

Optimization (Cost Optimizer Agent)
- Idle percentage > 60% on one ETL warehouse
- Suggested AUTO_SUSPEND change could reduce waste materially

Security (Security Agent)
- One privileged user inactive but still assigned elevated role
- Increased failed login attempts from multiple IPs for two accounts

Priority Actions
1) Apply warehouse auto-suspend tuning
2) Review elevated role assignments and revoke unused grants
3) Investigate failed-login anomalies and tighten network controls
```

## Deployment Sequence

If you already deployed Parts 1 and 2:

```bash
# 1) Security views
sql/08_create_security_governance_views.sql

# 2) Security semantic layer
sql/09_create_security_governance_semantic_views.sql

# 3) Security agent
sql/11_create_security_governance_agent.sql

# 4) Orchestrator (includes SecurityAgent routing)
sql/12_create_orchestrator_agent.sql
```

## Testing Queries

Direct test:

```sql
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  '<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>',
  '{"messages":[{"role":"user","content":[{"type":"text","text":"Show failed login anomalies by severity"}]}]}'
);
```

Orchestrated test:

```sql
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  '<APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>',
  '{"messages":[{"role":"user","content":[{"type":"text","text":"Analyze account risk: costs, idle warehouses, and failed logins"}]}]}'
);
```

## Practical Notes

- `SNOWFLAKE.ACCOUNT_USAGE` views have latency. For near-real-time incident response, combine this with event-driven telemetry.
- Keep role and privilege reviews on a recurring schedule (monthly or quarterly depending on policy).
- Use placeholders and environment-specific grants consistently:
  - `<APP_DB>.<APP_SCHEMA>`
  - `<EXEC_WAREHOUSE>`
  - `<ADMIN_ROLE>`, `<DEVELOPER_ROLE>`
- Part 3 is where alerting should be operationalized: start with failed login anomalies, excessive privileged access, and unauthorized access attempt thresholds.

## What We Have Now

After Part 3, you have a complete multi-agent Snowflake administration team:

- Admin Agent for operational visibility
- Cost Optimizer Agent for efficiency and savings
- Security and Governance Agent for risk and compliance
- Orchestrator Agent for seamless, natural-language routing across all three

This is where multi-agent design pays off: each specialist stays focused, and users still ask one simple question.

## Code References

- Security base views: `sql/08_create_security_governance_views.sql`
- Security semantic views: `sql/09_create_security_governance_semantic_views.sql`
- Security agent: `sql/11_create_security_governance_agent.sql`
- Orchestrator routing: `sql/12_create_orchestrator_agent.sql`
- Security skill guidance: `skills/security-governance/SKILL.md`

## Code Repository

Complete implementation:

- [GitHub Repository](https://github.com/LALITHASWAROOPK/agent_snowflake_admin)
- [SQL Folder](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/tree/main/sql)
- [MCP Server](https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/mcp/server.py)

## Conclusion

Part 1 gave us visibility.
Part 2 gave us optimization.
Part 3 gives us governance and risk control.

Together, this edition introduces all three topics as one operating model for Snowflake platform teams, with Part 3 adding the security alerting layer.

Same architecture pattern, broader coverage:
**Views -> Semantic Views -> Specialist Agent -> Orchestrator**

Next directions:
- Add automated alerting and ticket creation workflows
- Add remediation playbooks per risk severity
- Add environment-level policy checks for continuous compliance

Questions or feedback? Drop a comment below.

Part 1: [Ask Your Snowflake Account Anything - Build an AI Admin Agent](https://dev.to/swaroop_krishna_e2f4b83b2/ask-your-snowflake-account-anything-build-an-ai-admin-agent-with-cortex-github-copilot-1mk6)
Part 2: [From One Agent to Many - Building a Multi-Agent Team](https://dev.to/swaroop_krishna_e2f4b83b2/from-one-agent-to-many-building-a-multi-agent-team-for-snowflake-administration-part-2-379d)
Part 3: Security and Governance Agent (this post)
