# HestiaCP AI Automated Monitor

This directory contains the blueprint for building an automated, hourly AI monitoring system in [Dify](https://dify.ai/). 

Instead of waiting for you to ask questions, this workflow runs automatically on a schedule, connects to your server, runs a predefined set of diagnostic commands, analyzes the output using an LLM, and sends a Telegram alert **only** if something is wrong.

## Files Included

1. **`monitor-workflow.yml`**: The Dify Workflow DSL file. Import this into Dify to create the automated task. *All sensitive data has been removed.*
2. **`monitor-prompt.md`**: The strict system prompt used by the LLM. It defines exactly what commands to run (Disk, RAM, Services, Exim) and sets strict thresholds (e.g., "Only alert if disk is > 85%") to prevent false positive alerts.

## How it works

1. A cron trigger inside Dify starts the workflow every hour.
2. The workflow executes a batch of commands via SSH to gather server metrics:
   `hostname && nproc && uptime && df -h / /home /backup && free -m && v-list-sys-services json`
3. The LLM receives the raw output of these commands.
4. The LLM analyzes the data against the rules in `monitor-prompt.md`.
5. If everything is healthy, the workflow ends silently.
6. If an issue is detected (e.g., MariaDB is down, or Disk is at 90%), it formats an emergency HTML message and pushes it to your Telegram channel via a webhook.

## Setup Instructions

1. Go to your Dify instance.
2. Click **Create from DSL** and upload `monitor-workflow.yml`.
3. **CRITICAL: Configure your private data.** The imported workflow contains placeholder strings that you MUST replace with your actual server and bot details. Go through the workflow nodes (specifically the SSH execution nodes and Telegram HTTP request node) and replace:
   - `"YOUR_SERVER_IP_OR_DOMAIN"` -> Your actual server IP
   - `"YOUR_SSH_USERNAME"` -> Your SSH user (e.g., `root` or `dify_agent`)
   - `"YOUR_SSH_KEY_HERE"` -> Your actual private SSH key
   - `"YOUR_PASSWORD"` -> Your SSH password (if not using keys)
   - `"YOUR_TELEGRAM_BOT_TOKEN"` -> Your actual Telegram Bot API token
   - `"YOUR_TELEGRAM_CHAT_ID"` -> The ID of the Telegram chat/group where you want to receive alerts
4. Set the Cron trigger inside Dify to run every hour (or your preferred interval).
5. Publish the workflow.