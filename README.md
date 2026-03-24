# 🤖 Autonomous Engineering Factory (AEF) v2
### *Agentic Infrastructure. Self-Healing Code. Zero-Trust Security.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Stack: n8n](https://img.shields.io/badge/Orchestrator-n8n-red.svg)](https://n8n.io)
[![Infrastructure: Proxmox](https://img.shields.io/badge/Infrastructure-Proxmox-orange.svg)](https://www.proxmox.com)

The **AEF v2** is a modular, event-driven ecosystem that transforms high-level intent into production-ready software. It utilizes a swarm of AI agents to handle the entire SDLC—from prompt re-engineering to hardware-level provisioning.

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
```bash
# Run this on a clean Proxmox VM (Ubuntu/Debian)
curl -sSL https://raw.githubusercontent.com/<repo-owner>/Autonomous-Engineering-Factory/v2/bootstrap.sh | bash
```

### 2. Configure Secrets
Edit the `.env` file in the root directory and the Proxmox credentials in `scripts/proxmox_bridge.py`.

### 3. Launch the Factory
```bash
docker compose up -d
```

---

## 🛠️ Access Points
* **Orchestrator (n8n):** `http://[VM-IP]:5678`
* **Sentry Dashboard (Kuma):** `http://[VM-IP]:3001`
* **Remote Management (Guacamole):** `http://[VM-IP]:8080`
* **Telemetry (Grafana):** `http://[VM-IP]:3000`
* **Stack Management (Dockge):** `http://[VM-IP]:5001`
* **Knowledge Base UI (AnythingLLM):** `http://[VM-IP]:3002`
* **Database Manager (DbGate):** `http://[VM-IP]:3003`
