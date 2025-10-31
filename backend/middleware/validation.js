/**
 * Input validation middleware using Joi
 * Provides security against injection attacks and data corruption
 */

const Joi = require('joi');
const logger = require('../utils/logger');

// Validation schemas
const schemas = {
  chatMessage: Joi.object({
    message: Joi.string()
      .trim()
      .min(1)
      .max(5000)
      .required()
      .pattern(/^[^<>{}]*$/) // Basic XSS protection
      .messages({
        'string.pattern.base': 'Message contains invalid characters',
        'string.max': 'Message too long (max 5000 characters)',
        'string.min': 'Message cannot be empty'
      }),
    session_id: Joi.string()
      .uuid()
      .optional()
      .allow(null, ''),
    language: Joi.string()
      .valid('en', 'pidgin', 'auto')
      .default('en'),
    channel: Joi.string()
      .valid('web', 'telegram', 'whatsapp', 'twilio')
      .default('web')
  }),

  voiceMessage: Joi.object({
    audio: Joi.string()
      .required()
      .max(50 * 1024 * 1024) // 50MB limit for base64 audio
      .messages({
        'string.max': 'Audio file too large (max 50MB)'
      }),
    session_id: Joi.string()
      .uuid()
      .optional()
      .allow(null, ''),
    language: Joi.string()
      .valid('en', 'pidgin', 'auto')
      .default('en'),
    channel: Joi.string()
      .valid('web', 'telegram', 'whatsapp', 'twilio')
      .default('web')
  }),

  sessionId: Joi.object({
    sessionId: Joi.string()
      .uuid()
      .required()
      .messages({
        'string.uuid': 'Invalid session ID format'
      })
  }),

  handoff: Joi.object({
    session_id: Joi.string()
      .uuid()
      .required(),
    reason: Joi.string()
      .trim()
      .min(1)
      .max(500)
      .optional(),
    priority: Joi.string()
      .valid('low', 'medium', 'high', 'urgent')
      .default('medium')
  })
};

/**
 * Create validation middleware for specific schema
 * @param {string} schemaName - Name of the schema to validate against
 * @param {string} source - Where to find data ('body', 'params', 'query')
 * @returns {Function} Express middleware function
 */
function validateInput(schemaName, source = 'body') {
  return (req, res, next) => {
    const schema = schemas[schemaName];
    if (!schema) {
      logger.error(`Validation schema '${schemaName}' not found`);
      return res.status(500).json({ error: 'Internal validation error' });
    }

    const data = req[source];
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true,
      convert: true
    });

    if (error) {
      const errorDetails = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      logger.warn('Input validation failed', {
        endpoint: req.path,
        errors: errorDetails,
        ip: req.ip
      });

      return res.status(400).json({
        error: 'Invalid input',
        details: errorDetails
      });
    }

    // Replace original data with validated/sanitized data
    req[source] = value;
    next();
  };
}

/**
 * Sanitize text input to prevent XSS and injection attacks
 * @param {string} text - Text to sanitize
 * @returns {string} Sanitized text
 */
function sanitizeText(text) {
  if (typeof text !== 'string') return text;
  
  return text
    .replace(/[<>]/g, '') // Remove potential HTML tags
    .replace(/javascript:/gi, '') // Remove javascript: protocol
    .replace(/on\w+=/gi, '') // Remove event handlers
    .trim();
}

/**
 * Rate limiting configuration
 */
const rateLimitConfig = {
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // Default: 15 minutes
  max: parseInt(process.env.RATE_LIMIT_REQUESTS) || 100, // Default: 100 requests per window
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 60000) + ' minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn('Rate limit exceeded', {
      ip: req.ip,
      endpoint: req.path,
      userAgent: req.get('User-Agent')
    });
    res.status(429).json(rateLimitConfig.message);
  }
};

module.exports = {
  validateInput,
  sanitizeText,
  rateLimitConfig,
  schemas
};