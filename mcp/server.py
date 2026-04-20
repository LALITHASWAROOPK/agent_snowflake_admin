import json
import os
import time
from collections import defaultdict, deque
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.request import urlopen

from dotenv import load_dotenv
import jwt
from snowflake.connector import connect


load_dotenv()

SNOWFLAKE_ACCOUNT = os.environ.get("SNOWFLAKE_ACCOUNT", "<your_account>")
SNOWFLAKE_USER = os.environ.get("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.environ.get("SNOWFLAKE_PASSWORD")
SNOWFLAKE_AUTHENTICATOR = os.environ.get("SNOWFLAKE_AUTHENTICATOR", "externalbrowser")
SNOWFLAKE_TOKEN = os.environ.get("SNOWFLAKE_TOKEN")
SNOWFLAKE_ROLE = os.environ.get("SNOWFLAKE_ROLE", "<DEVELOPER_ROLE>")
SNOWFLAKE_WAREHOUSE = os.environ.get("SNOWFLAKE_WAREHOUSE", "<EXEC_WAREHOUSE>")

# Multi-Agent Configuration
ADMIN_AGENT_FQN = os.environ.get("SNOWFLAKE_ADMIN_AGENT_FQN", "<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>")
COST_OPTIMIZER_AGENT_FQN = os.environ.get("SNOWFLAKE_COST_OPTIMIZER_AGENT_FQN", "<APP_DB>.<APP_SCHEMA>.<COST_OPTIMIZER_AGENT_NAME>")
SECURITY_AGENT_FQN = os.environ.get("SNOWFLAKE_SECURITY_AGENT_FQN", "<APP_DB>.<APP_SCHEMA>.<SECURITY_AGENT_NAME>")
ORCHESTRATOR_AGENT_FQN = os.environ.get("SNOWFLAKE_ORCHESTRATOR_AGENT_FQN", "<APP_DB>.<APP_SCHEMA>.<ORCHESTRATOR_AGENT_NAME>")

# Backward compatibility - default to orchestrator if AGENT_FQN is set
AGENT_FQN = os.environ.get("SNOWFLAKE_AGENT_FQN", ORCHESTRATOR_AGENT_FQN)

MCP_PORT = int(os.environ.get("MCP_PORT", "3000"))

ALLOWED_ORIGINS = [origin.strip() for origin in os.environ.get("ALLOWED_ORIGINS", "*").split(",") if origin.strip()]

AUTH_MODE = os.environ.get("AUTH_MODE", "none").strip().lower()
COGNITO_REGION = os.environ.get("COGNITO_REGION")
COGNITO_USER_POOL_ID = os.environ.get("COGNITO_USER_POOL_ID")
COGNITO_APP_CLIENT_ID = os.environ.get("COGNITO_APP_CLIENT_ID")

RATE_LIMIT_REQUESTS = int(os.environ.get("RATE_LIMIT_REQUESTS", "60"))
RATE_LIMIT_WINDOW_SECONDS = int(os.environ.get("RATE_LIMIT_WINDOW_SECONDS", "60"))

RATE_LIMIT_BUCKETS: dict[str, deque] = defaultdict(deque)
JWKS_CACHE: dict = {"value": None, "expires_at": 0.0}


def _cors_origin(request_origin: str | None) -> str:
    if "*" in ALLOWED_ORIGINS:
        return "*"
    if request_origin and request_origin in ALLOWED_ORIGINS:
        return request_origin
    return ALLOWED_ORIGINS[0] if ALLOWED_ORIGINS else "*"


def _load_cognito_jwks() -> dict:
    now = time.time()
    if JWKS_CACHE["value"] and now < JWKS_CACHE["expires_at"]:
        return JWKS_CACHE["value"]

    if not COGNITO_REGION or not COGNITO_USER_POOL_ID:
        raise ValueError("COGNITO_REGION and COGNITO_USER_POOL_ID are required when AUTH_MODE=cognito")

    url = (
        "https://cognito-idp."
        f"{COGNITO_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}/.well-known/jwks.json"
    )
    with urlopen(url, timeout=5) as response:
        jwks = json.loads(response.read().decode("utf-8"))

    JWKS_CACHE["value"] = jwks
    JWKS_CACHE["expires_at"] = now + 3600
    return jwks


def _verify_cognito_token(auth_header: str | None) -> dict:
    if not auth_header or not auth_header.lower().startswith("bearer "):
        raise PermissionError("Missing bearer token")

    token = auth_header.split(" ", 1)[1].strip()
    if not token:
        raise PermissionError("Empty bearer token")

    unverified = jwt.get_unverified_header(token)
    kid = unverified.get("kid")
    if not kid:
        raise PermissionError("Token missing kid")

    jwks = _load_cognito_jwks()
    key_dict = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
    if not key_dict:
        raise PermissionError("Unknown signing key")

    public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key_dict))
    issuer = f"https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{COGNITO_USER_POOL_ID}"

    payload = jwt.decode(
        token,
        public_key,
        algorithms=["RS256"],
        audience=COGNITO_APP_CLIENT_ID,
        issuer=issuer,
    )
    token_use = payload.get("token_use")
    if token_use not in {"id", "access"}:
        raise PermissionError("Unsupported token_use")
    return payload


def _enforce_rate_limit(client_ip: str):
    if RATE_LIMIT_REQUESTS <= 0:
        return

    now = time.time()
    bucket = RATE_LIMIT_BUCKETS[client_ip]
    cutoff = now - RATE_LIMIT_WINDOW_SECONDS

    while bucket and bucket[0] < cutoff:
        bucket.popleft()

    if len(bucket) >= RATE_LIMIT_REQUESTS:
        raise RuntimeError("Rate limit exceeded")

    bucket.append(now)


def _require_auth(headers):
    if AUTH_MODE == "none":
        return
    if AUTH_MODE == "cognito":
        _verify_cognito_token(headers.get("Authorization"))
        return
    raise PermissionError("Unsupported AUTH_MODE")


def get_connection():
    auth = SNOWFLAKE_AUTHENTICATOR.strip().lower()
    kwargs = {
        "account": SNOWFLAKE_ACCOUNT,
        "user": SNOWFLAKE_USER,
        "role": SNOWFLAKE_ROLE,
        "warehouse": SNOWFLAKE_WAREHOUSE,
        "authenticator": SNOWFLAKE_AUTHENTICATOR,
    }

    if auth in {"oauth", "oauth_authorization_code", "oauth_client_credentials"}:
        if not SNOWFLAKE_TOKEN:
            raise ValueError("SNOWFLAKE_TOKEN is required for OAuth authentication")
        kwargs["token"] = SNOWFLAKE_TOKEN
    elif auth == "snowflake":
        if not SNOWFLAKE_PASSWORD:
            raise ValueError("SNOWFLAKE_PASSWORD is required for password authentication")
        kwargs["password"] = SNOWFLAKE_PASSWORD

    return connect(**kwargs)


def ask_agent(question: str, agent_fqn: str = None) -> dict:
    """
    Query a specific agent or the default agent.
    
    Args:
        question: The natural language question to ask
        agent_fqn: Fully qualified name of the agent to query (defaults to AGENT_FQN)
    
    Returns:
        dict with 'answer' key containing the agent's response
    """
    if agent_fqn is None:
        agent_fqn = AGENT_FQN
        
    conn = get_connection()
    try:
        cur = conn.cursor()
        payload = json.dumps(
            {"messages": [{"role": "user", "content": [{"type": "text", "text": question}]}]}
        )
        escaped = payload.replace("'", "''")
        cur.execute(
            f"""
            SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
                '{agent_fqn}',
                '{escaped}'
            )
            """
        )
        response = json.loads(cur.fetchone()[0])
        text_chunks = [item.get("text", "") for item in response.get("content", []) if item.get("type") == "text"]
        return {"answer": "\n".join([t for t in text_chunks if t]) or "No response from agent."}
    finally:
        conn.close()


class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self._send(200, {"status": "ok"})

    def do_POST(self):
        client_ip = self.client_address[0] if self.client_address else "unknown"
        try:
            _enforce_rate_limit(client_ip)
            _require_auth(self.headers)
        except PermissionError as exc:
            self._send(401, {"error": "Unauthorized", "details": str(exc)})
            return
        except RuntimeError as exc:
            self._send(429, {"error": "Too Many Requests", "details": str(exc)})
            return

        content_length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(content_length)) if content_length else {}
        except json.JSONDecodeError:
            self._send(400, {"error": "Invalid JSON body"})
            return

        if self.path == "/mcp/tools/list":
            self._send(
                200,
                {
                    "tools": [
                        {
                            "name": "ask_orchestrator",
                            "description": "Ask the intelligent Orchestrator agent which routes requests to specialized agents (Admin, Cost Optimizer, Security). Use this for any Snowflake administration question.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "question": {"type": "string", "description": "Natural language question about Snowflake administration, costs, or security"}
                                },
                                "required": ["question"],
                            },
                        },
                        {
                            "name": "ask_admin",
                            "description": "Directly query the Admin agent about warehouse usage, credits, query history, storage metrics, serverless costs, user spend, and operational usage.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "question": {"type": "string", "description": "Natural language Admin question"}
                                },
                                "required": ["question"],
                            },
                        },
                        {
                            "name": "ask_cost_optimizer",
                            "description": "Directly query the Cost Optimizer agent about idle warehouses, auto-suspend recommendations, warehouse sizing, query optimization, and cost savings opportunities.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "question": {"type": "string", "description": "Natural language cost optimization question"}
                                },
                                "required": ["question"],
                            },
                        },
                        {
                            "name": "ask_security",
                            "description": "Directly query the Security & Governance agent about role assignments, privilege grants, failed logins, login anomalies, unauthorized access attempts, and compliance.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "question": {"type": "string", "description": "Natural language security/governance question"}
                                },
                                "required": ["question"],
                            },
                        }
                    ]
                },
            )
            return

        if self.path == "/mcp/tools/call":
            tool_name = body.get("name")
            
            # Map tool names to agent FQNs
            agent_map = {
                "ask_orchestrator": ORCHESTRATOR_AGENT_FQN,
                "ask_admin": ADMIN_AGENT_FQN,
                "ask_cost_optimizer": COST_OPTIMIZER_AGENT_FQN,
                "ask_security": SECURITY_AGENT_FQN,
            }
            
            if tool_name not in agent_map:
                self._send(404, {"error": f"Unknown tool: {tool_name}"})
                return

            question = body.get("arguments", {}).get("question", "")
            if not isinstance(question, str) or not question.strip():
                self._send(400, {"error": "question must be a non-empty string"})
                return
            if len(question) > 2000:
                self._send(400, {"error": "question is too long (max 2000 chars)"})
                return

            try:
                agent_fqn = agent_map[tool_name]
                result = ask_agent(question, agent_fqn=agent_fqn)
                self._send(200, {"content": [{"type": "text", "text": result["answer"]}]})
            except Exception as exc:
                self._send(500, {"error": "Agent query failed", "details": str(exc)})
            return

        self._send(404, {"error": "Not found"})

    def do_GET(self):
        if self.path != "/health":
            try:
                _require_auth(self.headers)
            except PermissionError as exc:
                self._send(401, {"error": "Unauthorized", "details": str(exc)})
                return

        if self.path == "/health":
            self._send(200, {
                "status": "ok",
                "agents": {
                    "orchestrator": ORCHESTRATOR_AGENT_FQN,
                    "admin": ADMIN_AGENT_FQN,
                    "cost_optimizer": COST_OPTIMIZER_AGENT_FQN,
                    "security": SECURITY_AGENT_FQN,
                }
            })
            return
        self._send(404, {"error": "Not found"})

    def _send(self, status: int, payload: dict):
        request_origin = self.headers.get("Origin")
        cors_origin = _cors_origin(request_origin)

        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", cors_origin)
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Access-Control-Max-Age", "86400")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())


if __name__ == "__main__":
    print(f"Multi-Agent Snowflake Admin MCP server listening on port {MCP_PORT}")
    print(f"\nConfigured Agents:")
    print(f"  🧠 Orchestrator: {ORCHESTRATOR_AGENT_FQN}")
    print(f"  🔧 Admin Agent: {ADMIN_AGENT_FQN}")
    print(f"  💰 Cost Optimizer: {COST_OPTIMIZER_AGENT_FQN}")
    print(f"  🔐 Security & Governance: {SECURITY_AGENT_FQN}")
    print(f"\nAuthenticator: {SNOWFLAKE_AUTHENTICATOR}")
    print(f"Auth mode: {AUTH_MODE}")
    print(f"\nAvailable MCP tools:")
    print(f"  - ask_orchestrator (recommended - intelligent routing)")
    print(f"  - ask_admin (direct)")
    print(f"  - ask_cost_optimizer (direct)")
    print(f"  - ask_security (direct)")
    print(f"\nServer ready!")
    HTTPServer(("0.0.0.0", MCP_PORT), Handler).serve_forever()
