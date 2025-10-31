/**
 * Telegram Bot integration
 */

const express = require('express');
const axios = require('axios');
const logger = require('../utils/logger');
const router = express.Router();

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_API_URL = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}`;
const RASA_SERVER_URL = process.env.RASA_SERVER_URL || 'http://localhost:5005';

// Store sessions per Telegram chat ID
const telegramSessions = new Map();

/**
 * POST /api/telegram/webhook
 * Handle incoming Telegram messages
 */
router.post('/webhook', async (req, res) => {
  try {
    const { message, callback_query } = req.body;

    // Handle callback queries (button clicks)
    if (callback_query) {
      const chatId = callback_query.message.chat.id;
      const data = callback_query.data;
      
      // Process callback data
      await handleTelegramCallback(chatId, data, callback_query.from);
      
      // Answer callback query
      await axios.post(`${TELEGRAM_API_URL}/answerCallbackQuery`, {
        callback_query_id: callback_query.id
      });
      
      return res.status(200).send('OK');
    }

    // Handle regular messages
    if (!message || !message.text) {
      return res.status(200).send('OK');
    }

    const chatId = message.chat.id;
    const userId = message.from.id;
    const userText = message.text;
    const sessionId = `telegram_${chatId}`;

    // Get or create session
    if (!telegramSessions.has(sessionId)) {
      telegramSessions.set(sessionId, {
        chatId,
        userId,
        history: [],
        metadata: {
          username: message.from.username,
          first_name: message.from.first_name
        }
      });
    }

    // Forward to Rasa
    try {
      const rasaResponse = await axios.post(
        `${RASA_SERVER_URL}/webhooks/rest/webhook`,
        {
          sender: sessionId,
          message: userText,
          metadata: {
            channel: 'telegram',
            language: 'en',
            telegram_user_id: userId,
            telegram_username: message.from.username
          }
        }
      );

      const botText = rasaResponse.data && rasaResponse.data.length > 0
        ? rasaResponse.data[0].text
        : "I'm sorry, I didn't understand that.";

      // Send response back to Telegram
      await sendTelegramMessage(chatId, botText);

      // Store in session
      const session = telegramSessions.get(sessionId);
      session.history.push({
        timestamp: new Date(),
        user: userText,
        bot: botText
      });

    } catch (error) {
      logger.error('Error processing Telegram message', { chatId, error: error.message });
      await sendTelegramMessage(
        chatId,
        "I'm experiencing technical difficulties. Please try again later."
      );
    }

    res.status(200).send('OK');

  } catch (error) {
    logger.error('Telegram webhook error', { error: error.message });
    res.status(200).send('OK'); // Always return 200 to Telegram
  }
});

/**
 * GET /api/telegram/webhook
 * Telegram webhook verification
 */
router.get('/webhook', (req, res) => {
  res.send('Telegram webhook is active');
});

/**
 * Send message to Telegram user
 */
async function sendTelegramMessage(chatId, text, options = {}) {
  try {
    const payload = {
      chat_id: chatId,
      text: text,
      parse_mode: 'Markdown',
      ...options
    };

    await axios.post(`${TELEGRAM_API_URL}/sendMessage`, payload);
  } catch (error) {
      logger.error('Error sending Telegram message', { chatId, error: error.response?.data || error.message });
    throw error;
  }
}

/**
 * Handle Telegram callback queries (button clicks)
 */
async function handleTelegramCallback(chatId, data, user) {
  const sessionId = `telegram_${chatId}`;
  
  // Process callback data as a message to Rasa
  try {
    const rasaResponse = await axios.post(
      `${RASA_SERVER_URL}/webhooks/rest/webhook`,
      {
        sender: sessionId,
        message: data,
        metadata: {
          channel: 'telegram',
          is_callback: true
        }
      }
    );

    const botText = rasaResponse.data && rasaResponse.data.length > 0
      ? rasaResponse.data[0].text
      : "Thank you!";

    await sendTelegramMessage(chatId, botText);

  } catch (error) {
    logger.error('Error handling callback', { error: error.message });
  }
}

/**
 * Send message with inline keyboard
 */
async function sendMessageWithKeyboard(chatId, text, buttons) {
  const keyboard = {
    inline_keyboard: buttons.map(row => 
      row.map(btn => ({
        text: btn.text,
        callback_data: btn.data
      }))
    )
  };

  await sendTelegramMessage(chatId, text, {
    reply_markup: keyboard
  });
}

module.exports = router;

