-- ============================================================
-- Generic Admin: Base Views
-- Replace <APP_DB> and <APP_SCHEMA> before execution.
-- ============================================================

-- 1. Warehouse metering + optional warehouse tag attribution
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_WAREHOUSE_COST_BY_TAG AS
SELECT
    wmh.warehouse_name,
    wmh.warehouse_id,
    wmh.start_time,
    DATE_TRUNC('DAY', wmh.start_time) AS usage_date,
    DATE_TRUNC('MONTH', wmh.start_time) AS usage_month,
    wmh.credits_used_compute,
    wmh.credits_used_cloud_services,
    wmh.credits_used,
    tr.tag_name,
    tr.tag_value
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY wmh
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES tr
    ON wmh.warehouse_id = tr.object_id
    AND tr.domain = 'WAREHOUSE';

-- 2. Query performance
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_QUERY_PERFORMANCE AS
SELECT
    warehouse_name,
    warehouse_size,
    user_name,
    query_tag,
    error_code,
    error_message,
    start_time,
    DATE_TRUNC('DAY', start_time) AS query_date,
    DATE_TRUNC('MONTH', start_time) AS query_month,
    execution_time / 1000 AS execution_time_sec,
    total_elapsed_time / 1000 AS total_elapsed_time_sec,
    queued_overload_time / 1000 AS queued_overload_time_sec,
    compilation_time / 1000 AS compilation_time_sec,
    bytes_scanned / POWER(1024, 4) AS tb_scanned,
    bytes_spilled_to_remote_storage / POWER(1024, 3) AS gb_spilled_remote,
    percentage_scanned_from_cache,
    query_load_percent
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE execution_time > 0;

-- 3. User spend attribution
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_USER_SPEND AS
SELECT
    user_name,
    warehouse_name,
    query_tag,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    credits_attributed_compute,
    credits_used_query_acceleration,
    credits_attributed_compute + COALESCE(credits_used_query_acceleration, 0) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY;

-- 4. Unified serverless costs
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_SERVERLESS_COSTS AS
SELECT
    'TASK' AS service_type,
    task_name AS object_name,
    database_name,
    schema_name,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.SERVERLESS_TASK_HISTORY
UNION ALL
SELECT
    'PIPE' AS service_type,
    pipe_name AS object_name,
    NULL AS database_name,
    NULL AS schema_name,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
UNION ALL
SELECT
    'AUTO_CLUSTERING' AS service_type,
    table_name AS object_name,
    database_name,
    schema_name,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.AUTOMATIC_CLUSTERING_HISTORY
UNION ALL
SELECT
    'SEARCH_OPTIMIZATION' AS service_type,
    table_name AS object_name,
    database_name,
    schema_name,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.SEARCH_OPTIMIZATION_HISTORY;

-- 5. Materialized view refresh costs
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_MV_REFRESH_COSTS AS
SELECT
    database_name,
    schema_name,
    table_name,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.MATERIALIZED_VIEW_REFRESH_HISTORY;

-- 6. Warehouse operations
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_WAREHOUSE_EVENTS AS
SELECT
    warehouse_name,
    timestamp AS event_time,
    DATE_TRUNC('DAY', timestamp) AS event_date,
    DATE_TRUNC('MONTH', timestamp) AS event_month,
    event_name,
    event_reason,
    event_state,
    user_name
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_EVENTS_HISTORY;

-- 7. Session activity
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_SESSION_ACTIVITY AS
SELECT
    user_name,
    event_type AS login_event_type,
    is_success AS login_success,
    error_code AS login_error_code,
    error_message AS login_error_message,
    client_ip,
    reported_client_type,
    reported_client_version,
    first_authentication_factor,
    event_timestamp AS login_time,
    DATE_TRUNC('DAY', event_timestamp) AS login_date,
    DATE_TRUNC('MONTH', event_timestamp) AS login_month
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY;

-- 8. Data transfer
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_DATA_TRANSFER_COSTS AS
SELECT
    source_cloud,
    source_region,
    target_cloud,
    target_region,
    transfer_type,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    bytes_transferred,
    bytes_transferred / POWER(1024, 3) AS gb_transferred
FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_TRANSFER_HISTORY;

-- 9. Replication
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_REPLICATION_COSTS AS
SELECT
    database_name,
    start_time,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    DATE_TRUNC('MONTH', start_time) AS usage_month,
    credits_used,
    bytes_transferred,
    bytes_transferred / POWER(1024, 3) AS gb_transferred
FROM SNOWFLAKE.ACCOUNT_USAGE.REPLICATION_USAGE_HISTORY;

-- 10. Storage metrics
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_STORAGE_TABLE_METRICS AS
SELECT
    table_catalog AS database_name,
    table_schema,
    table_name,
    active_bytes,
    time_travel_bytes,
    failsafe_bytes,
    retained_for_clone_bytes,
    active_bytes / POWER(1024, 4) AS active_tb,
    (time_travel_bytes + failsafe_bytes + retained_for_clone_bytes) / POWER(1024, 4) AS inactive_tb
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS;

-- 11. Rate sheet pricing (may require org-level access)
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_RATE_SHEET_PRICING AS
SELECT
    "DATE" AS rate_date,
    ACCOUNT_NAME,
    REGION,
    SERVICE_TYPE,
    USAGE_TYPE,
    BILLING_TYPE,
    CURRENCY,
    EFFECTIVE_RATE,
    IS_ADJUSTMENT
FROM SNOWFLAKE.ORGANIZATION_USAGE.RATE_SHEET_DAILY
WHERE ACCOUNT_NAME = CURRENT_ACCOUNT_NAME()
  AND REGION = CURRENT_REGION();
