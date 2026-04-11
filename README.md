# HestiaCP Useful Tools Collection

A curated collection of production-grade scripts, optimization guides, and **platform-agnostic AI prompt blueprints** for HestiaCP + Debian/Ubuntu servers.

Built and battle-tested for real production environments. A contribution to the HestiaCP community — thank you to the team for your continuous work!

---

## 📂 Repository Structure

### 1. 📖 Guides & Optimizations

Step-by-step guides to optimize your server infrastructure.

- **[PHP-FPM Optimization Guide](php_optimize/):** Calculate RAM limits and choose between `ondemand`, `dynamic`, and `static` PHP modes based on server size and traffic.
- **[MariaDB Optimization Guide](mariadb_optimize/):** Configure `innodb_buffer_pool_size` to dramatically improve database performance and reduce CPU load.
- **[SWAP Setup Guide](swap_setup/):** 1-click script to configure SWAP memory, essential for low-RAM environments (1GB/2GB VPS).

---

### 2. 🤖 AI Integration Blueprints (`/AI`)

**Platform-agnostic** system prompt blueprints and knowledge bases to integrate LLMs with your HestiaCP server. No dependency on Dify, n8n, or any specific platform — inject these prompts directly into any LLM provider (OpenAI, Anthropic, Google, OpenRouter, etc.) via `systemPrompt`.

#### Cognitive Architecture (April 2026)

The AI prompts in this repository follow a **3-module Cognitive OS** structure inspired by the [Nuwa.skill](https://github.com/alchaincyf/zhangxuefeng-skill) methodology and the [Agent Skills](https://github.com/anthropics/skills) standard:

```
<decision_heuristics>  — Operational reasoning rules
<expression_dna>       — Tone, syntax, and output format
<internal_tensions>    — Ethical and technical constraints to force critical thinking
```

This structure shifts LLM agents from generic "helpful assistants" to **specialized cognitive profiles** with deterministic, institutional-grade behavior.

#### Available Prompts ([`/AI/DevOps-AI-Prompts`](AI/DevOps-AI-Prompts/))

- **[DevOps Agent](AI/DevOps-AI-Prompts/DevOps-Agent-Prompt.md):** A senior DevOps engineer persona with SSH root access. Enforces "look before you leap" heuristics, mandatory pre-flight checks (`nginx -t` before restart), and balances root power against operational safety. Responds in the user's language.
- **[System Monitor](AI/DevOps-AI-Prompts/System-Monitor-Prompt.md):** A cold, clinical health-check agent. Runs scheduled server audits, grades severity objectively (HEALTHY / DEGRADED / CRITICAL), and suppresses alerts when no human action is required.

#### Knowledge Base ([`/AI/knowledge`](AI/knowledge/))

Curated Markdown files covering HestiaCP CLI commands, PHP-FPM tuning, Exim troubleshooting, Nginx configuration, and more. Designed to be used as a RAG knowledge base for any LLM agent.

---

### 3. ⚙️ Custom Scripts (`/scripts`)

Automation and maintenance scripts to enhance HestiaCP's default capabilities.

#### [System Cleanup (`v-clean-garbage`)](scripts/clean-garbage/)
- Cleans old system logs (Journalctl), rotated logs, and temp files.
- Manages mail queue and spam retention.
- Configuration-driven toggles per task.

#### [Custom Backup Wrapper (`v-backup-users-custom`)](scripts/backup-users-custom/)
- **Symlink Support:** Patches core scripts to handle backups to symlinked locations (e.g., rclone mounts).
- **Smart Retention:** Keeps only one backup per user from previous months.
- **Version Guard:** Patches only applied on validated HestiaCP versions.

#### [GitHub Mirror (`v-github-mirror`)](scripts/github-mirror/)
- Automates mirroring of git repositories to your server.
- Supports private repositories via SSH.
- **Smart Retention** (Daily/Weekly/Monthly) for versioned backup history.

#### [Exim Limit Monitor (`v-add-exim-limit`)](scripts/exim-limit/)
- Blocks outgoing emails larger than 10MB to protect IP reputation.
- Sends rejection messages to users with alternatives.
- Notifies the admin on every block event.

#### [System Health Report (`v-system-report`)](scripts/system-report/)
- Checks CPU, RAM, Disk, and Load averages.
- Monitors all HestiaCP services (Nginx, Apache, PHP-FPM, MySQL, Exim, etc.).
- Checks SSL expiry, email blacklists, and database errors.
- Sends a detailed HTML report to the admin.

---

## 🚀 Installation

```bash
git clone git@github.com:webxtekstudio/hestiacp-useful-tools.git /root/hestiacp-useful-tools
cd /root/hestiacp-useful-tools
bash install.sh
```

Each tool has its own directory with a `README.md` and a `.conf.sample` file. Configuration files in `/etc/` are never committed to this repository.

---

## ⚠️ Disclaimer

These scripts are provided "as is". While used in production, review and test in your environment before deployment.
