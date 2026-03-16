# HestiaCP Useful Tools Collection

This repository contains a curated collection of custom scripts, tools, and optimization guides designed for production HestiaCP systems. 

A personal contribution to the HestiaCP community — designed to help sysadmins, agencies, and developers squeeze the maximum performance and stability out of their servers. Thank you to the HestiaCP team for your continuous hard work!

## 📂 Repository Structure

The repository is divided into two main categories:

### 1. 📖 Guides & Optimizations
Detailed, step-by-step guides to optimize your server.
*   **[PHP-FPM Optimization Guide](php_optimize/)**: A comprehensive guide on how to calculate RAM limits and choose between `ondemand`, `dynamic`, and `static` PHP modes based on your server size and traffic.
*   **[MariaDB Optimization Guide](mariadb_optimize/)**: Step-by-step guide to calculating and configuring `innodb_buffer_pool_size` to dramatically improve database performance and reduce CPU load.
*   **[SWAP Setup Guide](swap_setup/)**: A quick 1-click script and explanation on how to configure SWAP memory for HestiaCP servers, essential for low-RAM environments (1GB/2GB).

### 2. 🤖 AI Integration Blueprints (`/AI`)
Ready-to-use templates to integrate your HestiaCP server with Large Language Models using Dify. See the [AI Architecture Guide](AI/README.md) for details.
*   **[Interactive AI Agent](AI/agent/)**: A Dify Chatflow template and prompt to create a Telegram bot that acts as your personal Linux Sysadmin.
*   **[Telegram ↔ Dify Bridge](AI/telegram-bridge/)**: A lightweight Node.js script required to format LLM markdown into beautiful Telegram HTML and maintain chat sessions.
*   **[Automated AI Monitor](AI/monitor/)**: A Dify Workflow template and strict prompt to run scheduled (cron) health checks on your server and send Telegram alerts *only* when human intervention is actually needed.
*   **[HestiaCP Knowledge Base](AI/knowledge/)**: A collection of highly curated Markdown files covering HestiaCP CLI commands, PHP tuning, Exim troubleshooting, and more. Designed to be uploaded into Dify's Knowledge module to give your Agent deep, specialized context.

### 3. ⚙️ Custom Scripts (`/scripts`)
Automation and maintenance scripts to enhance HestiaCP's default capabilities.

#### [System Cleanup (v-clean-garbage)](scripts/clean-garbage/)
A comprehensive cleanup script to maintain server health.
- Cleans old system logs (Journalctl), rotated logs, and temp files.
- Manages mail queue and spam retention.
- Configuration-driven toggles per task.

#### [Custom Backup Wrapper (v-backup-users-custom)](scripts/backup-users-custom/)
Enhances the default HestiaCP backup system.
- **Symlink Support:** Patches core scripts to handle backups to symlinked locations (e.g., rclone mounts).
- **Smart Retention:** Option to keep only one backup per user from previous months.
- **Version Guard:** Patches only applied on validated HestiaCP versions (safe on upgrades).

#### [GitHub Mirror (v-github-mirror)](scripts/github-mirror/)
Automates mirroring of git repositories to your server.
- Perfect for backing up source code of static sites or web apps.
- Supports private repositories via SSH.
- **Smart Retention** (Daily/Weekly/Monthly) for versioned backup history.

#### [Exim Limit Monitor (v-add-exim-limit)](scripts/exim-limit/)
Protects your server's IP reputation.
- Blocks outgoing emails larger than 10MB.
- Sends rejection messages to users with alternatives.
- Notifies the admin when a block occurs.

#### [System Health Report (v-system-report)](scripts/system-report/)
Daily health check for your server.
- Checks CPU, RAM, Disk, Load averages.
- Monitors all HestiaCP services (Nginx, Apache, PHP-FPM, MySQL, Exim, etc.).
- Checks SSL expiry, email blacklists, and database errors.
- Sends a detailed HTML report to the admin.

## 🚀 Installation

```bash
git clone git@github.com:webxtekagency/hestiacp-useful-tools.git /root/hestiacp-useful-tools
cd /root/hestiacp-useful-tools
bash install.sh
```

Each tool has its own directory with a `README.md` and a `.conf.sample` file. Configuration files in `/etc/` are **never committed** to this repository.

## 📋 Changelog

### v1.0 — 2026-03-15
- **Initial Release:** Created the `hestiacp-useful-tools` repository.
- **Features Included:** 
  - Comprehensive PHP-FPM, MariaDB, and SWAP optimization guides.
  - Complete AI Integration Blueprints (`/AI/`) with Dify templates, Node.js Telegram bridge, and specialized Agent prompts.
  - Custom automated bash scripts for backups (`v-backup-users-custom`), GitHub mirroring (`v-github-mirror`), system reporting (`v-system-report`), cleanup (`v-clean-garbage`), and Exim limiting (`v-add-exim-limit`).

## ⚠️ Disclaimer

These scripts are provided "as is". While used in production, please review and test in your environment before deployment.
