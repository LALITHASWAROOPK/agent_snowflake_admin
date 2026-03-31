import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

from dotenv import load_dotenv
from snowflake.connector import connect


load_dotenv()

SNOWFLAKE_ACCOUNT = os.environ.get("SNOWFLAKE_ACCOUNT", "<your_account>")
SNOWFLAKE_USER = os.environ.get("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.environ.get("SNOWFLAKE_PASSWORD")
SNOWFLAKE_AUTHENTICATOR = os.environ.get("SNOWFLAKE_AUTHENTICATOR", "externalbrowser")
SNOWFLAKE_TOKEN = os.environ.get("SNOWFLAKE_TOKEN")
SNOWFLAKE_ROLE = os.environ.get("SNOWFLAKE_ROLE", "<DEVELOPER_ROLE>")
SNOWFLAKE_WAREHOUSE = os.environ.get("SNOWFLAKE_WAREHOUSE", "<EXEC_WAREHOUSE>")
AGENT_FQN = os.environ.get("SNOWFLAKE_AGENT_FQN", "<APP_DB>.<APP_SCHEMA>.<AGENT_NAME>")
MCP_PORT = int(os.environ.get("MCP_PORT", "3000"))


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


def ask_agent(question: str) -> dict:
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
                '{AGENT_FQN}',
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
    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(content_length)) if content_length else {}

        if self.path == "/mcp/tools/list":
            self._send(
                200,
                {
                    "tools": [
                        {
                            "name": "ask_admin",
                            "description": "Ask the Snowflake Admin agent about compute, storage, serverless, user spend, pricing, and operational usage.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "question": {"type": "string", "description": "Natural language Admin question"}
                                },
                                "required": ["question"],
                            },
                        }
                    ]
                },
            )
            return

        if self.path == "/mcp/tools/call":
            if body.get("name") != "ask_admin":
                self._send(404, {"error": "Unknown tool"})
                return

            question = body.get("arguments", {}).get("question", "")
            try:
                result = ask_agent(question)
                self._send(200, {"content": [{"type": "text", "text": result["answer"]}]})
            except Exception as exc:
                self._send(500, {"error": "Agent query failed", "details": str(exc)})
            return

        self._send(404, {"error": "Not found"})

    def do_GET(self):
        if self.path == "/health":
            self._send(200, {"status": "ok", "agent": AGENT_FQN})
            return
        self._send(404, {"error": "Not found"})

    def _send(self, status: int, payload: dict):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())


if __name__ == "__main__":
    print(f"Generic Admin MCP server listening on {MCP_PORT}")
    print(f"Agent: {AGENT_FQN}")
    print(f"Authenticator: {SNOWFLAKE_AUTHENTICATOR}")
    HTTPServer(("0.0.0.0", MCP_PORT), Handler).serve_forever()
