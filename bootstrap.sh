#!/bin/bash
# ==============================================================================
# 🤖 AUTONOMOUS ENGINEERING FACTORY (AEF) - MASTER BOOTSTRAP (RECONCILED)
# Architecture: Senior Lead / Reconciled Modular Stack / Zero-Trust
# ==============================================================================
set -e

# --- UI COLORS ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🏗️ Initializing Reconciled AEF Modular Build...${NC}"

# 1. HOST HARDENING & DEPENDENCIES
echo -e "${YELLOW}📦 Installing System Dependencies...${NC}"
sudo -n apt update && sudo -n apt install -y \
    curl git openssl jq build-essential libmagic-dev \
    python3-pip python3-venv docker.io docker-compose-v2 || echo -e "${YELLOW}⚠️ System update failed, continuing with existing dependencies...${NC}"

if getent group docker > /dev/null; then
    sudo -n usermod -aG docker $USER || true
fi

# 2. DIRECTORY ARCHITECTURE
echo -e "${YELLOW}📁 Creating Modular Workspace with Observability & Data Layers...${NC}"
mkdir -p ~/factory/{compose,data/{postgres,n8n,chroma,guac,tailscale,kuma,redis,searxng,anythingllm,nginx,prometheus,grafana,dockge},knowledge_base,scripts,workspace}
cd ~/factory

# 3. GENERATE SECURE ENV TEMPLATES
echo -e "${YELLOW}🔐 Generating Reconciled Security Templates...${NC}"
VM_IP_VAL=$(hostname -I | awk '{print $1}')
[ -z "$VM_IP_VAL" ] && VM_IP_VAL="127.0.0.1"

cat <<EOF > .env.example
# --- SYSTEM & NETWORK ---
VM_IP=$VM_IP_VAL
RUST_KEY=GENERATE_SECRET_RUST

# --- AI & ORCHESTRATION ---
OPENAI_API_KEY=sk-xxxx
GITHUB_TOKEN=ghp_xxxx
SLACK_BOT_TOKEN=xoxb-xxxx
TELEGRAM_BOT_TOKEN=xxxx:xxxx

# --- PROXMOX API BRIDGE ---
PVE_HOST=192.168.1.XX
PVE_USER=automation@pve
PVE_TOKEN_NAME=aef-token
PVE_TOKEN_VALUE=xxxx-xxxx-xxxx

# --- NETWORK & ACCESS ---
CLOUDFLARE_TUNNEL_TOKEN=ey...
TAILSCALE_AUTHKEY=tskey-auth-...
GUAC_ADMIN_PASSWORD=AdminPassword123!
GRAFANA_PASSWORD=GrafanaAdmin123!

# --- AUTO-GENERATED SECRETS ---
N8N_SECRET=GENERATE_SECRET_N8N
POSTGRES_USER=aef_admin
POSTGRES_PASSWORD=GENERATE_SECRET_POSTGRES
REDIS_PASSWORD=GENERATE_SECRET_REDIS
EOF

if [ ! -f .env ]; then
    cp .env.example .env
    # Perform substitutions with unique secrets
    sed -i "s/GENERATE_SECRET_RUST/$(openssl rand -hex 16)/" .env
    sed -i "s/GENERATE_SECRET_N8N/$(openssl rand -hex 24)/" .env
    sed -i "s/GENERATE_SECRET_POSTGRES/$(openssl rand -hex 16)/" .env
    sed -i "s/GENERATE_SECRET_REDIS/$(openssl rand -hex 16)/" .env
    echo -e "${GREEN}✅ .env file generated with unique secure random secrets and local IP.${NC}"
else
    echo -e "${YELLOW}⚠️ .env file already exists. Skipping overwrite.${NC}"
fi

# 4. WRITE MODULAR COMPOSE FILES
echo -e "${YELLOW}📦 Writing Reconciled Stack Modules...${NC}"

# Core: The Brain & Cache
cat <<EOF > compose/core.yml
services:
  postgres:
    image: postgres:16-alpine
    container_name: aef_db
    environment:
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    networks: [data_tier]
    healthcheck: { test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER}"], interval: 5s }

  redis:
    image: redis:7-alpine
    container_name: aef_cache
    command: redis-server --requirepass \${REDIS_PASSWORD}
    networks: [data_tier]

  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: aef_brain
    env_file: ../.env
    ports: ["4000:4000"]
    networks: [agent_bus]

  n8n:
    image: docker.n8n.io/n8nio/n8n
    container_name: aef_orchestrator
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_USER=\${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=\${POSTGRES_PASSWORD}
      - N8N_ENCRYPTION_KEY=\${N8N_SECRET}
    networks: [ingress, agent_bus, data_tier]
    volumes: [../data/n8n:/home/node/.n8n]
    depends_on: { postgres: { condition: service_healthy } }

networks:
  ingress:
  agent_bus:
  data_tier:
EOF

# Agents & RAG
cat <<EOF > compose/agents.yml
services:
  swe-agent:
    image: sweagent/swe-agent:latest
    container_name: aef_coder
    env_file: ../.env
    networks: [agent_bus, data_tier]
    volumes: ['/var/run/docker.sock:/var/run/docker.sock', '../workspace:/workspace']

  searxng:
    image: searxng/searxng:latest
    container_name: aef_search
    networks: [agent_bus]
    volumes: [../data/searxng:/etc/searxng]

  chromadb:
    image: chromadb/chroma:latest
    container_name: aef_memory
    networks: [agent_bus]
    volumes: [../data/chroma:/chroma/data]

  anythingllm:
    image: mintplexlabs/anythingllm:latest
    container_name: aef_kb_ui
    ports: ["3002:3001"]
    networks: [ingress, agent_bus]
    volumes: [../data/anythingllm:/app/storage]

networks:
  ingress:
  agent_bus:
  data_tier:
EOF

# Network & Ingress
cat <<EOF > compose/network.yml
services:
  nginx:
    image: jc21/nginx-proxy-manager:latest
    container_name: aef_proxy
    ports: ['80:80', '81:81', '443:443']
    networks: [ingress]
    volumes: [../data/nginx:/data, ../data/nginx/letsencrypt:/etc/letsencrypt]

  cf-tunnel:
    image: cloudflare/cloudflared:latest
    container_name: aef_tunnel
    command: tunnel run
    environment:
      TUNNEL_TOKEN: \${CLOUDFLARE_TUNNEL_TOKEN}
    networks: [ingress]

  tailscale:
    image: tailscale/tailscale:latest
    container_name: aef_mesh
    environment:
      TS_AUTHKEY: \${TAILSCALE_AUTHKEY}
      TS_STATE_DIR: /var/lib/tailscale
    volumes: ['../data/tailscale:/var/lib/tailscale', '/dev/net/tun:/dev/net/tun']
    cap_add: [NET_ADMIN, SYS_MODULE]
    networks: [ingress, agent_bus]

networks:
  ingress:
  agent_bus:
EOF

# Access & Management
cat <<EOF > compose/access.yml
services:
  dockge:
    image: louislam/dockge:1
    container_name: aef_manager
    ports: ["5001:5001"]
    networks: [ingress]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ../compose:/app/stacks
    environment:
      - DOCKGE_STACKS_DIR=/app/stacks

  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: aef_monitor
    ports: ['3001:3001']
    networks: [ingress]
    volumes: [../data/kuma:/app/data]

  guacamole:
    image: abcdesktopio/oc-guacamole:latest
    container_name: aef_remote
    environment:
      GUAC_ADMIN_PASSWORD: \${GUAC_ADMIN_PASSWORD}
    networks: [ingress, agent_bus]

networks:
  ingress:
  agent_bus:
EOF

# Observability & Monitoring
cat <<EOF > compose/observability.yml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: aef_telemetry
    networks: [monitoring]
    volumes: [../data/prometheus:/etc/prometheus]

  grafana:
    image: grafana/grafana:latest
    container_name: aef_dashboard
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=\${GRAFANA_PASSWORD}
    networks: [monitoring, ingress]
    volumes: [../data/grafana:/var/lib/grafana]

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.2
    container_name: aef_metrics
    networks: [monitoring]
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro

networks:
  monitoring:
  ingress:
EOF

# Master Entry
cat <<EOF > docker-compose.yml
include:
  - compose/core.yml
  - compose/agents.yml
  - compose/network.yml
  - compose/access.yml
  - compose/observability.yml

networks:
  ingress:
  agent_bus:
  data_tier:
  monitoring:
EOF

# 5. WRITE THE PROXMOX API BRIDGE
echo -e "${YELLOW}🐍 Setting up Proxmox Python Bridge...${NC}"
cat <<EOF > scripts/proxmox_bridge.py
import os
from proxmoxer import ProxmoxAPI
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

def get_pve():
    return ProxmoxAPI(
        os.getenv("PVE_HOST"),
        user=os.getenv("PVE_USER"),
        token_name=os.getenv("PVE_TOKEN_NAME"),
        token_value=os.getenv("PVE_TOKEN_VALUE"),
        verify_ssl=False
    )

def self_heal(vmid):
    p = get_pve()
    print(f"🤖 AEF Sentry: Resetting VM {vmid}")
    p.nodes('pve').qemu(vmid).status.reboot.post()

if __name__ == "__main__":
    try:
        nodes = get_pve().nodes.get()
        print(f"✅ API Connection Successful. Nodes: {[n['node'] for n in nodes]}")
    except Exception as e:
        print(f"❌ Connection Failed: {e}")
EOF

# 6. WRITE THE AGENT DEFINITIONS (AGENTS.md)
echo -e "${YELLOW}🤖 Documenting Agentic Personas...${NC}"
cat <<EOF > AGENTS.md
# 🤖 AEF Agent Registry
### *Defining the Roles, Responsibilities, and Logic Gates.*

The AEF operates on a **Distributed Intelligence** model. Each agent is a specialized "containerized" persona with unique system prompts and tool access.

---

## 🏗️ 1. The Architect (n8n + LiteLLM)
* **Role:** Intent Analysis & Prompt Re-Engineering.
* **Mission:** Take "Human-speak" and turn it into "Machine-spec."
* **Capabilities:** RAG Lookup (ChromaDB), Slack/Telegram Gateway, Spec Drafting.
* **Logic Gate:** If the user request is ambiguous, The Architect triggers a "Clarification Loop" back to the user instead of proceeding.

## 💻 2. The Lead Engineer (SWE-Agent)
* **Role:** Autonomous Code Generation & Unit Testing.
* **Mission:** Implement the Architect's spec within a sandboxed environment.
* **Capabilities:** File I/O, Terminal Execution, Local npm/python testing, Git PR creation.
* **Logic Gate:** Cannot push to 'main'. Must pass 100% of unit tests before opening a Pull Request.

## 🛡️ 3. Agent Zero (Python SRE)
* **Role:** Site Reliability & Hardware Orchestration.
* **Mission:** Manage the "Physical" layer and ensure service uptime.
* **Capabilities:** Proxmox API Bridge, Uptime Kuma Integration, Automated Reboots.
* **Logic Gate:** Only acts when a "Service Down" event is verified by two independent health checks.

---

## 🧠 Chain of Thought (CoT) Flow

1. **User:** "Build a secure login page."
2. **Architect:** "I found our security standard in ChromaDB. Engineering spec generated."
3. **Engineer:** "Writing React code. Test failed (CSS missing). Fixing... Tests passed. PR #402 opened."
4. **Agent Zero:** "PR merged. Provisioning Proxmox LXC. Service is LIVE."
EOF

# 7. WRITE THE PROFESSIONAL README.MD
echo -e "${YELLOW}📝 Generating Architectural Documentation...${NC}"
cat <<EOF > README.md
# 🤖 Autonomous Engineering Factory (AEF)
### *Agentic Infrastructure. Self-Healing Code. Zero-Trust Security.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Stack: n8n](https://img.shields.io/badge/Orchestrator-n8n-red.svg)](https://n8n.io)
[![Infrastructure: Proxmox](https://img.shields.io/badge/Infrastructure-Proxmox-orange.svg)](https://www.proxmox.com)

The **AEF** is a modular, event-driven ecosystem that transforms high-level intent into production-ready software. It utilizes a swarm of AI agents to handle the entire SDLC—from prompt re-engineering to hardware-level provisioning.

---

## 🌪️ Operational Workflow: Design, Write, Validate (DWV)

1. **Intent Capture:** Commands from **Slack/Telegram** are re-engineered into technical specs via **Agentic Prompting**.
2. **Autonomous Execution:** The **SWE-Agent** writes and tests code in a sandboxed environment, self-correcting until builds pass.
3. **Hardware Provisioning:** The factory interfaces with the **Proxmox API** to deploy resources via a **Zero-Trust Mesh** (Cloudflare + Tailscale).
4. **Self-Healing Sentry:** **Uptime Kuma** monitors deployments; **Agent Zero** performs automated recovery if failures occur.

---

## 💎 Architectural Pillars
* **Agentic RAG:** Persistent "Expert Memory" via ChromaDB & AnythingLLM.
* **Self-Healing CI/CD:** Automated hardware/software recovery with Prometheus/Grafana telemetry.
* **Zero-Trust Access:** Port-less remote management via Cloudflare Tunnels & Tailscale.
* **Unified LLM Gateway:** Hot-swappable model support via LiteLLM.

---

## 🚀 Installation & Setup

### 1. Bootstrap the Environment
\`\`\`bash
# Run this on a clean Proxmox VM (Ubuntu/Debian)
# Replace <repo-owner> with your GitHub username
curl -sSL https://raw.githubusercontent.com/<repo-owner>/Autonomous-Engineering-Factory/main/bootstrap.sh | bash
\`\`\`

### 2. Configure Secrets
Edit the \`.env\` file in the root directory and the Proxmox credentials in \`scripts/proxmox_bridge.py\`.

### 3. Launch the Factory
\`\`\`bash
docker compose up -d
\`\`\`

---

## 🛠️ Access Points
* **Orchestrator (n8n):** \`http://[VM-IP]:5678\`
* **Sentry Dashboard (Kuma):** \`http://[VM-IP]:3001\`
* **Remote Management (Guacamole):** \`http://[VM-IP]:8080\`
* **Telemetry (Grafana):** \`http://[VM-IP]:3000\`
* **Stack Management (Dockge):** \`http://[VM-IP]:5001\`
* **Knowledge Base UI (AnythingLLM):** \`http://[VM-IP]:3002\`
EOF

echo -e "${GREEN}🏁 RECONCILED AEF BUILD COMPLETE!${NC}"
echo -e "Next Step: Edit ${BLUE}~/factory/.env${NC} then run ${BLUE}docker compose up -d${NC}"
