# LinkedIn Newsletter Edition: Part 3

## Headline Options

1. Building a Security and Governance Agent for Snowflake: Part 3 of the Multi-Agent Series
2. From Cost Optimization to Risk Control: Completing a Snowflake Multi-Agent Team
3. How We Added Security Intelligence to a Snowflake AI Admin Assistant

## Suggested Newsletter Settings

- Newsletter title: Snowflake AI Agents
- Edition title: Part 3 - Security and Governance Agent
- Suggested cover image theme: Security monitoring dashboard with role/privilege graph overlay
- Tags/keywords: Snowflake, AI Agents, Data Security, Governance, FinOps, Platform Engineering

## Newsletter Body (Copy/Paste Ready)

In Part 1, we built an Admin Agent to answer operational and cost questions.
In Part 2, we added a Cost Optimizer Agent plus an Orchestrator to route questions intelligently.

In this edition, I am sharing Part 3: adding a Security and Governance Agent so the system can answer not only "what happened" and "what should we optimize," but also "what is risky right now."

That gives us a complete specialist team for Snowflake administration.

## Why this matters

Most Snowflake assistant projects start with cost visibility.
That is useful, but incomplete.

Platform teams also need:

- Role and privilege hygiene
- Failed login anomaly detection
- Unauthorized access attempt visibility
- Inactive users who still have access
- Governance and compliance-ready audit context

Instead of creating one large, fragile prompt, I used a specialist-agent pattern.
Each agent stays focused, and the Orchestrator combines results when questions span domains.

## Final architecture

User question -> Orchestrator Agent -> specialist agents -> unified response.

Specialists in this implementation:

- Admin Agent: usage, credits, storage, operational metrics
- Cost Optimizer Agent: idle compute, rightsizing, optimization recommendations
- Security and Governance Agent: roles, privileges, failed logins, unauthorized access, audits

## What Part 3 adds technically

The same pattern from Parts 1 and 2 applies:

1. Base views from SNOWFLAKE.ACCOUNT_USAGE
2. Semantic views for natural-language grounding
3. Security and Governance Cortex Agent with focused tools
4. Orchestrator routing updates to include SecurityAgent

Key implementation files:

- sql/08_create_security_governance_views.sql
- sql/09_create_security_governance_semantic_views.sql
- sql/11_create_security_governance_agent.sql
- sql/12_create_orchestrator_agent.sql

## Example questions this now handles well

1. "Are there suspicious failed logins in the last 7 days?"
2. "Which users have ACCOUNTADMIN or SECURITYADMIN but low recent usage?"
3. "Why are costs up, and is there any security risk around this?"

That third question is where multi-agent design shows real value.
The Orchestrator can combine operational context, optimization analysis, and security posture in one response.

## Operational takeaway

If you are building AI assistants for data platforms, this pattern scales:

- Keep data logic in views
- Keep language mapping in semantic views
- Keep each agent domain-specific
- Keep orchestration explicit and testable

This gives you better maintainability, cleaner prompts, and safer evolution as scope expands.

## Important caveat

SNOWFLAKE.ACCOUNT_USAGE has latency.
For near-real-time incident response, combine this approach with event-driven telemetry and alerting.

## Full code

- Repository: https://github.com/LALITHASWAROOPK/agent_snowflake_admin
- SQL scripts: https://github.com/LALITHASWAROOPK/agent_snowflake_admin/tree/main/sql
- MCP server: https://github.com/LALITHASWAROOPK/agent_snowflake_admin/blob/main/mcp/server.py

## Series links

- Part 1: https://dev.to/swaroop_krishna_e2f4b83b2/ask-your-snowflake-account-anything-build-an-ai-admin-agent-with-cortex-github-copilot-1mk6
- Part 2: https://dev.to/swaroop_krishna_e2f4b83b2/from-one-agent-to-many-building-a-multi-agent-team-for-snowflake-administration-part-2-379d
- Part 3 (Dev.to draft in repo): docs/devto-blog-post-part3.md

## Closing

Part 1 gave visibility.
Part 2 gave optimization.
Part 3 adds governance and risk control.

Same architecture pattern, broader impact.

If you are working on platform AI or Snowflake operations, I would love to hear how you are handling security and governance in your agent workflows.

## Optional CTA variants

- Comment "PART3" and I will share the deployment sequence.
- If you want the Orchestrator routing template, message me and I will send the structure.
- Next edition: automated remediation playbooks by risk severity.
