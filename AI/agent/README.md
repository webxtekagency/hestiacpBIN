# HestiaCP DevOps AI Agent

This directory contains the blueprint for building an interactive AI Agent in [Dify](https://dify.ai/) that acts as a Senior Linux Sysadmin directly inside Telegram.

Unlike a simple script, this Agent can execute commands via SSH, read server logs, troubleshoot errors, and maintain a conversation context to help you manage your HestiaCP server.

## Files Included

1. **`HestiaCP-DevOps-CHATFLOW.yml`**: The Dify Chatflow DSL file. You can import this directly into Dify to instantly create the agent structure, complete with SSH tool connections and the conversational flow. *All sensitive data (IPs, keys, tokens) has been removed and must be configured inside Dify after import.*
2. **`agent-prompt.md`**: The system prompt (the "brain" and rules) used by the LLM. It defines strict rules to prevent hallucinations, forces safe command execution, and limits response lengths.
3. **`../knowledge/` (Knowledge Base)**: A folder containing markdown files with advanced HestiaCP documentation (PHP tuning, Exim troubleshooting, CLI reference). You should upload these files into a Dify Knowledge Base and link it to your Agent so it knows exactly how to fix HestiaCP-specific problems.

## Security Recommendation: Dedicated SSH User

By default, the template might suggest using `root`. However, **for production security and audit logs**, we strongly recommend creating a dedicated sudo user for the AI agent (e.g., `dify-agent` or `monitor-bot`).

Using a dedicated user ensures that every command executed by the AI is logged under that specific user in `/var/log/auth.log` and `/var/log/syslog`, making it easy to distinguish human actions from AI actions.

### How to create a dedicated user with safe sudo privileges:

1. Create the new user and add it to the sudo group:
```bash
adduser dify-agent
usermod -aG sudo dify-agent
```

2. Grant passwordless sudo access so the Agent doesn't get stuck asking for passwords (the Agent prompts are already configured to use `sudo -n`):
```bash
echo 'dify-agent ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/dify-agent
chmod 440 /etc/sudoers.d/dify-agent
```
*Note: Even if you decide to go back to using the `root` user later, the `sudo -n` commands in the prompts will still work perfectly (root doesn't need a password for sudo).*

## How it works

1. You send a message via Telegram (e.g., *"Why is my server slow?"* or *"Create a new database for user John"*).
2. The Dify workflow receives the message.
3. The LLM processes your request based on the rules in `agent-prompt.md`.
4. If it needs to check the server, it automatically triggers an SSH tool to run commands (e.g., `uptime` or `top`).
5. It reads the SSH output and replies to you in Telegram with a human-readable, formatted answer.

## Setup Instructions

1. Go to your Dify instance.
2. Click **Create from DSL** and upload `HestiaCP-DevOps-CHATFLOW.yml`.
3. **CRITICAL: Configure your private data.** The imported workflow contains placeholder strings that you MUST replace with your actual server and bot details. Go through the Agent's nodes (specifically the SSH tools and HTTP request nodes) and replace:
   - `"YOUR_SERVER_IP"` -> Your actual server IP
   - `"YOUR_SSH_USERNAME"` -> Your SSH user (e.g., `root` or `dify_agent`)
   - `"YOUR_SSH_PASSWORD"` -> Your SSH password (if not using keys)
4. Publish the workflow and connect it to your Telegram Bot.

### 2. Configure SSH Key
1. Generate an SSH key on your HestiaCP server specifically for the Agent. 
   **CRITICAL:** Dify is very strict with modern key formats. You MUST generate a Classic RSA key in PEM format, otherwise Dify will throw an `invalid private key` error:
   ```bash
   ssh-keygen -m PEM -t rsa -b 4096 -C "dify_ai_agent" -f ~/.ssh/id_rsa_dify -N ""
   ```
2. In Dify, go to the **Tools** section.
3. Search for the **SSH** tool and authorize it.
4. Fill in your server's details (IP, Port `22`, Username `root` or `ai-agent`).
5. Paste the content of your newly generated Private Key (`id_rsa_dify`).