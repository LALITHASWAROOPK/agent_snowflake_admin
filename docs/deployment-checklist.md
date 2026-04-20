# Multi-Agent Deployment Checklist

Use this checklist to ensure proper deployment of the Snowflake Multi-Agent Admin Assistant.

## Pre-Deployment

### Prerequisites
- [ ] Snowflake account with ACCOUNTADMIN or equivalent privileges
- [ ] Access to `SNOWFLAKE.ACCOUNT_USAGE` views
- [ ] Warehouse for agent execution created
- [ ] Python 3.9+ installed (for MCP server)
- [ ] Git client installed
- [ ] Text editor for SQL placeholder replacement

### Configuration Values
Gather these before starting:

- [ ] Database name: `_______________`
- [ ] Schema name: `_______________`
- [ ] Admin role: `_______________`
- [ ] Developer role: `_______________`
- [ ] Execution warehouse: `_______________`
- [ ] Credit rate (USD): `_______________`
- [ ] Agent names:
  - [ ] Admin Agent: `_______________`
  - [ ] Cost Optimizer Agent: `_______________`
  - [ ] Security Agent: `_______________`
  - [ ] Orchestrator Agent: `_______________`

## SQL Deployment

### Phase 1: Foundation (Admin Agent)
- [ ] **01_create_views.sql**
  - [ ] Replace all placeholders
  - [ ] Execute in Snowflake
  - [ ] Verify 9 views created
  - [ ] Test: `SELECT * FROM <APP_DB>.<APP_SCHEMA>.V_WAREHOUSE_COST_BY_TAG LIMIT 10;`

- [ ] **02_create_semantic_views.sql**
  - [ ] Replace all placeholders including `<CREDIT_RATE_USD>`
  - [ ] Execute in Snowflake
  - [ ] Verify 8 semantic views created
  - [ ] Test: `SHOW SEMANTIC VIEWS IN SCHEMA <APP_DB>.<APP_SCHEMA>;`

- [ ] **03_create_agent.sql**
  - [ ] Replace all placeholders
  - [ ] Execute in Snowflake
  - [ ] Verify agent created
  - [ ] Test: `SHOW AGENTS IN SCHEMA <APP_DB>.<APP_SCHEMA>;`

- [ ] **04_create_budget.sql** (Optional)
  - [ ] Replace placeholders
  - [ ] Set credit limit as needed
  - [ ] Execute in Snowflake
  - [ ] Test: `CALL <APP_DB>.<APP_SCHEMA>.<BUDGET_NAME>!GET_CONFIG();`

- [ ] **05_grants.sql**
  - [ ] Replace role names
  - [ ] Execute in Snowflake
  - [ ] Verify: `SHOW GRANTS ON AGENT <APP_DB>.<APP_SCHEMA>.<AGENT_NAME>;`

### Phase 2: Cost Optimizer Agent
- [ ] **06_create_cost_optimizer_views.sql**
  - [ ] Replace all placeholders
  - [ ] Execute in Snowflake
  - [ ] Verify 6 views created
  - [ ] Test: `SELECT * FROM <APP_DB>.<APP_SCHEMA>.V_IDLE_WAREHOUSES LIMIT 10;`

- [ ] **07_create_cost_optimizer_semantic_views.sql**
  - [ ] Replace all placeholders including `<CREDIT_RATE_USD>`
  - [ ] Execute in Snowflake
  - [ ] Verify 6 semantic views created
  - [ ] Test: `SHOW SEMANTIC VIEWS LIKE 'SV_%OPTIMIZER%';`

- [ ] **10_create_cost_optimizer_agent.sql**
  - [ ] Replace all placeholders
  - [ ] Execute in Snowflake
  - [ ] Verify agent created
  - [ ] Test: `SHOW AGENTS LIKE '%COST%';`

### Phase 3: Security & Governance Agent
- [ ] **08_create_security_governance_views.sql**
  - [ ] Replace all placeholders
  - [ ] Execute in Snowflake
  - [ ] Verify 9 views created
  - [ ] Test: `SELECT * FROM <APP_DB>.<APP_SCHEMA>.V_FAILED_LOGIN_ATTEMPTS LIMIT 10;`

- [ ] **09_create_security_governance_semantic_views.sql**
  - [ ] Replace all placeholders
  - [ ] Execute in Snowflake
  - [ ] Verify 9 semantic views created
  - [ ] Test: `SHOW SEMANTIC VIEWS LIKE 'SV_%SECURITY%';`

- [ ] **11_create_security_governance_agent.sql**
  - [ ] Replace all placeholders
  - [ ] Execute in Snowflake
  - [ ] Verify agent created
  - [ ] Test: `SHOW AGENTS LIKE '%SECURITY%';`

### Phase 4: Orchestrator Agent
- [ ] **12_create_orchestrator_agent.sql**
  - [ ] Replace ALL agent FQN placeholders
  - [ ] Execute routing function first
  - [ ] Execute orchestrator agent
  - [ ] Execute grant statements
  - [ ] Verify: `SHOW FUNCTIONS LIKE 'F_ROUTE_TO_AGENT';`
  - [ ] Verify: `SHOW AGENTS LIKE '%ORCHESTRATOR%';`

### Validation Queries
Run these to verify everything is deployed:

```sql
-- Count all views
SELECT COUNT(*) FROM <APP_DB>.INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = '<APP_SCHEMA>';
-- Expected: 24+ views

-- Count semantic views
SHOW SEMANTIC VIEWS IN SCHEMA <APP_DB>.<APP_SCHEMA>;
-- Expected: 23 semantic views

-- Count agents
SHOW AGENTS IN SCHEMA <APP_DB>.<APP_SCHEMA>;
-- Expected: 4 agents

-- Test admin agent
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  '<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>',
  '{"messages":[{"role":"user","content":[{"type":"text","text":"How many credits did we use last month?"}]}]}'
);

-- Test cost optimizer agent
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  '<APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>',
  '{"messages":[{"role":"user","content":[{"type":"text","text":"Which warehouses are idle?"}]}]}'
);

-- Test security agent
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  '<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>',
  '{"messages":[{"role":"user","content":[{"type":"text","text":"Show me failed login attempts"}]}]}'
);

-- Test orchestrator
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  '<APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>',
  '{"messages":[{"role":"user","content":[{"type":"text","text":"How much could I save this month?"}]}]}'
);
```

## MCP Server Deployment

### Local Development Setup
- [ ] Clone repository: `git clone <repo_url>`
- [ ] Navigate to directory: `cd agent_snowflake_admin`
- [ ] Install dependencies: `pip install -r mcp/requirements.txt`
- [ ] Create `.env` file in root directory
- [ ] Add all required environment variables:
  ```bash
  SNOWFLAKE_ACCOUNT=_______________
  SNOWFLAKE_USER=_______________
  SNOWFLAKE_PASSWORD=_______________
  SNOWFLAKE_AUTHENTICATOR=snowflake
  SNOWFLAKE_ROLE=_______________
  SNOWFLAKE_WAREHOUSE=_______________
  SNOWFLAKE_ADMIN_AGENT_FQN=_______________
  SNOWFLAKE_COST_OPTIMIZER_AGENT_FQN=_______________
  SNOWFLAKE_SECURITY_AGENT_FQN=_______________
  SNOWFLAKE_ORCHESTRATOR_AGENT_FQN=_______________
  MCP_PORT=3000
  AUTH_MODE=none
  ALLOWED_ORIGINS=*
  ```
- [ ] Test connection: `python mcp/server.py`
- [ ] Verify startup message shows all 4 agents
- [ ] Test health endpoint: `curl http://localhost:3000/health`
- [ ] Expected response includes all agent FQNs

### GitHub Copilot Integration
- [ ] Create or update `.vscode/mcp.json`:
  ```json
  {
    "mcpServers": {
      "snowflake-admin": {
        "url": "http://localhost:3000/mcp"
      }
    }
  }
  ```
- [ ] Restart VS Code
- [ ] Open Copilot Chat
- [ ] Test: `@workspace How many credits did we use yesterday?`
- [ ] Verify agent response received

### MCP Server Testing
- [ ] Test tool list: `curl http://localhost:3000/mcp/tools/list`
- [ ] Verify 4 tools returned: ask_orchestrator, ask_admin, ask_cost_optimizer, ask_security
- [ ] Test orchestrator call:
  ```bash
  curl -X POST http://localhost:3000/mcp/tools/call \
    -H "Content-Type: application/json" \
    -d '{"name":"ask_orchestrator","arguments":{"question":"How many credits did we use yesterday?"}}'
  ```
- [ ] Test cost optimizer call:
  ```bash
  curl -X POST http://localhost:3000/mcp/tools/call \
    -H "Content-Type: application/json" \
    -d '{"name":"ask_cost_optimizer","arguments":{"question":"Which warehouses are idle?"}}'
  ```
- [ ] Test security call:
  ```bash
  curl -X POST http://localhost:3000/mcp/tools/call \
    -H "Content-Type: application/json" \
    -d '{"name":"ask_security","arguments":{"question":"Show me failed login attempts"}}'
  ```

## Production Deployment (AWS)

### Prerequisites
- [ ] AWS account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] Docker installed (for image building)
- [ ] Domain name (optional, for custom domain)

### Container Build
- [ ] Build Docker image: `docker build -t snowflake-admin-mcp .`
- [ ] Test locally: `docker run -p 3000:3000 --env-file .env snowflake-admin-mcp`
- [ ] Verify health endpoint: `curl http://localhost:3000/health`
- [ ] Push to ECR or Docker Hub

### AWS App Runner Deployment
- [ ] Create App Runner service
- [ ] Configure environment variables (all agent FQNs)
- [ ] Set `AUTH_MODE=cognito`
- [ ] Configure Cognito User Pool
- [ ] Set `COGNITO_REGION`, `COGNITO_USER_POOL_ID`, `COGNITO_APP_CLIENT_ID`
- [ ] Configure ALLOWED_ORIGINS for CORS
- [ ] Deploy service
- [ ] Test health endpoint: `curl https://<app-runner-url>/health`
- [ ] Verify authentication required: `curl https://<app-runner-url>/mcp/tools/list` (should return 401)

### Amazon Cognito Setup
- [ ] Create User Pool
- [ ] Configure app client
- [ ] Set up hosted UI (optional)
- [ ] Create test user
- [ ] Test authentication flow
- [ ] Obtain JWT token
- [ ] Test authenticated request:
  ```bash
  curl -H "Authorization: Bearer <jwt_token>" \
    https://<app-runner-url>/mcp/tools/list
  ```

### Frontend Deployment (AWS Amplify)
- [ ] Create Amplify app
- [ ] Connect to Git repository (frontend code)
- [ ] Configure build settings
- [ ] Set environment variables (App Runner URL, Cognito details)
- [ ] Deploy
- [ ] Test end-to-end flow

## Post-Deployment Validation

### Functional Testing
- [ ] **Orchestrator routing**
  - [ ] Ask cost question → routes to Cost Optimizer
  - [ ] Ask security question → routes to Security Agent
  - [ ] Ask operational question → routes to Admin Agent
  - [ ] Ask multi-domain question → routes to multiple agents

- [ ] **Direct agent access**
  - [ ] Call Admin Agent directly
  - [ ] Call Cost Optimizer directly
  - [ ] Call Security Agent directly

- [ ] **Data accuracy**
  - [ ] Verify credit numbers match `SNOWFLAKE.ACCOUNT_USAGE`
  - [ ] Verify warehouse usage matches reality
  - [ ] Verify failed login counts are accurate

### Performance Testing
- [ ] Measure average response time per agent
- [ ] Expected: 1-5 seconds for simple queries
- [ ] Expected: 5-15 seconds for complex queries
- [ ] Test concurrent requests (5-10 simultaneous)
- [ ] Monitor warehouse utilization during tests

### Security Validation
- [ ] **Authentication**
  - [ ] Verify unauthenticated requests blocked (if AUTH_MODE=cognito)
  - [ ] Verify invalid JWT tokens rejected
  - [ ] Verify expired tokens rejected

- [ ] **Authorization**
  - [ ] Verify Snowflake role restrictions honored
  - [ ] Test with read-only role
  - [ ] Test with admin role

- [ ] **Network Security**
  - [ ] Verify CORS settings
  - [ ] Test with allowed/disallowed origins
  - [ ] Verify HTTPS in production

### Cost Monitoring
- [ ] Set up warehouse monitoring
- [ ] Track agent query costs
- [ ] Verify budget limits (if configured)
- [ ] Set up alerts at 80% threshold
- [ ] Monitor for unexpected cost spikes

## Documentation & Training

### Internal Documentation
- [ ] Document connection details for team
- [ ] Create example questions cheat sheet
- [ ] Document troubleshooting steps
- [ ] Create runbook for common issues

### User Training
- [ ] Train team on Orchestrator vs direct agent usage
- [ ] Provide example questions for each agent
- [ ] Demonstrate GitHub Copilot integration
- [ ] Share best practices

### Operational Procedures
- [ ] Document deployment process
- [ ] Create rollback procedure
- [ ] Set up monitoring dashboards
- [ ] Configure alerting
- [ ] Schedule regular security audits

## Maintenance Schedule

### Daily
- [ ] Review agent usage logs
- [ ] Monitor for errors/failures
- [ ] Check warehouse credit consumption

### Weekly
- [ ] Review cost trends
- [ ] Validate data accuracy
- [ ] Check for security anomalies
- [ ] Review most common questions

### Monthly
- [ ] Update semantic views if needed
- [ ] Review and optimize agent instructions
- [ ] Audit user access
- [ ] Review budget utilization
- [ ] Check for Snowflake release notes (semantic view syntax changes)

### Quarterly
- [ ] Full security audit
- [ ] Performance optimization review
- [ ] Cost optimization review
- [ ] Add new semantic views based on user needs
- [ ] Consider adding new specialist agents

## Rollback Procedure

If issues arise, follow this rollback:

### Emergency Rollback
1. [ ] Stop MCP server
2. [ ] Revert to previous agent versions:
   ```sql
   -- Drop new agents
   DROP AGENT IF EXISTS <APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>;
   DROP AGENT IF EXISTS <APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>;
   DROP AGENT IF EXISTS <APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>;
   ```
3. [ ] Restart MCP server with previous configuration
4. [ ] Verify old agent still works
5. [ ] Investigate issue before re-deploying

### Incremental Rollback
1. [ ] Disable affected agent only
2. [ ] Update orchestrator to skip problematic agent
3. [ ] Fix underlying issue
4. [ ] Re-enable agent
5. [ ] Test thoroughly

## Support & Troubleshooting

### Common Issues

**Issue:** Orchestrator not routing correctly
- [ ] Check all agent FQN environment variables
- [ ] Verify grants: `SHOW GRANTS TO AGENT <ORCHESTRATOR_AGENT_NAME>;`
- [ ] Review orchestrator instructions
- [ ] Test direct agent calls

**Issue:** Agent returns empty results
- [ ] Check semantic view exists: `SHOW SEMANTIC VIEWS;`
- [ ] Verify ACCOUNT_USAGE access
- [ ] Check for data latency (wait 1-3 hours)
- [ ] Test underlying views directly

**Issue:** MCP server errors
- [ ] Check Snowflake credentials
- [ ] Verify network connectivity
- [ ] Review server logs
- [ ] Check authentication mode

### Getting Help
- [ ] Review [Multi-Agent Architecture](docs/multi-agent-architecture.md)
- [ ] Check [Troubleshooting Section](README.md#troubleshooting)
- [ ] Review Snowflake Cortex AI documentation
- [ ] Open GitHub issue with:
  - Error message
  - Agent name
  - Example question
  - Expected vs actual behavior

## Sign-Off

Deployment completed by: _______________ Date: _______________

Validated by: _______________ Date: _______________

Approved for production: _______________ Date: _______________

Notes:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
