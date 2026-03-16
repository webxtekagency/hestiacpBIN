require('dotenv').config();
const { Telegraf } = require('telegraf');
const axios = require('axios');

// 1. Strict Environment Variables Check (No Hardcoded Values)
const { TELEGRAM_BOT_TOKEN, DIFY_API_URL, DIFY_API_KEY } = process.env;
const IS_CHATFLOW = process.env.IS_CHATFLOW === 'true';

if (!TELEGRAM_BOT_TOKEN || !DIFY_API_URL || !DIFY_API_KEY) {
  console.error("❌ ERROR: Missing required environment variables!");
  console.error("Please ensure TELEGRAM_BOT_TOKEN, DIFY_API_URL, and DIFY_API_KEY are set in CapRover or your .env file.");
  process.exit(1);
}

// Helper to escape HTML special characters
function escapeHtml(text) {
  if (!text) return text;
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

// Helper to format text for Telegram HTML (Smarter & Cleaner)
function formatTelegramMessage(text) {
  if (!text) return "";

  const tableRegex = /((?:^\s*\|.*\|\s*$\r?\n?){2,})/gm;
  let textWithTables = text.replace(tableRegex, (match) => {
    if (match.includes('|-') || match.includes('|:')) {
      return "\n```\n" + match.trim() + "\n```\n";
    }
    return match;
  });

  const parts = textWithTables.split(/(```[\s\S]*?```|`[^`]+`)/g);

  return parts.map(part => {
    if (part.startsWith('```')) {
      let content = part.slice(3, -3); 
      return `<pre><code>${escapeHtml(content)}</code></pre>`;
    }
    
    if (part.startsWith('`')) {
      let content = part.slice(1, -1);
      return `<code>${escapeHtml(content)}</code>`;
    }

    let formatted = escapeHtml(part);

    formatted = formatted
      .replace(/^#{1,6}\s+/gm, '')
      // Restore blockquote support using HTML tag which Telegram supports
      .replace(/^>\s?(.*)$/gm, '<blockquote>$1</blockquote>')
      .replace(/\*\*([^\n*][\s\S]*?[^\n*])\*\*/g, '<b>$1</b>')
      .replace(/__([^\n_]+)__/g, '<b>$1</b>')
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')
      .replace(/^[-*] /gm, '• ');

    return formatted;
  }).join('');
}

// Helper to split and send long messages
async function sendLongMessage(ctx, text) {
  const MAX_LENGTH = 4000;
  
  // Helper to send safely
  const sendChunk = async (chunk) => {
    try {
      const html = formatTelegramMessage(chunk);
      await ctx.reply(html, { parse_mode: 'HTML', disable_web_page_preview: true });
    } catch (e) {
      console.warn("[WARN] HTML send failed, retrying plain text:", e.message);
      // Fallback: strip tags or just send raw
      await ctx.reply(chunk); 
    }
  };

  if (text.length <= MAX_LENGTH) {
    await sendChunk(text);
    return;
  }

  const chunks = [];
  let currentChunk = "";
  
  const lines = text.split('\n');
  for (const line of lines) {
    if ((currentChunk + line).length > MAX_LENGTH) {
        chunks.push(currentChunk);
        currentChunk = "";
    }
    currentChunk += line + "\n";
  }
  if (currentChunk) chunks.push(currentChunk);

  for (const chunk of chunks) {
    await sendChunk(chunk);
  }
}

// 2. Initialize Telegram Bot
const bot = new Telegraf(TELEGRAM_BOT_TOKEN);

const userConversations = {};

// 3. Setup Bot Commmands & Middleware
bot.start((ctx) => {
  const chatId = ctx.from.id;
  delete userConversations[chatId];
  ctx.reply("🤖 Hello! I am connected to the Dify DevOps System. How can I help you regarding your HestiaCP server today?");
});

// Help command
bot.help((ctx) => {
  ctx.reply("Send me any message or alert, and I will forward it to the AI DevOps Agent for analysis.");
});

  // Main message handler
bot.on('text', async (ctx) => {
  const chatId = ctx.from.id;
  const userText = ctx.message.text;
  const username = ctx.from.username || `user_${chatId}`;
  
  ctx.sendChatAction('typing');
  
  let statusMessageId = null;
  let currentThought = "🔄 Connecting to Agent...";
  let lastThought = "";

  try {
    const sentMsg = await ctx.reply(currentThought);
    statusMessageId = sentMsg.message_id;
  } catch (e) {
    console.error("Failed to send initial status message", e);
  }

  const typingInterval = setInterval(() => {
    ctx.sendChatAction('typing').catch(() => {});
  }, 4000);

  // Update status message every 1.5 seconds if changed (faster feedback)
  const statusUpdateInterval = setInterval(async () => {
    if (statusMessageId && currentThought !== lastThought) {
      lastThought = currentThought;
      try {
        await ctx.telegram.editMessageText(chatId, statusMessageId, null, currentThought);
      } catch (e) {
        // Ignore errors (e.g. message not modified or too frequent)
      }
    }
  }, 1500);

  try {
    // API Endpoint differs slightly between Agent and Chatflow/Workflow
    // Agent: /chat-messages
    // Workflow: /chat-messages (usually same for Chatflow apps, but response format differs)
    // Workflow (Pure): /workflows/run (we assume Chatflow App here)
    const targetUrl = `${DIFY_API_URL}/chat-messages`;
    
    console.log(`[DEBUG] Requesting Dify (Streaming Mode) at: ${targetUrl} | Mode: ${IS_CHATFLOW ? 'Chatflow' : 'Agent'}`);
    
    // We leave inputs empty because the user relies on hardcoded prompt values
    // for compatibility between Telegram and Dify Native Web Chat.
    const difyPayload = {
      inputs: {},
      query: userText,
      response_mode: "streaming",
      user: username
    };

    if (userConversations[chatId]) {
      difyPayload.conversation_id = userConversations[chatId];
    }

    const response = await axios.post(targetUrl, difyPayload, {
      headers: {
        'Authorization': `Bearer ${DIFY_API_KEY}`,
        'Content-Type': 'application/json'
      },
      responseType: 'stream',
      timeout: 1200000 // 20 minutes timeout to allow extremely long Agent executions (DeepSeek/GPT-4o)
    });

    let fullAnswer = "";
    let conversationId = "";
    let buffer = "";

    response.data.on('data', (chunk) => {
      buffer += chunk.toString();
      let lines = buffer.split('\n');
      // Keep the last line in the buffer as it might be incomplete
      buffer = lines.pop();

      for (const line of lines) {
        if (!line.trim() || !line.startsWith('data:')) continue;
        
        try {
          const data = JSON.parse(line.substring(5));
          
          // Capture agent thoughts/observations (Standard Agent Mode)
          if (!IS_CHATFLOW && data.event === 'agent_thought') {
            if (data.thought) {
              // Truncate thought to avoid huge messages and format beautifully
              const cleanThought = data.thought.replace(/\n/g, ' ').trim();
              const thoughtPreview = cleanThought.length > 100 ? cleanThought.substring(0, 100) + "..." : cleanThought;
              currentThought = `💭 Thinking: ${thoughtPreview}`;
            } else if (data.tool) {
               // Show tool usage clearly
               currentThought = `🛠️ Using tool: ${data.tool}...`;
            } else if (data.observation) {
               currentThought = `👀 Analyzing command result...`;
            }
          }
          
          // Capture Chatflow/Workflow node steps (Workflow Mode)
          if (IS_CHATFLOW && (data.event === 'node_started' || data.event === 'workflow_started')) {
            const nodeTitle = data.data?.title || data.data?.node_type || "Processing...";
            // Don't show "Start" or "Answer" nodes as they are boring
            if (nodeTitle !== 'Start' && nodeTitle !== 'Answer' && nodeTitle !== 'User Input') {
                currentThought = `⏳ Step: ${nodeTitle}...`;
            }
          }
          
          if (data.event === 'message' || data.event === 'agent_message' || data.event === 'text_chunk') {
            fullAnswer += data.answer || data.text || "";
          }
          if (data.conversation_id) {
            conversationId = data.conversation_id;
          }
          if (data.event === 'error') {
            console.error("[DIFY-STREAM-ERROR]", data.message);
          }
        } catch (e) {
          // Ignore partial JSON chunks
        }
      }
    });

    response.data.on('end', async () => {
      clearInterval(typingInterval);
      clearInterval(statusUpdateInterval);

      // Delete the status message before sending final answer
      if (statusMessageId) {
        try {
            await ctx.telegram.deleteMessage(chatId, statusMessageId);
        } catch (e) {
            console.error("Failed to delete status message", e);
        }
      }

      if (conversationId) userConversations[chatId] = conversationId;
      
      if (fullAnswer.trim()) {
        // Send final response
        await sendLongMessage(ctx, fullAnswer);
      } else {
        console.warn("[WARN] Dify stream ended with empty answer.");
        await ctx.reply("⚠️ Cloud Dify processed the request but returned an empty answer. Please check your IF/ELSE logic and Answer nodes.");
      }
    });

  } catch (error) {
    clearInterval(typingInterval);
    clearInterval(statusUpdateInterval);
    if (statusMessageId) {
        try { await ctx.telegram.deleteMessage(chatId, statusMessageId); } catch(e){}
    }
    
    // Enhanced Error Logging for Debugging
    if (error.response) {
        console.error(`[ERROR] Dify API Response Status:`, error.response.status);
        // Fix: error.response.data might be a stream in axios stream mode, or circular.
        // Try to read stream if possible, or just log safely.
        try {
           if (error.response.data && typeof error.response.data.read === 'function') {
               // It's a stream, try to read it
               error.response.data.on('data', d => console.error(`[ERROR BODY]: ${d.toString()}`));
           } else {
               // It's likely an object or string
               console.error(`[ERROR] Dify API Response Data:`, JSON.stringify(error.response.data));
           }
        } catch(serializationError) {
           console.error(`[ERROR] Could not serialize response data:`, serializationError.message);
        }
    } else {
        console.error(`[ERROR] Dify API Failure:`, error.message);
    }
    
    await ctx.reply("❌ Sorry, I couldn't reach the AI brain. Check the logs for the specific error details.");
  }
});

// 4. Start the Bot
bot.launch().then(() => {
  console.log("🚀 Telegram-Dify Node.js Bridge is running!");
});

// Enable graceful stop
process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));
