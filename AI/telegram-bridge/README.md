# Telegram ↔ Dify API Bridge

This directory contains a lightweight Node.js script that acts as a bridge between a **Telegram Bot** and your **Dify AI Agent**.

While Dify has native tool connections, passing messages back and forth from Telegram with correct HTML formatting, markdown conversion, and state management is much better handled by a dedicated bridge script.

## Features
- **Markdown to HTML Conversion:** Dify outputs Markdown, but Telegram requires specific HTML formatting. This script handles the conversion seamlessly.
- **Table Parsing:** Converts Markdown tables from the LLM into readable Telegram code blocks.
- **Session Management:** Keeps track of the `conversation_id` so the AI remembers the context of your chat.
- **Error Handling:** Gracefully catches API timeouts or SSH errors and reports them back to Telegram.

## Prerequisites
- Node.js (v16 or higher)
- NPM or Yarn
- A Telegram Bot Token (from [@BotFather](https://t.me/botfather))
- A Dify API Key (from your Dify Agent's "API Access" menu)

---

## 🚀 Setup Instructions

### 1. Installation
Clone or copy this directory to your server (you can run this on the HestiaCP server itself or a separate VPS).

```bash
cd /root/hestiacp-useful-tools/AI/telegram-bridge
npm install
```

### 2. Configuration
Copy the example environment file:
```bash
cp .env.example .env
```

Edit the `.env` file (`nano .env`) and fill in your details:
```ini
# Get this from @BotFather on Telegram
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Usually https://api.dify.ai/v1 if using the cloud version, or your self-hosted URL
DIFY_API_URL=https://api.dify.ai/v1

# Get this from Dify -> Your Agent -> API Access -> API Key
DIFY_API_KEY=your_dify_api_key_here

# Set to true if your Dify app is a "Chatflow" or "Agent". Set to false if it's a basic workflow.
IS_CHATFLOW=true
```

### 3. Running the Bot

**For testing (development mode):**
```bash
node index.js
```
Send a message to your Telegram bot. You should see logs in the console, and the bot should reply.

**For production (using PM2):**
To keep the bot running 24/7 even if the server restarts, use PM2:
```bash
# Install PM2 globally if you don't have it
npm install -g pm2

# Start the bot
pm2 start index.js --name "dify-telegram-bridge"

# Save the PM2 process list so it starts on boot
pm2 save
pm2 startup
```

## How to use it
Once running, simply open your Telegram Bot and type a message like:
> "Check the server load" or "How much disk space do I have left?"

The bridge will forward this to Dify, Dify will use the SSH tool to check the server, and the bridge will format the answer beautifully in Telegram.