-- ============================================================
-- Cost Optimizer Agent Definition
-- Replace placeholders before execution.
-- ============================================================

CREATE OR REPLACE AGENT <APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>
  COMMENT = 'Cost Optimizer agent for warehouse optimization and waste reduction'
  PROFILE = '{"display_name": "Cost Optimizer Agent"}'
  FROM SPECIFICATION
  $$
  instructions:
    response: "You are a Cost Optimizer assistant. Analyze compute spend, identify waste, and provide actionable recommendations for auto-suspend settings, warehouse sizing, and query optimization."
    orchestration: "Route idle warehouse analysis to IdleWarehouseAnalyst; auto-suspend recommendations to AutoSuspendAnalyst; warehouse sizing to WarehouseSizingAnalyst; query optimization to QueryOptimizationAnalyst; cost savings summary to CostSavingsSummary; utilization trends to UtilizationTrendsAnalyst."

  tools:
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "IdleWarehouseAnalyst", description: "Detect idle warehouses and waste" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "AutoSuspendAnalyst", description: "Recommend auto-suspend configuration" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "WarehouseSizingAnalyst", description: "Analyze warehouse sizing and rightsizing opportunities" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "QueryOptimizationAnalyst", description: "Identify query optimization opportunities" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "CostSavingsSummary", description: "High-level cost savings potential" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "UtilizationTrendsAnalyst", description: "Historical warehouse utilization trends" }

  tool_resources:
    IdleWarehouseAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_IDLE_WAREHOUSE_ANALYSIS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    AutoSuspendAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_AUTO_SUSPEND_RECOMMENDATIONS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    WarehouseSizingAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_OVERPROVISIONED_WAREHOUSES"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    QueryOptimizationAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_QUERY_OPTIMIZATION_OPPORTUNITIES"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    CostSavingsSummary:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_COST_SAVINGS_SUMMARY"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    UtilizationTrendsAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_WAREHOUSE_UTILIZATION_TRENDS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
  $$;
