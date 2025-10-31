/**
 * CallWaitingAI Backend API Server
 * Express server that integrates with Rasa Open Source for conversational AI
 */

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const twilioRoutes = require('./routes/twilio');
const telegramRoutes = require('./routes/telegram');
const whatsappRoutes = require('./routes/whatsapp');
const webRoutes = require('./routes/web');
const analyticsRoutes = require('./routes/analytics');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const RASA_SERVER_URL = process.env.RASA_SERVER_URL || 'http://localhost:5005';

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.use('/api/twilio', twilioRoutes);
app.use('/api/telegram', telegramRoutes);
app.use('/api/whatsapp', whatsappRoutes);
app.use('/api/web', webRoutes);
app.use('/api/analytics', analyticsRoutes);

// In-memory session store (replace with Redis in production)
const sessions = new Map();

/**
 * Generate or retrieve session ID
 */
function getOrCreateSession(sessionId) {
  if (!sessionId || !sessions.has(sessionId)) {
    const newSessionId = sessionId || uuidv4();
    sessions.set(newSessionId, {
      id: newSessionId,
      createdAt: new Date(),
      history: [],
      metadata: {}
    });
    return newSessionId;
  }
  return sessionId;
}

/**
 * POST /api/chat
 * Handle chat messages and forward to Rasa
 */
app.post('/api/chat', async (req, res) => {
  try {
    const { message, session_id, language, channel = 'web' } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    const sessionId = getOrCreateSession(session_id);
    const session = sessions.get(sessionId);

    // Add metadata
    if (language) session.metadata.language = language;
    if (channel) session.metadata.channel = channel;

    // Forward to Rasa
    const rasaResponse = await axios.post(
      `${RASA_SERVER_URL}/webhooks/rest/webhook`,
      {
        sender: sessionId,
        message: message,
        metadata: {
          language: language || 'en',
          channel: channel
        }
      },
      {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000 // 30 second timeout
      }
    );

    // Extract response
    const botResponse = rasaResponse.data && rasaResponse.data.length > 0
      ? rasaResponse.data[0].text
      : "I'm sorry, I didn't understand that.";

    // Store in session history
    session.history.push({
      timestamp: new Date(),
      user: message,
      bot: botResponse
    });

    logger.info(`Chat processed: ${sessionId}`, {
      message,
      response: botResponse,
      channel
    });

    res.json({
      session_id: sessionId,
      text: botResponse,
      intent: rasaResponse.data?.[0]?.intent || null,
      confidence: rasaResponse.data?.[0]?.confidence || null
    });

  } catch (error) {
    logger.error('Error processing chat:', error);
    const errorMessage = error.response?.data?.message || error.message || 'Unknown error';
    const statusCode = error.response?.status || 500;
    res.status(statusCode).json({
      error: 'Failed to process message',
      message: errorMessage,
      details: error.code === 'ECONNREFUSED' ? 'Rasa server may still be starting. Please wait 30-60 seconds and try again.' : undefined
    });
  }
});

/**
 * POST /api/voice
 * Handle voice messages (STT text) and forward to Rasa
 */
app.post('/api/voice', async (req, res) => {
  try {
    const { audio_text, session_id, language, channel = 'twilio' } = req.body;

    if (!audio_text) {
      return res.status(400).json({ error: 'audio_text is required' });
    }

    const sessionId = getOrCreateSession(session_id);
    const session = sessions.get(sessionId);

    // Add metadata
    if (language) session.metadata.language = language;
    session.metadata.channel = channel;

    // Forward to Rasa
    const rasaResponse = await axios.post(
      `${RASA_SERVER_URL}/webhooks/rest/webhook`,
      {
        sender: sessionId,
        message: audio_text,
        metadata: {
          language: language || 'en',
          channel: channel,
          is_voice: true
        }
      }
    );

    const botResponse = rasaResponse.data && rasaResponse.data.length > 0
      ? rasaResponse.data[0].text
      : "I'm sorry, I didn't understand that.";

    // Store in session history
    session.history.push({
      timestamp: new Date(),
      user: audio_text,
      bot: botResponse,
      type: 'voice'
    });

    logger.info(`Voice processed: ${sessionId}`, {
      audio_text,
      response: botResponse,
      channel
    });

    res.json({
      session_id: sessionId,
      text: botResponse,
      intent: rasaResponse.data?.[0]?.intent || null,
      confidence: rasaResponse.data?.[0]?.confidence || null,
      // TTS audio URL would be generated here if needed
      // audio_url: await generateTTS(botResponse, language)
    });

  } catch (error) {
    logger.error('Error processing voice:', error);
    res.status(500).json({
      error: 'Failed to process voice message',
      message: error.message
    });
  }
});

/**
 * GET /api/session/:sessionId
 * Get conversation history for a session
 */
app.get('/api/session/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  const session = sessions.get(sessionId);

  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }

  res.json({
    session_id: sessionId,
    created_at: session.createdAt,
    history: session.history,
    metadata: session.metadata
  });
});

/**
 * POST /api/handoff
 * Trigger human agent handoff
 */
app.post('/api/handoff', async (req, res) => {
  try {
    const { session_id, reason } = req.body;

    if (!session_id) {
      return res.status(400).json({ error: 'session_id is required' });
    }

    const session = sessions.get(session_id);
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    // Mark session for handoff
    session.metadata.handoff_requested = true;
    session.metadata.handoff_reason = reason;
    session.metadata.handoff_at = new Date();

    // Update Supabase with handoff request
    try {
      const { createClient } = require('@supabase/supabase-js');
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_KEY
      );
      
      await supabase
        .from('handoffs')
        .insert({
          session_id,
          reason,
          status: 'pending',
          requested_at: new Date().toISOString(),
          metadata: session.metadata
        });
      
      // Update conversation status
      await supabase
        .from('conversations')
        .update({ status: 'handoff_pending', updated_at: new Date().toISOString() })
        .eq('session_id', session_id);
      
      logger.info(`Handoff requested: ${session_id}`, { reason, status: 'logged_to_supabase' });
    } catch (error) {
      logger.error('Failed to log handoff to Supabase', { session_id, error: error.message });
    }

    res.json({
      session_id,
      status: 'handoff_initiated',
      message: 'Human agent handoff has been requested'
    });

  } catch (error) {
    logger.error('Error processing handoff:', error);
    res.status(500).json({
      error: 'Failed to process handoff request',
      message: error.message
    });
  }
});

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    rasa_server: RASA_SERVER_URL
  });
});

/**
 * Check Rasa server connection
 */
app.get('/api/rasa/status', async (req, res) => {
  try {
    const response = await axios.get(`${RASA_SERVER_URL}/status`);
    res.json({
      rasa_status: 'connected',
      version: response.data.version || 'unknown'
    });
  } catch (error) {
    res.status(503).json({
      rasa_status: 'disconnected',
      error: error.message
    });
  }
});

// Start server
app.listen(PORT, () => {
  logger.info(`CallWaitingAI Backend API running on port ${PORT}`);
  logger.info(`Rasa server: ${RASA_SERVER_URL}`);
});

module.exports = app;

