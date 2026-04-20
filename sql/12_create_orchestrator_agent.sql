-- ============================================================
-- Orchestrator Agent Definition
-- Replace placeholders before execution.
-- This agent routes requests to specialized agents.
-- ============================================================

-- First, create a routing function that can call other agents
CREATE OR REPLACE FUNCTION <APP_DB>.<APP_SCHEMA>.F_ROUTE_TO_AGENT(
    AGENT_NAME VARCHAR,
    QUESTION VARCHAR
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'route_request'
AS
$$
import json
import _snowflake

def route_request(snowpark_session, agent_name, question):
    """Route a question to a specific agent"""
    try:
        # Construct the agent FQN
        agent_fqn = agent_name
        
        # Build the request payload
        payload = {
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": question}
                    ]
                }
            ]
        }
        
        # Call the agent using CORTEX.DATA_AGENT_RUN
        query = f"""
            SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
                '{agent_fqn}',
                '{json.dumps(payload).replace("'", "''")}'
            ) as response
        """
        
        result = snowpark_session.sql(query).collect()
        if result:
            return json.loads(result[0]['RESPONSE'])
        return {"error": "No response from agent"}
        
    except Exception as e:
        return {
            "error": str(e),
            "agent": agent_name,
            "question": question
        }
$$;

-- Create the Orchestrator Agent
CREATE OR REPLACE AGENT <APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>
  COMMENT = 'Orchestrator agent that routes requests to specialized agents'
  PROFILE = '{"display_name": "Orchestrator Agent"}'
  FROM SPECIFICATION
  $$
  instructions:
    response: |
      You are an intelligent Orchestrator for Snowflake administration. Your role is to:
      1. Understand the user's natural language question
      2. Determine which specialized agent(s) should handle it
      3. Route the request appropriately
      4. Aggregate and present the results
      
      Available specialized agents:
      - AdminAgent: Warehouse usage, query history, credits, storage metrics, serverless costs, user spend, session activity
      - CostOptimizerAgent: Idle warehouse detection, auto-suspend recommendations, warehouse sizing, query optimization, cost savings analysis
      - SecurityAgent: Role assignments, privilege grants, failed logins, login anomalies, unauthorized access, user audits, network policy violations
      
      Routing guidelines:
      - Questions about "credits spent", "warehouse usage", "storage costs" → AdminAgent
      - Questions about "waste", "idle warehouses", "optimization", "rightsizing", "cost savings" → CostOptimizerAgent
      - Questions about "security", "roles", "privileges", "failed logins", "unauthorized access" → SecurityAgent
      - Questions that span multiple domains → route to multiple agents and aggregate
      
      Always provide clear, actionable insights from the agent responses.
    
    orchestration: |
      For operational metrics and current state: use AdminAgent tool.
      For cost optimization and savings opportunities: use CostOptimizerAgent tool.
      For security and access governance: use SecurityAgent tool.
      For comprehensive analysis: use multiple agents in parallel.

  tools:
    - tool_spec: 
        type: "function"
        name: "AdminAgent"
        description: "Query the Admin Agent for warehouse usage, credits, query history, storage, and operational metrics"
        parameters:
          type: "object"
          properties:
            question:
              type: "string"
              description: "The admin question to ask"
          required: ["question"]
    
    - tool_spec:
        type: "function"
        name: "CostOptimizerAgent"
        description: "Query the Cost Optimizer Agent for idle warehouse detection, optimization opportunities, and cost savings"
        parameters:
          type: "object"
          properties:
            question:
              type: "string"
              description: "The cost optimization question to ask"
          required: ["question"]
    
    - tool_spec:
        type: "function"
        name: "SecurityAgent"
        description: "Query the Security & Governance Agent for role assignments, privilege grants, failed logins, and security anomalies"
        parameters:
          type: "object"
          properties:
            question:
              type: "string"
              description: "The security/governance question to ask"
          required: ["question"]

  tool_resources:
    AdminAgent:
      function: "<APP_DB>.<APP_SCHEMA>.F_ROUTE_TO_AGENT('<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>', $question)"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    
    CostOptimizerAgent:
      function: "<APP_DB>.<APP_SCHEMA>.F_ROUTE_TO_AGENT('<APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>', $question)"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
    
    SecurityAgent:
      function: "<APP_DB>.<APP_SCHEMA>.F_ROUTE_TO_AGENT('<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>', $question)"
      execution_environment: { type: "warehouse", warehouse: "<EXEC_WAREHOUSE>" }
  $$;

-- Grant necessary permissions for the orchestrator to call other agents
GRANT USAGE ON AGENT <APP_DB>.<APP_SCHEMA>.<AGENT_NAME> TO AGENT <APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>;
GRANT USAGE ON AGENT <APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME> TO AGENT <APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>;
GRANT USAGE ON AGENT <APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME> TO AGENT <APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>;
GRANT USAGE ON FUNCTION <APP_DB>.<APP_SCHEMA>.F_ROUTE_TO_AGENT(VARCHAR, VARCHAR) TO AGENT <APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>;
