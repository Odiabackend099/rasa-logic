/**
 * WhatsApp Business API integration
 * Supports WhatsApp Cloud API
 */

const express = require('express');
const axios = require('axios');
const logger = require('../utils/logger');
const router = express.Router();

const WHATSAPP_PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID || '';
const WHATSAPP_ACCESS_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN || '';
const WHATSAPP_API_URL = `https://graph.facebook.com/v18.0/${WHATSAPP_PHONE_NUMBER_ID}`;
const WHATSAPP_VERIFY_TOKEN = process.env.WHATSAPP_VERIFY_TOKEN || 'callwaitingai_verify_token';
const RASA_SERVER_URL = process.env.RASA_SERVER_URL || 'http://localhost:5005';

// Store sessions per WhatsApp number
const whatsappSessions = new Map();

/**
 * GET /api/whatsapp/webhook
 * WhatsApp webhook verification
 */
router.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === WHATSAPP_VERIFY_TOKEN) {
    logger.info('WhatsApp webhook verified');
    res.status(200).send(challenge);
  } else {
    res.status(403).send('Forbidden');
  }
});

/**
 * POST /api/whatsapp/webhook
 * Handle incoming WhatsApp messages
 */
router.post('/webhook', async (req, res) => {
  try {
    const body = req.body;

    // WhatsApp sends webhook data in entry array
    if (body.object === 'whatsapp_business_account') {
      for (const entry of body.entry || []) {
        for (const change of entry.changes || []) {
          const value = change.value;

          // Handle messages
          if (value.messages) {
            for (const message of value.messages) {
              await handleWhatsAppMessage(message, value.metadata);
            }
          }

          // Handle status updates (delivered, read, sent)
          if (value.statuses) {
            for (const status of value.statuses) {
              logger.debug('WhatsApp status update', { status, messageId });
              // TODO: Log status updates to database
            }
          }
        }
      }
    }

    res.status(200).send('OK');

  } catch (error) {
    logger.error('WhatsApp webhook error', { error: error.message });
    res.status(200).send('OK'); // Always return 200 to WhatsApp
  }
});

/**
 * Handle incoming WhatsApp message
 */
async function handleWhatsAppMessage(message, metadata) {
  const from = message.from;
  const messageText = message.text?.body || '';
  const messageId = message.id;
  const sessionId = `whatsapp_${from}`;

  if (!messageText) {
    // Handle media messages, etc.
    return;
  }

  // Get or create session
  if (!whatsappSessions.has(sessionId)) {
    whatsappSessions.set(sessionId, {
      phoneNumber: from,
      history: [],
      metadata: {
        phone_number_id: metadata.phone_number_id
      }
    });
  }

  // Forward to Rasa
  try {
    const rasaResponse = await axios.post(
      `${RASA_SERVER_URL}/webhooks/rest/webhook`,
      {
        sender: sessionId,
        message: messageText,
        metadata: {
          channel: 'whatsapp',
          language: 'en',
          whatsapp_phone: from
        }
      }
    );

    const botText = rasaResponse.data && rasaResponse.data.length > 0
      ? rasaResponse.data[0].text
      : "I'm sorry, I didn't understand that.";

    // Send response back to WhatsApp
    await sendWhatsAppMessage(from, botText);

    // Store in session
    const session = whatsappSessions.get(sessionId);
    session.history.push({
      timestamp: new Date(),
      user: messageText,
      bot: botText
    });

  } catch (error) {
      logger.error('Error processing WhatsApp message', { from, error: error.message });
    await sendWhatsAppMessage(
      from,
      "I'm experiencing technical difficulties. Please try again later."
    );
  }
}

/**
 * Send message to WhatsApp user
 */
async function sendWhatsAppMessage(to, text) {
  try {
    const response = await axios.post(
      `${WHATSAPP_API_URL}/messages`,
      {
        messaging_product: 'whatsapp',
        to: to,
        type: 'text',
        text: {
          body: text
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${WHATSAPP_ACCESS_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data;
  } catch (error) {
      logger.error('Error sending WhatsApp message', { to, error: error.response?.data || error.message });
    throw error;
  }
}

/**
 * Send message with quick replies
 */
async function sendMessageWithQuickReplies(to, text, quickReplies) {
  try {
    const response = await axios.post(
      `${WHATSAPP_API_URL}/messages`,
      {
        messaging_product: 'whatsapp',
        to: to,
        type: 'text',
        text: {
          body: text
        },
        interactive: {
          type: 'button',
          body: {
            text: text
          },
          action: {
            buttons: quickReplies.map((reply, index) => ({
              type: 'reply',
              reply: {
                id: `btn_${index}`,
                title: reply
              }
            }))
          }
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${WHATSAPP_ACCESS_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data;
  } catch (error) {
      logger.error('Error sending WhatsApp quick replies', { to, error: error.response?.data || error.message });
    throw error;
  }
}

module.exports = router;

