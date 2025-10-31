/**
 * Twilio webhook handlers for voice calls
 */

const express = require('express');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const router = express.Router();

const { speechToText, textToSpeech } = require('../services/stt-tts');
const logger = require('../utils/logger'); // Production logger
const RASA_SERVER_URL = process.env.RASA_SERVER_URL || 'http://localhost:5005';
const TWILIO_WEBHOOK_BASE_URL = process.env.TWILIO_WEBHOOK_BASE_URL || '';

/**
 * POST /api/twilio/incoming
 * Handle incoming Twilio call
 */
router.post('/incoming', (req, res) => {
  const { CallSid, From, To, CallStatus } = req.body;
  
  // Create session for this call
  const sessionId = CallSid || uuidv4();
  
  // Generate TwiML response to greet caller and start recording
  const twimlResponse = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice">Hello! Welcome to Call Waiting AI. How can I assist you today?</Say>
    <Gather input="speech" action="${TWILIO_WEBHOOK_BASE_URL}/api/twilio/gather" 
            method="POST" speechTimeout="auto" language="en-US">
        <Say voice="alice">Please speak your request.</Say>
    </Gather>
    <Redirect>${TWILIO_WEBHOOK_BASE_URL}/api/twilio/timeout</Redirect>
</Response>`;

  res.type('text/xml');
  res.send(twimlResponse);
});

/**
 * POST /api/twilio/gather
 * Handle speech input from Twilio
 */
router.post('/gather', async (req, res) => {
  try {
    const { CallSid, SpeechResult, From, Confidence } = req.body;
    const sessionId = CallSid;
    
    let userText = SpeechResult || '';
    let twimlResponse = '';

    // If no speech detected or low confidence, use STT on audio recording
    if (!userText || Confidence < 0.5) {
      // Try to get audio recording URL from Twilio if available
      // Note: Recording must be enabled in Twilio config
      if (req.body.RecordingUrl) {
        try {
          const improvedText = await speechToText(req.body.RecordingUrl, 'en');
          if (improvedText) {
            userText = improvedText;
            logger.debug('Used MiniMax STT for low-confidence speech', { sessionId, confidence: Confidence });
          }
        } catch (error) {
          logger.debug('STT fallback failed, using SpeechResult', { sessionId, error: error.message });
        }
      }
      
      // Fallback to SpeechResult if STT unavailable
      if (!userText) {
        userText = SpeechResult || '';
      }
      
      if (!userText) {
        twimlResponse = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice">I'm sorry, I didn't catch that. Could you please repeat?</Say>
    <Gather input="speech" action="${TWILIO_WEBHOOK_BASE_URL}/api/twilio/gather" 
            method="POST" speechTimeout="auto" language="en-US">
        <Say voice="alice">Please speak again.</Say>
    </Gather>
    <Redirect>${TWILIO_WEBHOOK_BASE_URL}/api/twilio/timeout</Redirect>
</Response>`;
        res.type('text/xml');
        return res.send(twimlResponse);
      }
    }

    // Process with MiniMax STT if audio recording is available (for better accuracy)
    if (req.body.RecordingUrl) {
      try {
        const transcribedText = await speechToText(req.body.RecordingUrl, 'en');
        if (transcribedText) {
          userText = transcribedText;
          logger.debug('MiniMax STT transcription received', { sessionId, length: transcribedText.length });
        }
      } catch (error) {
        logger.error('STT error', { sessionId, error: error.message });
        // Fall back to Twilio's speech recognition (SpeechResult)
      }
    }

    // Forward to Rasa
    let rasaResponse;
    try {
      const rasaRequest = await axios.post(
        `${RASA_SERVER_URL}/webhooks/rest/webhook`,
        {
          sender: sessionId,
          message: userText,
          metadata: {
            channel: 'twilio',
            language: 'en',
            is_voice: true,
            phone_number: From
          }
        }
      );

      const botText = rasaRequest.data && rasaRequest.data.length > 0
        ? rasaRequest.data[0].text
        : "I'm sorry, I didn't understand that. Could you repeat?";

      // Convert response to speech using MiniMax TTS (default: Odia voice)
      let audioUrl = '';
      try {
        // Use Odia (African male) as default voice for voice calls
        const language = session.metadata?.language || 'en';
        audioUrl = await textToSpeech(botText, language, 'Odia');
        if (audioUrl) {
          logger.debug('MiniMax TTS audio generated', { sessionId, audioLength: audioUrl.length });
        }
      } catch (error) {
        logger.error('TTS error', { sessionId, error: error.message });
        // Will fall back to Twilio's Say verb if TTS fails
      }

      // Generate TwiML response
      twimlResponse = `<?xml version="1.0" encoding="UTF-8"?>
<Response>`;
      
      if (audioUrl) {
        twimlResponse += `
    <Play>${audioUrl}</Play>`;
      } else {
        twimlResponse += `
    <Say voice="alice">${botText}</Say>`;
      }
      
      // Check if handoff was requested
      const handoffRequested = rasaRequest.data?.[0]?.metadata?.handoff_requested;
      
      if (handoffRequested) {
        twimlResponse += `
    <Say voice="alice">Please hold while I connect you with a human agent.</Say>
    <Dial>
        <Number>${process.env.AGENT_PHONE_NUMBER || ''}</Number>
    </Dial>`;
      } else {
        // Continue conversation
        twimlResponse += `
    <Gather input="speech" action="${TWILIO_WEBHOOK_BASE_URL}/api/twilio/gather" 
            method="POST" speechTimeout="auto" language="en-US">
        <Say voice="alice">How else can I help you?</Say>
    </Gather>`;
      }
      
      twimlResponse += `
    <Redirect>${TWILIO_WEBHOOK_BASE_URL}/api/twilio/timeout</Redirect>
</Response>`;

    } catch (error) {
      logger.error('Rasa error', { sessionId, error: error.message });
      twimlResponse = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice">I'm experiencing technical difficulties. Please try again later.</Say>
    <Hangup/>
</Response>`;
    }

    res.type('text/xml');
    res.send(twimlResponse);

  } catch (error) {
    logger.error('Gather error', { sessionId: req.body.CallSid, error: error.message });
    res.type('text/xml');
    res.send(`<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice">An error occurred. Please try again later.</Say>
    <Hangup/>
</Response>`);
  }
});

/**
 * POST /api/twilio/timeout
 * Handle call timeout or no input
 */
router.post('/timeout', (req, res) => {
  const twimlResponse = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice">I didn't receive any input. Please call back if you need assistance. Goodbye.</Say>
    <Hangup/>
</Response>`;

  res.type('text/xml');
  res.send(twimlResponse);
});

/**
 * POST /api/twilio/status
 * Handle call status callbacks
 */
router.post('/status', async (req, res) => {
  const { CallSid, CallStatus, CallDuration, From, To } = req.body;
  
  // Log call status
  logger.info('Call status update', {
    CallSid,
    CallStatus,
    CallDuration,
    From,
    To,
    timestamp: new Date()
  });

  // Update Supabase with call status
  try {
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_KEY
    );
    
    await supabase
      .from('conversations')
      .update({
        status: CallStatus === 'completed' ? 'ended' : CallStatus,
        ended_at: CallStatus === 'completed' ? new Date().toISOString() : null,
        duration_seconds: CallDuration ? parseInt(CallDuration) : null,
        updated_at: new Date().toISOString()
      })
      .eq('session_id', CallSid);
  } catch (error) {
    logger.error('Failed to update call status in Supabase', { CallSid, error: error.message });
  }

  res.status(200).send('OK');
});

/**
 * POST /api/twilio/recording
 * Handle recorded audio (if recording enabled)
 */
router.post('/recording', async (req, res) => {
  const { CallSid, RecordingUrl, RecordingSid, RecordingStatus } = req.body;
  
  logger.info('Recording received', {
    CallSid,
    RecordingSid,
    RecordingStatus,
    hasUrl: !!RecordingUrl
  });

  // Process recording with MiniMax STT for better accuracy (async, non-blocking)
  if (RecordingUrl && RecordingStatus === 'completed') {
    // Process asynchronously - don't block response
    setImmediate(async () => {
      try {
        const transcribedText = await speechToText(RecordingUrl, 'en');
        if (transcribedText) {
          // Store improved transcription in Supabase
          const { createClient } = require('@supabase/supabase-js');
          const supabase = createClient(
            process.env.SUPABASE_URL,
            process.env.SUPABASE_KEY
          );
          
          await supabase
            .from('call_logs')
            .update({ user_input: transcribedText, metadata: { source: 'minimax_stt' } })
            .eq('session_id', CallSid)
            .order('timestamp', { ascending: false })
            .limit(1);
          
          logger.debug('Recording transcription stored', { CallSid });
        }
      } catch (error) {
        logger.error('Recording transcription failed', { CallSid, error: error.message });
      }
    });
  }

  res.status(200).send('OK');
});

module.exports = router;

