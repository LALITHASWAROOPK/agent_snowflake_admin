-- ============================================================
-- Generic Admin: Optional Budget Controls
-- Replace placeholders before execution.
-- ============================================================

-- 1. Tag used for budget scoping
CREATE TAG IF NOT EXISTS <APP_DB>.<APP_SCHEMA>.AGENT_BUDGET_TAG
  COMMENT = 'Tag used to scope Admin agent budget resources';

-- 2. Apply tag to agent
ALTER AGENT IF EXISTS <APP_DB>.<APP_SCHEMA>.<AGENT_NAME>
  SET TAG <APP_DB>.<APP_SCHEMA>.AGENT_BUDGET_TAG = 'admin-agent';

-- 3. Budget object
CREATE SNOWFLAKE.CORE.BUDGET IF NOT EXISTS <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>();

-- 4. Set budget limit in credits/month
CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!SET_SPENDING_LIMIT(<MONTHLY_CREDIT_LIMIT>);

-- 5. Link tagged resources to budget
CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!SET_RESOURCE_TAGS(
  [
    [
      (SELECT SYSTEM$REFERENCE('TAG', '<APP_DB>.<APP_SCHEMA>.AGENT_BUDGET_TAG', 'SESSION', 'applybudget')),
      'admin-agent'
    ]
  ],
  'UNION'
);

-- 6. Alert threshold
CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!SET_NOTIFICATION_THRESHOLD(80);

-- 7. Optional revoke procedure at 100%
CREATE OR REPLACE PROCEDURE <APP_DB>.<APP_SCHEMA>.SP_REVOKE_AGENT_ACCESS()
RETURNS STRING
LANGUAGE SQL
AS
BEGIN
  REVOKE USAGE ON AGENT <APP_DB>.<APP_SCHEMA>.<AGENT_NAME> FROM ROLE "<DEVELOPER_ROLE>";
  RETURN 'Agent access revoked because budget threshold was exceeded.';
END;

CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!ADD_CUSTOM_ACTION(
  SYSTEM$REFERENCE('PROCEDURE', '<APP_DB>.<APP_SCHEMA>.SP_REVOKE_AGENT_ACCESS()'),
  ARRAY_CONSTRUCT(),
  'ACTUAL',
  100
);
