FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git npm nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Install vibe-trading ──
RUN pip install --no-cache-dir vibe-trading

# ── Install hermes-agent in a venv ──
RUN python3 -m venv /opt/hermes-venv \
    && /opt/hermes-venv/bin/pip install --no-cache-dir hermes-agent 'mcp>=1.9'

# ── Runtime env ──
ENV VIRTUAL_ENV=/opt/hermes-venv
ENV PATH="/opt/hermes-venv/bin:/usr/local/bin:$PATH"
ENV HERMES_HOME=/trader/hermes-home

# ── Persistent volumes ──
VOLUME ["/trader"]
WORKDIR /trader

# ── Entrypoint wrapper: sources trader-env then execs the command ──
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["hermes", "-p", "vibe-trading", "gateway", "run", "--replace"]