-- ============================================================
-- Generic Admin: Semantic Views
-- Replace <APP_DB>, <APP_SCHEMA>, and <CREDIT_RATE_USD>.
-- ============================================================

-- 1. Warehouse compute and performance
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_WAREHOUSE_COST_ANALYSIS
  TABLES (
    wc AS <APP_DB>.<APP_SCHEMA>.V_WAREHOUSE_COST_BY_TAG,
    qp AS <APP_DB>.<APP_SCHEMA>.V_QUERY_PERFORMANCE
  )
  FACTS (
    wc.credits_used_compute AS wc.credits_used_compute,
    wc.credits_used_cloud_services AS wc.credits_used_cloud_services,
    wc.credits_used AS wc.credits_used,
    wc.cost_usd AS wc.credits_used * <CREDIT_RATE_USD>,
    qp.execution_time_sec AS qp.execution_time_sec,
    qp.tb_scanned AS qp.tb_scanned
  )
  DIMENSIONS (
    wc.warehouse_name AS wc.warehouse_name,
    wc.usage_date AS wc.usage_date,
    wc.usage_month AS wc.usage_month,
    wc.tag_name AS wc.tag_name,
    wc.tag_value AS wc.tag_value,
    qp.user_name AS qp.user_name,
    qp.query_tag AS qp.query_tag,
    qp.error_code AS qp.error_code,
    qp.error_message AS qp.error_message,
    qp.query_date AS qp.query_date
  )
  METRICS (
    wc.total_credits AS SUM(wc.credits_used),
    wc.total_cost_usd AS SUM(wc.cost_usd),
    qp.query_count AS COUNT(*),
    qp.avg_execution_sec AS AVG(qp.execution_time_sec),
    qp.total_tb_scanned AS SUM(qp.tb_scanned)
  )
  COMMENT = 'Generic warehouse compute and query performance semantic view';

-- 2. Storage analysis
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_STORAGE_COST_ANALYSIS
  TABLES (
    st AS <APP_DB>.<APP_SCHEMA>.V_STORAGE_TABLE_METRICS
  )
  FACTS (
    st.active_tb AS st.active_tb,
    st.inactive_tb AS st.inactive_tb
  )
  DIMENSIONS (
    st.database_name AS st.database_name,
    st.table_schema AS st.table_schema,
    st.table_name AS st.table_name
  )
  METRICS (
    st.total_active_tb AS SUM(st.active_tb),
    st.total_inactive_tb AS SUM(st.inactive_tb)
  )
  COMMENT = 'Generic storage and inactive storage semantic view';

-- 3. Serverless analysis
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_SERVERLESS_COSTS
  TABLES (
    sc AS <APP_DB>.<APP_SCHEMA>.V_SERVERLESS_COSTS,
    mv AS <APP_DB>.<APP_SCHEMA>.V_MV_REFRESH_COSTS
  )
  FACTS (
    sc.credits_used AS sc.credits_used,
    sc.cost_usd AS sc.credits_used * <CREDIT_RATE_USD>,
    mv.mv_credits_used AS mv.credits_used,
    mv.mv_cost_usd AS mv.credits_used * <CREDIT_RATE_USD>
  )
  DIMENSIONS (
    sc.service_type AS sc.service_type,
    sc.object_name AS sc.object_name,
    sc.usage_date AS sc.usage_date,
    mv.table_name AS mv.table_name,
    mv.usage_date AS mv.usage_date
  )
  METRICS (
    sc.total_serverless_credits AS SUM(sc.credits_used),
    sc.total_serverless_cost_usd AS SUM(sc.cost_usd),
    mv.total_mv_credits AS SUM(mv.mv_credits_used)
  )
  COMMENT = 'Generic serverless and materialized view refresh semantic view';

-- 4. User spend analysis
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_USER_SPEND
  TABLES (
    us AS <APP_DB>.<APP_SCHEMA>.V_USER_SPEND
  )
  FACTS (
    us.total_credits AS us.total_credits,
    us.cost_usd AS us.total_credits * <CREDIT_RATE_USD>
  )
  DIMENSIONS (
    us.user_name AS us.user_name,
    us.warehouse_name AS us.warehouse_name,
    us.query_tag AS us.query_tag,
    us.usage_date AS us.usage_date
  )
  METRICS (
    us.total_user_credits AS SUM(us.total_credits),
    us.total_user_cost_usd AS SUM(us.cost_usd),
    us.query_count AS COUNT(*)
  )
  COMMENT = 'Generic user-level spend attribution semantic view';

-- 5. Warehouse operations
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_WAREHOUSE_OPERATIONS
  TABLES (
    ev AS <APP_DB>.<APP_SCHEMA>.V_WAREHOUSE_EVENTS
  )
  DIMENSIONS (
    ev.warehouse_name AS ev.warehouse_name,
    ev.event_name AS ev.event_name,
    ev.event_reason AS ev.event_reason,
    ev.event_date AS ev.event_date,
    ev.user_name AS ev.user_name
  )
  METRICS (
    ev.event_count AS COUNT(*),
    ev.suspend_count AS SUM(CASE WHEN ev.event_name = 'SUSPEND_WAREHOUSE' THEN 1 ELSE 0 END),
    ev.resume_count AS SUM(CASE WHEN ev.event_name = 'RESUME_WAREHOUSE' THEN 1 ELSE 0 END)
  )
  COMMENT = 'Generic warehouse lifecycle event semantic view';

-- 6. Session activity
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_SESSION_ACTIVITY
  TABLES (
    sa AS <APP_DB>.<APP_SCHEMA>.V_SESSION_ACTIVITY
  )
  DIMENSIONS (
    sa.user_name AS sa.user_name,
    sa.login_success AS sa.login_success,
    sa.login_error_code AS sa.login_error_code,
    sa.reported_client_type AS sa.reported_client_type,
    sa.login_date AS sa.login_date
  )
  METRICS (
    sa.total_logins AS COUNT(*),
    sa.failed_logins AS SUM(CASE WHEN sa.login_success = 'NO' THEN 1 ELSE 0 END),
    sa.distinct_users AS COUNT(DISTINCT sa.user_name)
  )
  COMMENT = 'Generic login/session semantic view';

-- 7. Data transfer and replication
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_DATA_TRANSFER_REPLICATION
  TABLES (
    dt AS <APP_DB>.<APP_SCHEMA>.V_DATA_TRANSFER_COSTS,
    rp AS <APP_DB>.<APP_SCHEMA>.V_REPLICATION_COSTS
  )
  FACTS (
    dt.gb_transferred AS dt.gb_transferred,
    rp.credits_used AS rp.credits_used,
    rp.gb_transferred AS rp.gb_transferred
  )
  DIMENSIONS (
    dt.source_region AS dt.source_region,
    dt.target_region AS dt.target_region,
    dt.transfer_type AS dt.transfer_type,
    dt.usage_date AS dt.usage_date,
    rp.database_name AS rp.database_name,
    rp.usage_date AS rp.usage_date
  )
  METRICS (
    dt.total_transfer_gb AS SUM(dt.gb_transferred),
    rp.total_replication_credits AS SUM(rp.credits_used),
    rp.total_replication_gb AS SUM(rp.gb_transferred)
  )
  COMMENT = 'Generic data transfer and replication semantic view';

-- 8. Rate sheet pricing
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_RATE_SHEET_PRICING
  TABLES (
    rs AS <APP_DB>.<APP_SCHEMA>.V_RATE_SHEET_PRICING
  )
  FACTS (
    rs.effective_rate AS rs.EFFECTIVE_RATE
  )
  DIMENSIONS (
    rs.rate_date AS rs.rate_date,
    rs.service_type AS rs.SERVICE_TYPE,
    rs.usage_type AS rs.USAGE_TYPE,
    rs.billing_type AS rs.BILLING_TYPE,
    rs.currency AS rs.CURRENCY
  )
  METRICS (
    rs.current_rate AS MAX(rs.effective_rate),
    rs.avg_rate AS AVG(rs.effective_rate)
  )
  COMMENT = 'Generic rate sheet semantic view';
