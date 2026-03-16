# HestiaCP AI Integration Blueprints

This directory contains everything you need to supercharge your HestiaCP server with Large Language Models (LLMs) using [Dify](https://dify.ai/). 

Depending on your needs, you can build a completely automated monitoring system, an interactive Sysadmin assistant, or both.

## 🏗️ Architecture & What to Choose

### Option 1: The Automated Monitor (`/monitor`)
**Goal:** You want the AI to check your server every hour and send you a Telegram message **only if something is broken** (e.g., Disk > 85%, MariaDB crashed).
- **How it works:** A scheduled workflow inside Dify connects via SSH, runs diagnostic commands, analyzes the output, and pushes an alert directly to Telegram via a Webhook.
- **Do I need a server script?** **No.** This runs entirely inside Dify. You just import the template and configure your SSH keys.
- **Go to:** [`/monitor/README.md`](monitor/README.md) for setup instructions.

### Option 2: The Interactive Agent (`/agent` + `/telegram-bridge`)
**Goal:** You want to be able to open Telegram, type *"Hey, why is the server slow today?"* or *"Create a database for user X"*, and have the AI act as your personal Sysadmin.
- **How it works:** You need two pieces for this to work perfectly:
  1. **The Brain (`/agent`):** The Dify Chatflow template that contains the LLM prompt, the SSH tools, and the logic.
  2. **The Mouth (`/telegram-bridge`):** A small Node.js script that you run on your server. It listens to your messages on Telegram, sends them to Dify's API, formats the markdown into Telegram HTML, and maintains the conversation history.
- **Do I need a server script?** **Yes.** You must run the `telegram-bridge` using PM2/Node.js so you can talk to the agent.
- **Go to:** 
  1. First, setup the Brain: [`/agent/README.md`](agent/README.md)
  2. Then, setup the Bridge: [`/telegram-bridge/README.md`](telegram-bridge/README.md)

### Option 3: The Brain Boost (`/knowledge`)
**Goal:** You want your Agent to be a true HestiaCP expert, not just a generic Linux admin.
- **How it works:** This is a collection of Markdown files containing HestiaCP CLI commands, advanced PHP-FPM tuning, and Exim troubleshooting guides.
- **Where to use it:** You upload these files into Dify's "Knowledge" section and link them to your Agent.
- **Go to:** [`/knowledge/`](knowledge/) to see the files.

---

## 🔒 Security Best Practices

Before you start, please follow these rules to ensure your server remains secure:

1. **Never use `root` for the AI:** The templates default to `root` for simplicity, but in a production environment, you should create a dedicated sudo user (e.g., `dify_agent`). This ensures all AI actions are clearly logged in `/var/log/auth.log` under that specific user.
2. **Use SSH Keys, not Passwords:** Dify supports SSH keys. Generate a unique ED25519 or RSA key pair exclusively for the AI Agent. Never reuse your personal SSH key.
3. **Restrict the Telegram Bot:** If you use the Interactive Agent, ensure your Telegram Bot is not accessible by the public. (The `telegram-bridge` script can be configured to only reply to your specific Telegram Chat ID).