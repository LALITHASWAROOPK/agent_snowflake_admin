---
name: cost-optimizer
description: Snowflake Cost Optimizer guidance for identifying waste, optimizing warehouse configurations, rightsizing resources, and maximizing cost efficiency.
---

# Cost Optimizer Guide

## Scope

Use this skill for:

- Idle warehouse detection and waste analysis
- Auto-suspend configuration recommendations
- Warehouse sizing and rightsizing opportunities
- Query optimization opportunities
- Cost savings potential calculations
- Warehouse utilization trend analysis

## Generic Object Pattern

Replace placeholders in this template:

- `<APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>`
- `<APP_DB>.<APP_SCHEMA>.SV_*` (Cost Optimizer semantic views)
- `<APP_DB>.<APP_SCHEMA>.V_*` (Cost Optimizer base views)

## Common Questions & Approaches

### Idle Warehouse Detection
**Question:** "Which warehouses are running idle?"
**Agent Response:** Analyzes warehouse uptime vs. productive query execution to identify wasted credits.

### Auto-Suspend Recommendations
**Question:** "What auto-suspend settings should I use?"
**Agent Response:** Reviews suspend/resume patterns to recommend optimal auto-suspend intervals (1, 5, 10 minutes).

### Warehouse Rightsizing
**Question:** "Are my warehouses oversized?"
**Agent Response:** Examines query load percentages and queue times to suggest downsizing or upsizing.

### Query Optimization
**Question:** "Which queries are wasting the most credits?"
**Agent Response:** Identifies expensive queries with spillage, low cache hits, or excessive scan.

### Cost Savings Summary
**Question:** "How much could I save?"
**Agent Response:** Aggregates idle waste and provides monthly savings potential.

## Best Practices

- Review idle warehouse reports weekly
- Implement recommended auto-suspend settings
- Monitor warehouse utilization trends for capacity planning
- Prioritize "Critical" and "High" priority query optimizations
- Track savings metrics before and after optimization changes

## Metrics to Monitor

- **Idle Credits**: Total credits consumed during idle periods
- **Idle Percentage**: Percentage of warehouse runtime spent idle
- **Median Idle Minutes**: Typical idle time between suspend/resume
- **P95 Load Percent**: 95th percentile warehouse load
- **Spillage**: Data spilled to remote storage (indicates undersized warehouse or inefficient query)
- **Cache Hit Rate**: Percentage of data served from cache
