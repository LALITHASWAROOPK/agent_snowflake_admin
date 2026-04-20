-- ============================================================
-- Security & Governance Agent Definition
-- Replace placeholders before execution.
-- ============================================================

CREATE OR REPLACE AGENT <APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>
  COMMENT = 'Security & Governance agent for access control and compliance'
  PROFILE = '{"display_name": "Security & Governance Agent"}'
  FROM SPECIFICATION
  $$
  instructions:
    response: "You are a Security & Governance assistant. Monitor role assignments, detect privilege anomalies, track failed logins, and identify unauthorized access attempts. Provide security recommendations and compliance insights."
    orchestration: "Route role hierarchy questions to RoleHierarchyAnalyst; privilege grants to PrivilegeGrantAnalyst; failed logins to FailedLoginAnalyst; login anomalies to LoginAnomalyDetector; excessive privileges to ExcessivePrivilegeAnalyst; data access patterns to DataAccessAnalyst; unauthorized access to UnauthorizedAccessAnalyst; user audits to UserAuditAnalyst; network policy to NetworkPolicyAnalyst."

  tools:
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "RoleHierarchyAnalyst", description: "Analyze role hierarchy and inheritance" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "PrivilegeGrantAnalyst", description: "Track privilege grants and assignments" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "FailedLoginAnalyst", description: "Monitor failed login attempts" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "LoginAnomalyDetector", description: "Detect login anomalies and potential attacks" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "ExcessivePrivilegeAnalyst", description: "Identify excessive or unused privileges" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "DataAccessAnalyst", description: "Analyze data access patterns" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "UnauthorizedAccessAnalyst", description: "Track unauthorized access attempts" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "UserAuditAnalyst", description: "Comprehensive user and role audit" }
    - tool_spec: { type: "cortex_analyst_text_to_sql", name: "NetworkPolicyAnalyst", description: "Monitor network policy violations" }

  tool_resources:
    RoleHierarchyAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_ROLE_HIERARCHY"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    PrivilegeGrantAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_PRIVILEGE_GRANTS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    FailedLoginAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_FAILED_LOGIN_ATTEMPTS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    LoginAnomalyDetector:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_LOGIN_ANOMALIES"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    ExcessivePrivilegeAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_EXCESSIVE_PRIVILEGES"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    DataAccessAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_DATA_ACCESS_PATTERNS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    UnauthorizedAccessAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_UNAUTHORIZED_ACCESS_ATTEMPTS"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    UserAuditAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_USER_ROLE_AUDIT"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    NetworkPolicyAnalyst:
      semantic_view: "<APP_DB>.<APP_SCHEMA>.SV_NETWORK_POLICY_ACTIVITY"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
  $$;
