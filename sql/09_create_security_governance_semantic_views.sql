-- ============================================================
-- Security & Governance Agent: Semantic Views
-- Replace <APP_DB> and <APP_SCHEMA> before execution.
-- ============================================================

-- 1. Role hierarchy semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_ROLE_HIERARCHY
  TABLES (
    rh AS <APP_DB>.<APP_SCHEMA>.V_ROLE_HIERARCHY
  )
  DIMENSIONS (
    rh.parent_role AS rh.parent_role,
    rh.granted_role AS rh.granted_role,
    rh.granted_by AS rh.granted_by,
    rh.created_on AS rh.created_on
  )
  METRICS (
    rh.total_role_grants AS COUNT(*),
    rh.distinct_parent_roles AS COUNT(DISTINCT rh.parent_role),
    rh.distinct_granted_roles AS COUNT(DISTINCT rh.granted_role)
  )
  COMMENT = 'Role hierarchy and inheritance structure';

-- 2. Privilege grants semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_PRIVILEGE_GRANTS
  TABLES (
    pg AS <APP_DB>.<APP_SCHEMA>.V_PRIVILEGE_GRANTS
  )
  DIMENSIONS (
    pg.role_name AS pg.role_name,
    pg.privilege AS pg.privilege,
    pg.object_type AS pg.object_type,
    pg.object_name AS pg.object_name,
    pg.database_name AS pg.database_name,
    pg.schema_name AS pg.schema_name,
    pg.granted_by AS pg.granted_by,
    pg.created_on AS pg.created_on
  )
  METRICS (
    pg.total_grants AS COUNT(*),
    pg.distinct_roles AS COUNT(DISTINCT pg.role_name),
    pg.distinct_objects AS COUNT(DISTINCT pg.object_name)
  )
  COMMENT = 'Comprehensive privilege grant tracking';

-- 3. Failed login attempts semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_FAILED_LOGIN_ATTEMPTS
  TABLES (
    fla AS <APP_DB>.<APP_SCHEMA>.V_FAILED_LOGIN_ATTEMPTS
  )
  FACTS (
    fla.event_timestamp AS fla.event_timestamp
  )
  DIMENSIONS (
    fla.user_name AS fla.user_name,
    fla.client_ip AS fla.client_ip,
    fla.reported_client_type AS fla.client_type,
    fla.error_code AS fla.error_code,
    fla.error_message AS fla.error_message,
    fla.event_date AS fla.event_date,
    fla.event_hour AS fla.event_hour,
    fla.first_authentication_factor AS fla.first_auth_factor,
    fla.second_authentication_factor AS fla.second_auth_factor
  )
  METRICS (
    fla.total_failed_logins AS COUNT(*),
    fla.distinct_users AS COUNT(DISTINCT fla.user_name),
    fla.distinct_ips AS COUNT(DISTINCT fla.client_ip),
    fla.distinct_error_codes AS COUNT(DISTINCT fla.error_code)
  )
  COMMENT = 'Failed login attempt tracking and analysis';

-- 4. Login anomaly detection semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_LOGIN_ANOMALIES
  TABLES (
    la AS <APP_DB>.<APP_SCHEMA>.V_LOGIN_ANOMALIES
  )
  FACTS (
    la.failed_attempts AS la.failed_attempts,
    la.distinct_ips AS la.distinct_ips
  )
  DIMENSIONS (
    la.user_name AS la.user_name,
    la.event_hour AS la.event_hour,
    la.error_codes AS la.error_codes,
    la.anomaly_severity AS la.anomaly_severity,
    la.recommendation AS la.recommendation
  )
  METRICS (
    la.total_anomalies AS COUNT(*),
    la.critical_anomalies AS SUM(CASE WHEN la.anomaly_severity LIKE 'Critical%' THEN 1 ELSE 0 END),
    la.high_anomalies AS SUM(CASE WHEN la.anomaly_severity LIKE 'High%' THEN 1 ELSE 0 END),
    la.total_failed_attempts AS SUM(la.failed_attempts),
    la.affected_users AS COUNT(DISTINCT la.user_name)
  )
  COMMENT = 'Login anomaly detection with severity classification';

-- 5. Excessive privilege semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_EXCESSIVE_PRIVILEGES
  TABLES (
    ep AS <APP_DB>.<APP_SCHEMA>.V_EXCESSIVE_PRIVILEGES
  )
  FACTS (
    ep.usage_count_90d AS ep.usage_count_90d,
    ep.grant_date AS ep.grant_date,
    ep.last_used AS ep.last_used
  )
  DIMENSIONS (
    ep.user_or_role AS ep.user_or_role,
    ep.privilege_concern AS ep.privilege_concern,
    ep.risk_level AS ep.risk_level,
    ep.recommendation AS ep.recommendation
  )
  METRICS (
    ep.total_excessive_privileges AS COUNT(*),
    ep.critical_risks AS SUM(CASE WHEN ep.risk_level LIKE 'Critical%' THEN 1 ELSE 0 END),
    ep.high_risks AS SUM(CASE WHEN ep.risk_level LIKE 'High%' THEN 1 ELSE 0 END),
    ep.unused_privileges AS SUM(CASE WHEN ep.usage_count_90d = 0 THEN 1 ELSE 0 END),
    ep.affected_users AS COUNT(DISTINCT ep.user_or_role)
  )
  COMMENT = 'Excessive privilege detection and risk assessment';

-- 6. Data access patterns semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_DATA_ACCESS_PATTERNS
  TABLES (
    dap AS <APP_DB>.<APP_SCHEMA>.V_DATA_ACCESS_PATTERNS
  )
  FACTS (
    dap.total_accesses_30d AS dap.total_accesses,
    dap.total_reads AS dap.total_reads,
    dap.total_writes AS dap.total_writes,
    dap.days_accessed AS dap.days_accessed,
    dap.first_access AS dap.first_access,
    dap.last_access AS dap.last_access
  )
  DIMENSIONS (
    dap.user_name AS dap.user_name,
    dap.role_name AS dap.role_name,
    dap.full_table_name AS dap.table_name
  )
  METRICS (
    dap.total_access_events AS SUM(dap.total_accesses),
    dap.total_read_operations AS SUM(dap.total_reads),
    dap.total_write_operations AS SUM(dap.total_writes),
    dap.distinct_users AS COUNT(DISTINCT dap.user_name),
    dap.distinct_tables AS COUNT(DISTINCT dap.table_name),
    dap.avg_accesses_per_user AS AVG(dap.total_accesses)
  )
  COMMENT = 'Data access pattern tracking for governance';

-- 7. Unauthorized access attempts semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_UNAUTHORIZED_ACCESS_ATTEMPTS
  TABLES (
    uaa AS <APP_DB>.<APP_SCHEMA>.V_UNAUTHORIZED_ACCESS_ATTEMPTS
  )
  FACTS (
    uaa.start_time AS uaa.attempt_time
  )
  DIMENSIONS (
    uaa.user_name AS uaa.user_name,
    uaa.role_name AS uaa.role_name,
    uaa.query_type AS uaa.query_type,
    uaa.database_name AS uaa.database_name,
    uaa.schema_name AS uaa.schema_name,
    uaa.error_code AS uaa.error_code,
    uaa.error_message AS uaa.error_message,
    uaa.attempt_date AS uaa.attempt_date,
    uaa.execution_status AS uaa.execution_status
  )
  METRICS (
    uaa.total_unauthorized_attempts AS COUNT(*),
    uaa.distinct_users AS COUNT(DISTINCT uaa.user_name),
    uaa.distinct_roles AS COUNT(DISTINCT uaa.role_name),
    uaa.distinct_databases AS COUNT(DISTINCT uaa.database_name)
  )
  COMMENT = 'Unauthorized access attempt tracking and analysis';

-- 8. User and role audit semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_USER_ROLE_AUDIT
  TABLES (
    ura AS <APP_DB>.<APP_SCHEMA>.V_USER_ROLE_AUDIT
  )
  FACTS (
    ura.role_count AS ura.role_count,
    ura.active_days_30d AS ura.active_days_30d,
    ura.query_count_30d AS ura.query_count_30d,
    ura.login_count_30d AS ura.login_count_30d,
    ura.first_role_grant AS ura.first_role_grant,
    ura.last_query_time AS ura.last_query_time,
    ura.last_login_time AS ura.last_login_time
  )
  DIMENSIONS (
    ura.user_name AS ura.user_name,
    ura.assigned_roles AS ura.assigned_roles,
    ura.audit_flag AS ura.audit_flag
  )
  METRICS (
    ura.total_users AS COUNT(*),
    ura.inactive_users AS SUM(CASE WHEN ura.audit_flag = 'Inactive user with access' THEN 1 ELSE 0 END),
    ura.excessive_role_users AS SUM(CASE WHEN ura.audit_flag = 'User with excessive role assignments' THEN 1 ELSE 0 END),
    ura.avg_roles_per_user AS AVG(ura.role_count),
    ura.avg_activity_days AS AVG(ura.active_days_30d)
  )
  COMMENT = 'Comprehensive user and role audit with activity tracking';

-- 9. Network policy activity semantic view
CREATE OR REPLACE SEMANTIC VIEW <APP_DB>.<APP_SCHEMA>.SV_NETWORK_POLICY_ACTIVITY
  TABLES (
    npa AS <APP_DB>.<APP_SCHEMA>.V_NETWORK_POLICY_ACTIVITY
  )
  FACTS (
    npa.event_timestamp AS npa.event_timestamp
  )
  DIMENSIONS (
    npa.user_name AS npa.user_name,
    npa.client_ip AS npa.client_ip,
    npa.reported_client_type AS npa.client_type,
    npa.is_success AS npa.is_success,
    npa.error_code AS npa.error_code,
    npa.error_message AS npa.error_message,
    npa.event_date AS npa.event_date
  )
  METRICS (
    npa.total_violations AS COUNT(*),
    npa.distinct_users AS COUNT(DISTINCT npa.user_name),
    npa.distinct_ips AS COUNT(DISTINCT npa.client_ip),
    npa.successful_logins AS SUM(CASE WHEN npa.is_success = 'YES' THEN 1 ELSE 0 END),
    npa.failed_logins AS SUM(CASE WHEN npa.is_success = 'NO' THEN 1 ELSE 0 END)
  )
  COMMENT = 'Network policy violation and compliance tracking';
