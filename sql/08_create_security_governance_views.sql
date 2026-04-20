-- ============================================================
-- Security & Governance Agent: Base Views
-- Replace <APP_DB> and <APP_SCHEMA> before execution.
-- ============================================================

-- 1. Role hierarchy and grants
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_ROLE_HIERARCHY AS
SELECT
    granted_to_name AS parent_role,
    name AS granted_role,
    granted_by,
    created_on,
    deleted_on
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE privilege = 'USAGE'
    AND granted_on = 'ROLE'
    AND deleted_on IS NULL;

-- 2. Privilege grants summary
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_PRIVILEGE_GRANTS AS
SELECT
    grantee_name AS role_name,
    privilege,
    granted_on AS object_type,
    name AS object_name,
    table_catalog AS database_name,
    table_schema AS schema_name,
    granted_by,
    created_on,
    deleted_on
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
WHERE deleted_on IS NULL
    AND granted_on != 'ROLE';

-- 3. Failed login attempts
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_FAILED_LOGIN_ATTEMPTS AS
SELECT
    user_name,
    client_ip,
    reported_client_type,
    error_code,
    error_message,
    first_authentication_factor,
    second_authentication_factor,
    event_timestamp,
    DATE_TRUNC('DAY', event_timestamp) AS event_date,
    DATE_TRUNC('HOUR', event_timestamp) AS event_hour
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE is_success = 'NO'
    AND event_timestamp >= DATEADD(DAY, -30, CURRENT_TIMESTAMP());

-- 4. Failed login patterns (anomaly detection)
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_LOGIN_ANOMALIES AS
WITH failed_login_stats AS (
    SELECT
        user_name,
        DATE_TRUNC('HOUR', event_timestamp) AS event_hour,
        COUNT(*) AS failed_attempts,
        COUNT(DISTINCT client_ip) AS distinct_ips,
        LISTAGG(DISTINCT error_code, ', ') WITHIN GROUP (ORDER BY error_code) AS error_codes
    FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE is_success = 'NO'
        AND event_timestamp >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
    GROUP BY 1, 2
)
SELECT
    user_name,
    event_hour,
    failed_attempts,
    distinct_ips,
    error_codes,
    CASE
        WHEN failed_attempts >= 10 THEN 'Critical - Possible brute force attack'
        WHEN failed_attempts >= 5 THEN 'High - Multiple failed attempts'
        WHEN distinct_ips > 3 THEN 'Medium - Failed logins from multiple IPs'
        ELSE 'Low - Normal failed login pattern'
    END AS anomaly_severity,
    CASE
        WHEN failed_attempts >= 10 THEN 'Investigate account security and consider locking'
        WHEN failed_attempts >= 5 THEN 'Review authentication logs and notify user'
        WHEN distinct_ips > 3 THEN 'Monitor for credential sharing or compromise'
        ELSE 'Standard monitoring'
    END AS recommendation
FROM failed_login_stats
WHERE failed_attempts >= 3
ORDER BY failed_attempts DESC, event_hour DESC;

-- 5. Excessive privilege grants (ACCOUNTADMIN, SECURITYADMIN usage)
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_EXCESSIVE_PRIVILEGES AS
WITH sensitive_roles AS (
    SELECT DISTINCT
        grantee_name AS user_or_role,
        'Has ACCOUNTADMIN' AS privilege_concern,
        created_on AS grant_date
    FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS
    WHERE role = 'ACCOUNTADMIN'
        AND deleted_on IS NULL
    UNION ALL
    SELECT DISTINCT
        grantee_name AS user_or_role,
        'Has SECURITYADMIN' AS privilege_concern,
        created_on AS grant_date
    FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS
    WHERE role = 'SECURITYADMIN'
        AND deleted_on IS NULL
),
usage_stats AS (
    SELECT
        user_name,
        role_name,
        COUNT(*) AS query_count,
        MAX(start_time) AS last_used
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE role_name IN ('ACCOUNTADMIN', 'SECURITYADMIN')
        AND start_time >= DATEADD(DAY, -90, CURRENT_TIMESTAMP())
    GROUP BY 1, 2
)
SELECT
    sr.user_or_role,
    sr.privilege_concern,
    sr.grant_date,
    COALESCE(us.query_count, 0) AS usage_count_90d,
    us.last_used,
    CASE
        WHEN us.last_used IS NULL OR us.last_used < DATEADD(DAY, -60, CURRENT_TIMESTAMP())
            THEN 'Critical - Unused privileged role'
        WHEN COALESCE(us.query_count, 0) < 5
            THEN 'High - Rarely used privileged role'
        ELSE 'Medium - Active privileged role user'
    END AS risk_level,
    CASE
        WHEN us.last_used IS NULL OR us.last_used < DATEADD(DAY, -60, CURRENT_TIMESTAMP())
            THEN 'Consider revoking - no recent usage'
        WHEN COALESCE(us.query_count, 0) < 5
            THEN 'Review necessity of privilege assignment'
        ELSE 'Monitor usage patterns'
    END AS recommendation
FROM sensitive_roles sr
LEFT JOIN usage_stats us 
    ON sr.user_or_role = us.user_name 
    AND sr.privilege_concern LIKE '%' || us.role_name || '%'
ORDER BY risk_level, sr.user_or_role;

-- 6. Data access patterns
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_DATA_ACCESS_PATTERNS AS
WITH table_access AS (
    SELECT
        user_name,
        role_name,
        database_name,
        schema_name,
        table_name,
        DATE_TRUNC('DAY', start_time) AS access_date,
        COUNT(*) AS access_count,
        SUM(CASE WHEN query_type IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE') THEN 1 ELSE 0 END) AS write_count,
        SUM(CASE WHEN query_type = 'SELECT' THEN 1 ELSE 0 END) AS read_count
    FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
    LATERAL FLATTEN(input => base_objects_accessed) obj
    WHERE start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
        AND obj.value:objectName IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT
    user_name,
    role_name,
    CONCAT(database_name, '.', schema_name, '.', table_name) AS full_table_name,
    SUM(access_count) AS total_accesses_30d,
    SUM(read_count) AS total_reads,
    SUM(write_count) AS total_writes,
    COUNT(DISTINCT access_date) AS days_accessed,
    MIN(access_date) AS first_access,
    MAX(access_date) AS last_access
FROM table_access
GROUP BY 1, 2, 3
ORDER BY total_accesses_30d DESC;

-- 7. Unauthorized access attempts
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_UNAUTHORIZED_ACCESS_ATTEMPTS AS
SELECT
    user_name,
    role_name,
    query_type,
    database_name,
    schema_name,
    error_code,
    error_message,
    start_time,
    DATE_TRUNC('DAY', start_time) AS attempt_date,
    query_text,
    execution_status
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE error_code IN (
    '002003',  -- SQL access control error
    '002021',  -- Object does not exist or not authorized
    '091008',  -- Insufficient privileges
    '091015'   -- SQL access control error
)
    AND start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

-- 8. User and role audit summary
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_USER_ROLE_AUDIT AS
WITH user_roles AS (
    SELECT
        grantee_name AS user_name,
        role AS role_name,
        created_on AS grant_date,
        deleted_on
    FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS
    WHERE deleted_on IS NULL
),
user_activity AS (
    SELECT
        user_name,
        COUNT(DISTINCT DATE_TRUNC('DAY', start_time)) AS active_days_30d,
        MAX(start_time) AS last_query_time,
        COUNT(*) AS query_count_30d
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
    GROUP BY user_name
),
user_logins AS (
    SELECT
        user_name,
        MAX(event_timestamp) AS last_login_time,
        COUNT(*) AS login_count_30d
    FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE event_timestamp >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
        AND is_success = 'YES'
    GROUP BY user_name
)
SELECT
    ur.user_name,
    LISTAGG(DISTINCT ur.role_name, ', ') WITHIN GROUP (ORDER BY ur.role_name) AS assigned_roles,
    COUNT(DISTINCT ur.role_name) AS role_count,
    MIN(ur.grant_date) AS first_role_grant,
    COALESCE(ua.active_days_30d, 0) AS active_days_30d,
    ua.last_query_time,
    COALESCE(ua.query_count_30d, 0) AS query_count_30d,
    ul.last_login_time,
    COALESCE(ul.login_count_30d, 0) AS login_count_30d,
    CASE
        WHEN ua.last_query_time IS NULL OR ua.last_query_time < DATEADD(DAY, -30, CURRENT_TIMESTAMP())
            THEN 'Inactive user with access'
        WHEN COUNT(DISTINCT ur.role_name) > 5
            THEN 'User with excessive role assignments'
        ELSE 'Active user'
    END AS audit_flag
FROM user_roles ur
LEFT JOIN user_activity ua ON ur.user_name = ua.user_name
LEFT JOIN user_logins ul ON ur.user_name = ul.user_name
GROUP BY ur.user_name, ua.active_days_30d, ua.last_query_time, ua.query_count_30d, ul.last_login_time, ul.login_count_30d
ORDER BY audit_flag, ur.user_name;

-- 9. Network policy violations
CREATE OR REPLACE VIEW <APP_DB>.<APP_SCHEMA>.V_NETWORK_POLICY_ACTIVITY AS
SELECT
    user_name,
    client_ip,
    reported_client_type,
    is_success,
    error_code,
    error_message,
    event_timestamp,
    DATE_TRUNC('DAY', event_timestamp) AS event_date
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE error_message LIKE '%network policy%'
    OR error_code IN ('390144', '390145')  -- Network policy related errors
    AND event_timestamp >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
ORDER BY event_timestamp DESC;
