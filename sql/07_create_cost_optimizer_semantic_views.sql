-- ============================================================
-- Cost Optimizer Agent: Semantic Views
-- Replace <APP_DB>, <APP_SCHEMA>, and <CREDIT_RATE_USD>.
-- ============================================================

-- 1. Idle warehouse semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_IDLE_WAREHOUSE_ANALYSIS
  TABLES (
    iw AS <APP_DB>.<APP_SCHEMA>.V_IDLE_WAREHOUSES
  )
  FACTS (
    iw.total_credits AS iw.total_credits,
    iw.query_count AS iw.query_count,
    iw.active_execution_sec AS iw.active_execution_sec,
    iw.productive_credits AS iw.productive_credits,
    iw.idle_credits AS iw.idle_credits,
    iw.idle_percentage AS iw.idle_percentage,
    iw.cost_usd AS iw.total_credits * <CREDIT_RATE_USD>,
    iw.idle_cost_usd AS iw.idle_credits * <CREDIT_RATE_USD>
  )
  DIMENSIONS (
    iw.warehouse_name AS iw.warehouse_name,
    iw.uptime_date AS iw.uptime_date
  )
  METRICS (
    iw.total_idle_credits AS SUM(iw.idle_credits),
    iw.total_idle_cost_usd AS SUM(iw.idle_cost_usd),
    iw.avg_idle_percentage AS AVG(iw.idle_percentage),
    iw.warehouse_count AS COUNT(DISTINCT iw.warehouse_name)
  )
  COMMENT = 'Idle warehouse detection and waste analysis';

-- 2. Auto-suspend recommendation semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_AUTO_SUSPEND_RECOMMENDATIONS
  TABLES (
    aso AS <APP_DB>.<APP_SCHEMA>.V_AUTO_SUSPEND_OPPORTUNITIES
  )
  FACTS (
    aso.suspend_event_count AS aso.suspend_event_count,
    aso.avg_idle_minutes AS aso.avg_idle_minutes,
    aso.min_idle_minutes AS aso.min_idle_minutes,
    aso.max_idle_minutes AS aso.max_idle_minutes,
    aso.median_idle_minutes AS aso.median_idle_minutes
  )
  DIMENSIONS (
    aso.warehouse_name AS aso.warehouse_name,
    aso.recommendation AS aso.recommendation
  )
  METRICS (
    aso.total_suspend_events AS SUM(aso.suspend_event_count),
    aso.avg_median_idle_min AS AVG(aso.median_idle_minutes),
    aso.optimization_opportunities AS COUNT(*)
  )
  COMMENT = 'Auto-suspend configuration recommendations based on idle patterns';

-- 3. Overprovisioned warehouse semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_OVERPROVISIONED_WAREHOUSES
  TABLES (
    ow AS <APP_DB>.<APP_SCHEMA>.V_OVERPROVISIONED_WAREHOUSES
  )
  FACTS (
    ow.avg_daily_queries AS ow.avg_daily_queries,
    ow.avg_load_percent AS ow.avg_load_percent,
    ow.avg_p95_load_percent AS ow.avg_p95_load_percent,
    ow.avg_queue_sec AS ow.avg_queue_sec,
    ow.current_credits_per_hour AS ow.current_credits_per_hour
  )
  DIMENSIONS (
    ow.warehouse_name AS ow.warehouse_name,
    ow.warehouse_size AS ow.warehouse_size,
    ow.sizing_recommendation AS ow.sizing_recommendation
  )
  METRICS (
    ow.total_warehouses AS COUNT(*),
    ow.avg_load AS AVG(ow.avg_load_percent),
    ow.avg_p95_load AS AVG(ow.avg_p95_load_percent),
    ow.downsize_candidates AS SUM(CASE WHEN ow.sizing_recommendation LIKE '%downsize%' THEN 1 ELSE 0 END),
    ow.upsize_candidates AS SUM(CASE WHEN ow.sizing_recommendation LIKE '%upsize%' THEN 1 ELSE 0 END)
  )
  COMMENT = 'Warehouse sizing analysis and rightsizing recommendations';

-- 4. Query optimization semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_QUERY_OPTIMIZATION_OPPORTUNITIES
  TABLES (
    qo AS <APP_DB>.<APP_SCHEMA>.V_QUERY_OPTIMIZATION_OPPORTUNITIES
  )
  FACTS (
    qo.execution_sec AS qo.execution_sec,
    qo.tb_scanned AS qo.tb_scanned,
    qo.gb_spilled AS qo.gb_spilled,
    qo.percentage_scanned_from_cache AS qo.cache_hit_percent,
    qo.compilation_sec AS qo.compilation_sec,
    qo.credits_attributed_compute AS qo.credits_used
  )
  DIMENSIONS (
    qo.query_id AS qo.query_id,
    qo.query_preview AS qo.query_preview,
    qo.user_name AS qo.user_name,
    qo.warehouse_name AS qo.warehouse_name,
    qo.warehouse_size AS qo.warehouse_size,
    qo.start_time AS qo.start_time,
    qo.optimization_hint AS qo.optimization_hint,
    qo.priority AS qo.priority
  )
  METRICS (
    qo.total_queries AS COUNT(*),
    qo.total_credits AS SUM(qo.credits_used),
    qo.avg_execution_sec AS AVG(qo.execution_sec),
    qo.critical_priority_count AS SUM(CASE WHEN qo.priority = 'Critical' THEN 1 ELSE 0 END),
    qo.high_priority_count AS SUM(CASE WHEN qo.priority = 'High' THEN 1 ELSE 0 END)
  )
  COMMENT = 'Query-level optimization opportunities with actionable hints';

-- 5. Cost savings summary semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_COST_SAVINGS_SUMMARY
  TABLES (
    css AS <APP_DB>.<APP_SCHEMA>.V_COST_SAVINGS_SUMMARY
  )
  FACTS (
    css.current_7d_credits AS css.current_7d_credits,
    css.idle_credits_7d AS css.idle_credits_7d,
    css.avg_idle_percentage AS css.avg_idle_percentage,
    css.potential_monthly_savings_credits AS css.potential_monthly_savings_credits,
    css.savings_percentage AS css.savings_percentage,
    css.potential_monthly_savings_usd AS css.potential_monthly_savings_credits * <CREDIT_RATE_USD>
  )
  METRICS (
    css.total_potential_savings_credits AS SUM(css.potential_monthly_savings_credits),
    css.total_potential_savings_usd AS SUM(css.potential_monthly_savings_usd),
    css.avg_savings_percentage AS AVG(css.savings_percentage)
  )
  COMMENT = 'High-level cost savings summary and potential optimization impact';

-- 6. Warehouse utilization trends semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_WAREHOUSE_UTILIZATION_TRENDS
  TABLES (
    wut AS <APP_DB>.<APP_SCHEMA>.V_WAREHOUSE_UTILIZATION_TRENDS
  )
  FACTS (
    wut.query_count AS wut.query_count,
    wut.total_execution_sec AS wut.total_execution_sec,
    wut.avg_load_percent AS wut.avg_load_percent,
    wut.credits_used AS wut.credits_used,
    wut.avg_query_duration_sec AS wut.avg_query_duration_sec,
    wut.queued_queries AS wut.queued_queries,
    wut.avg_queue_sec AS wut.avg_queue_sec
  )
  DIMENSIONS (
    wut.warehouse_name AS wut.warehouse_name,
    wut.usage_date AS wut.usage_date
  )
  METRICS (
    wut.total_queries AS SUM(wut.query_count),
    wut.total_credits AS SUM(wut.credits_used),
    wut.avg_utilization AS AVG(wut.avg_load_percent),
    wut.total_queued AS SUM(wut.queued_queries),
    wut.avg_queue_time AS AVG(wut.avg_queue_sec)
  )
  COMMENT = 'Historical warehouse utilization trends for capacity planning';
