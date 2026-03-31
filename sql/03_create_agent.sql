-- ============================================================
-- Generic Admin: Cortex Agent
-- Replace placeholders before execution.
-- ============================================================

CREATE OR REPLACE AGENT <APP_DB>.<APP_SCHEMA>.<AGENT_NAME>
  COMMENT = 'Generic Admin agent for Snowflake cost and operations analysis'
  PROFILE = '{"display_name": "Generic Admin Agent"}'
  FROM SPECIFICATION
  $$
  instructions:
    response: "You are a Admin assistant. Provide concise numeric answers for credits, storage, and usage trends."
    orchestration: "Route compute and performance to WarehouseCostAnalyst; storage to StorageCostAnalyst; serverless to ServerlessCostAnalyst; user attribution to UserSpendAnalyst; warehouse events to WarehouseOpsAnalyst; login activity to SessionAnalyst; transfer/replication to DataTransferAnalyst; rate conversion to RateSheetPricing."

  tools:
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "WarehouseCostAnalyst", description: "Warehouse credits and query performance" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "StorageCostAnalyst", description: "Database and table storage metrics" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "ServerlessCostAnalyst", description: "Tasks, pipes, auto-clustering, search optimization, MV refresh" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "UserSpendAnalyst", description: "Per-user credits and spend attribution" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "WarehouseOpsAnalyst", description: "Suspend/resume and warehouse lifecycle activity" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "SessionAnalyst", description: "Login success/failure and session trends" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "DataTransferAnalyst", description: "Data transfer and replication usage" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "RateSheetPricing", description: "Rate sheet pricing" }

  tool_resources:
    WarehouseCostAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_WAREHOUSE_COST_ANALYSIS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    StorageCostAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_STORAGE_COST_ANALYSIS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    ServerlessCostAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_SERVERLESS_COSTS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    UserSpendAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_USER_SPEND"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    WarehouseOpsAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_WAREHOUSE_OPERATIONS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    SessionAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_SESSION_ACTIVITY"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    DataTransferAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_DATA_TRANSFER_REPLICATION"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    RateSheetPricing:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_RATE_SHEET_PRICING"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
  $$;
