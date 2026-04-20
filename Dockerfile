FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    MCP_PORT=8080

WORKDIR /app

COPY mcp/requirements.txt /app/mcp/requirements.txt
RUN pip install --upgrade pip && pip install -r /app/mcp/requirements.txt

COPY mcp /app/mcp

EXPOSE 8080

CMD ["python", "mcp/server.py"]
