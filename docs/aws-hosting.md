# AWS Hosting Guide (App Runner + Cognito + Amplify)

This guide deploys the Snowflake admin MCP bridge for multi-user access on AWS.

## Recommended Architecture

1. Frontend chat page on AWS Amplify Hosting.
2. Backend MCP API on AWS App Runner (containerized Python service).
3. User login via Amazon Cognito User Pool.
4. Backend secrets in AWS Secrets Manager.
5. Optional protection with AWS WAF and CloudWatch alarms.

## 1) Prepare Snowflake Service Auth

For hosted mode, avoid interactive authentication.

1. Use `SNOWFLAKE_AUTHENTICATOR=snowflake` with a dedicated service user and password, or use OAuth if already configured in your Snowflake org.
2. Grant least-privilege role access to the semantic views and Cortex agent.
3. Keep warehouse small and enforce budget limits where possible.

## 2) Build and Push Container to ECR

From `agent_snowflake_admin`:

```bash
aws ecr create-repository --repository-name snowflake-admin-mcp

aws ecr get-login-password --region <AWS_REGION> \
  | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com

docker build -t snowflake-admin-mcp:latest .
docker tag snowflake-admin-mcp:latest <ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/snowflake-admin-mcp:latest
docker push <ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/snowflake-admin-mcp:latest
```

## 3) Create Cognito User Pool + App Client

1. Create a Cognito User Pool.
2. Create an App Client (no secret for browser-based login).
3. Enable Hosted UI or integrate with your preferred login UI.
4. Note values:
   - `COGNITO_REGION`
   - `COGNITO_USER_POOL_ID`
   - `COGNITO_APP_CLIENT_ID`

## 4) Store Backend Secrets

Create entries in Secrets Manager:

- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_PASSWORD` or `SNOWFLAKE_TOKEN`
- `SNOWFLAKE_ROLE`
- `SNOWFLAKE_WAREHOUSE`
- `SNOWFLAKE_AGENT_FQN`

## 5) Deploy App Runner Service

Create an App Runner service from the ECR image and set runtime environment variables:

- `MCP_PORT=8080`
- `SNOWFLAKE_ACCOUNT=<from secret>`
- `SNOWFLAKE_USER=<from secret>`
- `SNOWFLAKE_PASSWORD=<from secret>`
- `SNOWFLAKE_AUTHENTICATOR=snowflake`
- `SNOWFLAKE_ROLE=<from secret>`
- `SNOWFLAKE_WAREHOUSE=<from secret>`
- `SNOWFLAKE_AGENT_FQN=<from secret>`
- `AUTH_MODE=cognito`
- `COGNITO_REGION=<region>`
- `COGNITO_USER_POOL_ID=<user_pool_id>`
- `COGNITO_APP_CLIENT_ID=<app_client_id>`
- `ALLOWED_ORIGINS=https://<your-amplify-domain>`
- `RATE_LIMIT_REQUESTS=60`
- `RATE_LIMIT_WINDOW_SECONDS=60`

Map secret values via App Runner environment secrets where possible.

## 6) Deploy Frontend on Amplify

1. Host your static chat page in Amplify.
2. Configure the frontend API base URL to your App Runner URL.
3. Sign in users with Cognito and send bearer token in `Authorization` header.

## 7) API Contract for Chat Calls

Request:

```http
POST /mcp/tools/call
Content-Type: application/json
Authorization: Bearer <cognito_jwt>

{
  "name": "ask_admin",
  "arguments": {
    "question": "What are top 5 warehouses by credits in last 30 days?"
  }
}
```

Response:

```json
{
  "content": [
    {
      "type": "text",
      "text": "...answer from Cortex agent..."
    }
  ]
}
```

## 8) Validation Checklist

1. `/health` returns status `ok`.
2. Unauthorized requests to `/mcp/tools/call` return `401` when `AUTH_MODE=cognito`.
3. Browser call succeeds only from `ALLOWED_ORIGINS` domain.
4. Repeated flood requests return `429`.

## 9) Cost and Security Notes

1. Set App Runner min instances to 1 only if low latency is required.
2. Keep defaults at 0 for cheaper idle cost if occasional cold starts are acceptable.
3. Set CloudWatch alarms for 5xx rates and p95 latency.
4. Rotate Snowflake credentials on a schedule.
5. Consider AWS WAF in front of CloudFront if exposing to broad internet traffic.
