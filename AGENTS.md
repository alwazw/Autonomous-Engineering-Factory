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
