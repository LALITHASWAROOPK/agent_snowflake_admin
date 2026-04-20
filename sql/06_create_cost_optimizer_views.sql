-- ============================================================
-- Cost Optimizer Agent: Base Views
-- Replace <APP_DB> and <APP_SCHEMA> before execution.
-- ============================================================

-- 1. Idle warehouse detection
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_IDLE_WAREHOUSES AS
WITH warehouse_activity AS (
    SELECT
        warehouse_name,
        DATE_TRUNC('DAY', start_time) AS activity_date,
        COUNT(*) AS query_count,
        SUM(execution_time) / 1000 AS total_execution_sec,
        SUM(credits_attributed_compute) AS credits_used
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
    WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
    GROUP BY 1, 2
),
warehouse_uptime AS (
    SELECT
        warehouse_name,
        DATE_TRUNC('DAY', start_time) AS uptime_date,
        SUM(credits_used) AS total_credits
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
    GROUP BY 1, 2
)
SELECT
    u.warehouse_name,
    u.uptime_date,
    u.total_credits,
    COALESCE(a.query_count, 0) AS query_count,
    COALESCE(a.total_execution_sec, 0) AS active_execution_sec,
    COALESCE(a.credits_used, 0) AS productive_credits,
    u.total_credits - COALESCE(a.credits_used, 0) AS idle_credits,
    CASE 
        WHEN u.total_credits > 0 
        THEN ((u.total_credits - COALESCE(a.credits_used, 0)) / u.total_credits * 100)
        ELSE 0 
    END AS idle_percentage
FROM warehouse_uptime u
LEFT JOIN warehouse_activity a 
    ON u.warehouse_name = a.warehouse_name 
    AND u.uptime_date = a.activity_date
WHERE u.total_credits > 0.01;

-- 2. Auto-suspend opportunities
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_AUTO_SUSPEND_OPPORTUNITIES AS
WITH warehouse_events AS (
    SELECT
        warehouse_name,
        event_name,
        event_state,
        timestamp,
        user_name,
        LAG(timestamp) OVER (PARTITION BY warehouse_name ORDER BY timestamp) AS prev_timestamp,
        LAG(event_name) OVER (PARTITION BY warehouse_name ORDER BY timestamp) AS prev_event
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_EVENTS_HISTORY
    WHERE timestamp >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
),
idle_periods AS (
    SELECT
        warehouse_name,
        timestamp AS suspend_time,
        prev_timestamp AS resume_time,
        DATEDIFF('SECOND', prev_timestamp, timestamp) AS idle_seconds,
        DATEDIFF('MINUTE', prev_timestamp, timestamp) AS idle_minutes
    FROM warehouse_events
    WHERE event_name = 'SUSPEND_WAREHOUSE'
        AND prev_event = 'RESUME_WAREHOUSE'
        AND prev_timestamp IS NOT NULL
)
SELECT
    warehouse_name,
    COUNT(*) AS suspend_event_count,
    AVG(idle_minutes) AS avg_idle_minutes,
    MIN(idle_minutes) AS min_idle_minutes,
    MAX(idle_minutes) AS max_idle_minutes,
    MEDIAN(idle_minutes) AS median_idle_minutes,
    CASE
        WHEN MEDIAN(idle_minutes) < 5 THEN 'Set auto_suspend = 1 minute'
        WHEN MEDIAN(idle_minutes) < 10 THEN 'Set auto_suspend = 5 minutes'
        WHEN MEDIAN(idle_minutes) < 30 THEN 'Set auto_suspend = 10 minutes'
        ELSE 'Current auto_suspend likely sufficient'
    END AS recommendation
FROM idle_periods
GROUP BY warehouse_name
HAVING COUNT(*) >= 3;

-- 3. Overprovisioned warehouse analysis
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_OVERPROVISIONED_WAREHOUSES AS
WITH query_stats AS (
    SELECT
        warehouse_name,
        warehouse_size,
        DATE_TRUNC('DAY', start_time) AS query_date,
        COUNT(*) AS query_count,
        AVG(queued_overload_time) / 1000 AS avg_queue_sec,
        AVG(execution_time) / 1000 AS avg_execution_sec,
        AVG(query_load_percent) AS avg_load_percent,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY query_load_percent) AS p95_load_percent
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND execution_time > 0
        AND warehouse_name IS NOT NULL
    GROUP BY 1, 2, 3
)
SELECT
    warehouse_name,
    warehouse_size,
    AVG(query_count) AS avg_daily_queries,
    AVG(avg_load_percent) AS avg_load_percent,
    AVG(p95_load_percent) AS avg_p95_load_percent,
    AVG(avg_queue_sec) AS avg_queue_sec,
    CASE
        WHEN AVG(p95_load_percent) < 30 AND AVG(avg_queue_sec) < 1 
            THEN 'Consider downsizing by 1-2 sizes'
        WHEN AVG(p95_load_percent) < 50 AND AVG(avg_queue_sec) < 2 
            THEN 'Consider downsizing by 1 size'
        WHEN AVG(p95_load_percent) > 80 OR AVG(avg_queue_sec) > 10 
            THEN 'Consider upsizing'
        ELSE 'Size appears appropriate'
    END AS sizing_recommendation,
    CASE
        WHEN warehouse_size = 'X-Small' THEN 1
        WHEN warehouse_size = 'Small' THEN 2
        WHEN warehouse_size = 'Medium' THEN 4
        WHEN warehouse_size = 'Large' THEN 8
        WHEN warehouse_size = 'X-Large' THEN 16
        WHEN warehouse_size = '2X-Large' THEN 32
        WHEN warehouse_size = '3X-Large' THEN 64
        WHEN warehouse_size = '4X-Large' THEN 128
        ELSE 0
    END AS current_credits_per_hour
FROM query_stats
GROUP BY warehouse_name, warehouse_size
HAVING AVG(query_count) > 10;

-- 4. Query optimization opportunities
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_QUERY_OPTIMIZATION_OPPORTUNITIES AS
WITH expensive_queries AS (
    SELECT
        query_id,
        query_text,
        user_name,
        warehouse_name,
        warehouse_size,
        start_time,
        execution_time / 1000 AS execution_sec,
        total_elapsed_time / 1000 AS elapsed_sec,
        bytes_scanned / POWER(1024, 4) AS tb_scanned,
        bytes_spilled_to_remote_storage / POWER(1024, 3) AS gb_spilled,
        percentage_scanned_from_cache,
        partitions_scanned,
        partitions_total,
        compilation_time / 1000 AS compilation_sec,
        credits_attributed_compute
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND execution_time > 60000  -- longer than 60 seconds
        AND error_code IS NULL
)
SELECT
    query_id,
    LEFT(query_text, 200) AS query_preview,
    user_name,
    warehouse_name,
    warehouse_size,
    start_time,
    execution_sec,
    tb_scanned,
    gb_spilled,
    percentage_scanned_from_cache,
    compilation_sec,
    credits_attributed_compute,
    CASE
        WHEN gb_spilled > 0 THEN 'High spilling detected - consider clustering or larger warehouse'
        WHEN percentage_scanned_from_cache < 20 AND tb_scanned > 1 THEN 'Low cache hit - consider result caching or clustering'
        WHEN compilation_sec > execution_sec * 0.3 THEN 'High compilation time - query may benefit from parameterization'
        WHEN partitions_scanned IS NOT NULL AND partitions_total IS NOT NULL 
            AND partitions_scanned > partitions_total * 0.5 
            THEN 'Scanning many partitions - add filters or review clustering'
        ELSE 'Review query for optimization potential'
    END AS optimization_hint,
    CASE
        WHEN gb_spilled > 10 THEN 'Critical'
        WHEN gb_spilled > 1 OR percentage_scanned_from_cache < 10 THEN 'High'
        WHEN execution_sec > 300 THEN 'Medium'
        ELSE 'Low'
    END AS priority
FROM expensive_queries
ORDER BY credits_attributed_compute DESC
LIMIT 100;

-- 5. Cost savings summary
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_COST_SAVINGS_SUMMARY AS
WITH idle_waste AS (
    SELECT
        SUM(idle_credits) AS total_idle_credits,
        AVG(idle_percentage) AS avg_idle_percentage
    FROM <APP_DB>.<APP_SCHEMA>.V_IDLE_WAREHOUSES
),
current_spend AS (
    SELECT
        SUM(credits_used) AS total_credits_7d
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
)
SELECT
    c.total_credits_7d AS current_7d_credits,
    i.total_idle_credits AS idle_credits_7d,
    i.avg_idle_percentage AS avg_idle_percentage,
    i.total_idle_credits AS potential_monthly_savings_credits,
    (i.total_idle_credits / NULLIF(c.total_credits_7d, 0)) * 100 AS savings_percentage
FROM current_spend c
CROSS JOIN idle_waste i;

-- 6. Warehouse utilization trends
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_WAREHOUSE_UTILIZATION_TRENDS AS
SELECT
    warehouse_name,
    DATE_TRUNC('DAY', start_time) AS usage_date,
    COUNT(DISTINCT query_id) AS query_count,
    SUM(execution_time) / 1000 AS total_execution_sec,
    AVG(query_load_percent) AS avg_load_percent,
    SUM(credits_attributed_compute) AS credits_used,
    AVG(execution_time) / 1000 AS avg_query_duration_sec,
    SUM(CASE WHEN queued_overload_time > 0 THEN 1 ELSE 0 END) AS queued_queries,
    AVG(CASE WHEN queued_overload_time > 0 THEN queued_overload_time / 1000 ELSE 0 END) AS avg_queue_sec
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
    AND warehouse_name IS NOT NULL
    AND execution_time > 0
GROUP BY warehouse_name, DATE_TRUNC('DAY', start_time)
ORDER BY warehouse_name, usage_date DESC;
