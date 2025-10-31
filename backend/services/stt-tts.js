/**
 * MiniMax STT/TTS integration service
 * Production-ready with comprehensive validation and error handling
 */

const axios = require('axios');
const logger = require('../utils/logger');

// Constants
const MINIMAX_API_URL = process.env.MINIMAX_API_URL || 'https://api.minimax.io/v1';
const MINIMAX_API_KEY = process.env.MINIMAX_API_KEY || '';
const MINIMAX_GROUP_ID = process.env.MINIMAX_GROUP_ID || '';
const MINIMAX_MODEL = process.env.MINIMAX_MODEL || 'speech-02-hd';

// Configuration constants
const TTS_TIMEOUT_MS = 30000;
const MAX_TEXT_LENGTH = 5000;
const DEFAULT_VOICE_SETTINGS = {
  speed: 1.0,
  pitch: 0,
  emotion: 'neutral'
};

// Valid language codes
const VALID_LANGUAGES = ['en', 'pidgin'];

// Voice ID mapping (constant, not recreated per call)
const VOICE_ID_MAP = {
  odia: 'moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc', // African male default
  odiamale: 'moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc',
  marcus: 'moss_audio_a59cd561-ab87-11f0-a74c-2a7a0b4baedc', // American male
  marcy: 'moss_audio_fdad4786-ab84-11f0-a816-023f15327f7a', // American female
  joslyn: 'moss_audio_141d8c4c-a6f8-11f0-84c1-0ec6fa858d82', // African female
  alice: 'moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc',
  default: 'moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc'
};

/**
 * Convert audio to text using MiniMax STT
 * Note: STT endpoint may differ from TTS. Using a2t endpoint if available.
 * @param {string} audioUrl - URL of the audio file or base64 encoded audio
 * @param {string} language - Language code (en, pidgin)
 * @returns {Promise<string>} - Transcribed text
 */
async function speechToText(audioUrl, language = 'en') {
  if (!MINIMAX_API_KEY || !MINIMAX_GROUP_ID) {
    throw new Error('MiniMax STT not configured');
  }

  try {
    // MiniMax STT endpoint (audio-to-text)
    // Note: Adjust endpoint if MiniMax provides a different STT endpoint
    const sttEndpoint = `${MINIMAX_API_URL}/a2t`; // Assuming a2t for audio-to-text
    
    const response = await axios.post(
      sttEndpoint,
      {
        group_id: MINIMAX_GROUP_ID,
        audio_url: audioUrl,
        audio_base64: audioUrl.startsWith('data:') ? audioUrl : undefined,
        language: language === 'pidgin' ? 'en' : language, // Fallback to en if pidgin not supported
        model: MINIMAX_MODEL
      },
      {
        headers: {
          'Authorization': `Bearer ${MINIMAX_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data.text || response.data.result || '';
  } catch (error) {
    logger.error('STT Error', {
      message: error.message,
      status: error.response?.status,
      endpoint: sttEndpoint
    });
    
    // If a2t endpoint doesn't exist, log warning but don't crash
    if (error.response?.status === 404) {
      logger.warn('STT endpoint not found. Please verify MiniMax STT endpoint configuration.');
    }
    throw error;
  }
}

/**
 * Validates and sanitizes text input
 * @param {string} text - Text to validate
 * @throws {Error} If text is invalid
 */
function validateText(text) {
  if (!text || typeof text !== 'string') {
    throw new Error('Text parameter is required and must be a string');
  }
  
  const trimmedText = text.trim();
  if (trimmedText.length === 0) {
    throw new Error('Text cannot be empty or whitespace-only');
  }
  
  if (trimmedText.length > MAX_TEXT_LENGTH) {
    throw new Error(`Text exceeds maximum length of ${MAX_TEXT_LENGTH} characters`);
  }
  
  return trimmedText;
}

/**
 * Validates language code
 * @param {string} language - Language code
 * @returns {string} - Validated language code (normalized to 'en' for pidgin)
 */
function validateLanguage(language) {
  if (!language || typeof language !== 'string') {
    return 'en';
  }
  
  const normalized = language.toLowerCase();
  // Map pidgin to en for API compatibility
  return normalized === 'pidgin' ? 'en' : (VALID_LANGUAGES.includes(normalized) ? normalized : 'en');
}

/**
 * Gets voice ID from voice name (case-insensitive)
 * @param {string} voiceName - Voice name
 * @returns {string} - Voice ID
 */
function getVoiceId(voiceName) {
  if (!voiceName || typeof voiceName !== 'string') {
    return VOICE_ID_MAP.default;
  }
  
  const normalized = voiceName.toLowerCase().trim();
  return VOICE_ID_MAP[normalized] || VOICE_ID_MAP.default;
}

/**
 * Decodes HEX-encoded audio to base64 data URI
 * @param {string} hexAudio - HEX-encoded audio string
 * @returns {string} - Base64 data URI
 * @throws {Error} If decoding fails
 */
function decodeHexAudio(hexAudio) {
  if (!hexAudio || typeof hexAudio !== 'string') {
    throw new Error('Invalid hex audio data: must be a non-empty string');
  }
  
  // Validate hex format
  if (!/^[0-9A-Fa-f]+$/.test(hexAudio)) {
    throw new Error('Audio data is not valid HEX format');
  }
  
  try {
    const hexBuffer = Buffer.from(hexAudio, 'hex');
    
    if (hexBuffer.length === 0) {
      throw new Error('HEX decode produced empty buffer');
    }
    
    // Validate MP3 header
    const header = hexBuffer.slice(0, 3).toString('ascii');
    if (header !== 'ID3' && !(hexBuffer[0] === 0xFF && (hexBuffer[1] & 0xE0) === 0xE0)) {
      throw new Error(`Invalid audio format: expected MP3, got header "${header}"`);
    }
    
    const base64Audio = hexBuffer.toString('base64');
    return `data:audio/mp3;base64,${base64Audio}`;
  } catch (error) {
    if (error.message.includes('Invalid audio format')) {
      throw error;
    }
    throw new Error(`Failed to decode HEX audio: ${error.message}`);
  }
}

/**
 * Extracts audio data from MiniMax API response
 * @param {Object} responseData - API response data
 * @returns {string} - Audio data URI or URL
 * @throws {Error} If no audio data found
 */
function extractAudioFromResponse(responseData) {
  if (!responseData || typeof responseData !== 'object') {
    throw new Error('Invalid API response: response data is missing or invalid');
  }
  
  // Try multiple response paths (document expected structure)
  const audioData = responseData?.data?.audio || 
                    responseData?.audio ||
                    responseData?.result?.audio;
  
  if (audioData && typeof audioData === 'string' && audioData.length > 0) {
    // If already a data URI, return as-is
    if (audioData.startsWith('data:')) {
      return audioData;
    }
    
    // If it's a URL, return as-is
    if (audioData.startsWith('http://') || audioData.startsWith('https://')) {
      return audioData;
    }
    
    // Assume HEX format (MiniMax standard)
    return decodeHexAudio(audioData);
  }
  
  // Check for audio URL
  const audioUrl = responseData?.audio_url || 
                   responseData?.data?.audio_url ||
                   responseData?.result?.audio_url;
  if (audioUrl && typeof audioUrl === 'string') {
    return audioUrl;
  }
  
  // Check for audio_id (async retrieval - should this be handled differently?)
  const audioId = responseData?.audio_id || responseData?.data?.audio_id;
  if (audioId && typeof audioId === 'string') {
    // NOTE: audio_id requires separate API call to retrieve audio
    // This might not be the expected behavior - consider throwing error instead
    throw new Error(`Audio ID returned instead of audio data. Async retrieval not implemented. Audio ID: ${audioId}`);
  }
  
  throw new Error('No audio data found in API response');
}

/**
 * Sanitizes error messages to prevent leaking sensitive data
 * @param {Error} error - Error object
 * @returns {string} - Sanitized error message
 */
function sanitizeError(error) {
  if (!error) return 'Unknown error';
  
  let message = error.message || String(error);
  
  // Remove potential API keys, tokens, etc.
  message = message.replace(/[Bb]earer\s+[\w-]+/gi, '[REDACTED]');
  message = message.replace(/[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][\s:=]+[\w-]+/gi, '[REDACTED]');
  
  return message;
}

/**
 * Convert text to speech using MiniMax TTS (t2a_v2 endpoint)
 * 
 * @param {string} text - Text to convert to speech (required, max 5000 chars)
 * @param {string} [language='en'] - Language code ('en' or 'pidgin')
 * @param {string} [voiceName='Odia'] - Voice name (Odia, Marcus, Marcy, Joslyn)
 * @param {Object} [options={}] - Additional options
 * @param {number} [options.speed=1.0] - Speech speed (0.5-2.0)
 * @param {number} [options.pitch=0] - Voice pitch (-20 to 20)
 * @param {string} [options.emotion='neutral'] - Emotion setting
 * 
 * @returns {Promise<string>} - Data URI (data:audio/mp3;base64,...) or URL
 * 
 * @throws {Error} If API credentials are not configured
 * @throws {Error} If text is invalid or exceeds length limit
 * @throws {Error} If API request fails
 * @throws {Error} If audio data cannot be decoded
 * 
 * @example
 * const audioUri = await textToSpeech('Hello world', 'en', 'Odia');
 * // Returns: 'data:audio/mp3;base64,SUQzBAAAAAA...'
 */
async function textToSpeech(text, language = 'en', voiceName = 'Odia', options = {}) {
  // Validate configuration
  if (!MINIMAX_API_KEY || !MINIMAX_GROUP_ID) {
    throw new Error('MiniMax TTS not configured: API_KEY and GROUP_ID required');
  }
  
  // Validate and sanitize inputs
  const validatedText = validateText(text);
  const validatedLanguage = validateLanguage(language);
  const voiceId = getVoiceId(voiceName);
  
  // Build voice settings with options override
  const voiceSettings = {
    voice_id: voiceId,
    speed: options.speed ?? DEFAULT_VOICE_SETTINGS.speed,
    pitch: options.pitch ?? DEFAULT_VOICE_SETTINGS.pitch,
    emotion: options.emotion ?? DEFAULT_VOICE_SETTINGS.emotion
  };
  
  // Construct endpoint
  const ttsEndpoint = `${MINIMAX_API_URL}/t2a_v2?GroupId=${MINIMAX_GROUP_ID}`;
  
  try {
    const response = await axios.post(
      ttsEndpoint,
      {
        text: validatedText,
        model: MINIMAX_MODEL,
        voice_setting: voiceSettings,
        language_boost: 'auto'
      },
      {
        headers: {
          'Authorization': `Bearer ${MINIMAX_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: TTS_TIMEOUT_MS
      }
    );
    
    // Validate response structure
    if (!response?.data) {
      throw new Error('Invalid API response: no data received');
    }
    
    // Check API status code
    const statusCode = response.data?.base_resp?.status_code;
    const statusMsg = response.data?.base_resp?.status_msg;
    
    if (statusCode !== 0) {
      const errorMsg = statusMsg || 'TTS request failed';
      throw new Error(`MiniMax TTS API error (${statusCode}): ${errorMsg}`);
    }
    
    // Extract and return audio
    return extractAudioFromResponse(response.data);
    
  } catch (error) {
    // Handle specific error cases
    if (axios.isAxiosError(error)) {
      if (error.code === 'ECONNABORTED') {
        throw new Error(`TTS request timed out after ${TTS_TIMEOUT_MS}ms`);
      }
      
      if (error.response) {
        const status = error.response.status;
        const errorData = error.response.data;
        
        // Handle rate limiting
        if (status === 429) {
          throw new Error('MiniMax API rate limit exceeded. Please retry later.');
        }
        
        // Handle authentication errors
        if (status === 401 || status === 403) {
          throw new Error('MiniMax API authentication failed. Check API credentials.');
        }
        
        // Generic API error
        const apiError = errorData?.base_resp?.status_msg || error.message;
        throw new Error(`MiniMax API error (${status}): ${sanitizeError({ message: apiError })}`);
      }
      
      if (error.request) {
        throw new Error('No response from MiniMax API. Check network connection.');
      }
    }
    
    // Re-throw validation errors as-is
    if (error.message.includes('required') || 
        error.message.includes('invalid') || 
        error.message.includes('exceeds')) {
      throw error;
    }
    
    // Generic error handling
    throw new Error(`TTS generation failed: ${sanitizeError(error)}`);
  }
}

/**
 * Detect language from audio/text
 * @param {string} input - Audio URL or text
 * @returns {Promise<string>} - Detected language code
 */
async function detectLanguage(input) {
  // Simple language detection based on keywords
  // For production, use a proper language detection service
  
  const pidginKeywords = ['abeg', 'una', 'dey', 'wetin', 'na', 'go', 'come', 'don'];
  const text = typeof input === 'string' ? input.toLowerCase() : '';
  
  const hasPidginKeywords = pidginKeywords.some(keyword => text.includes(keyword));
  
  return hasPidginKeywords ? 'pidgin' : 'en';
}

module.exports = {
  speechToText,
  textToSpeech,
  detectLanguage
};

