/**
 * Production logger utility
 * Replaces console.log/error/warn with proper structured logging
 */

const winston = require('winston');

// Determine log level from environment
const logLevel = process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug');

// Create logger instance
const logger = winston.createLogger({
  level: logLevel,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'callwaitingai-backend' },
  transports: [
    // Write all logs to console in development
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'production'
        ? winston.format.json()
        : winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          )
    }),
    // Write errors to error.log in production
    ...(process.env.NODE_ENV === 'production' ? [
      new winston.transports.File({
        filename: 'logs/error.log',
        level: 'error',
        maxsize: 5242880, // 5MB
        maxFiles: 5
      }),
      new winston.transports.File({
        filename: 'logs/combined.log',
        maxsize: 5242880, // 5MB
        maxFiles: 5
      })
    ] : [])
  ]
});

// Sanitize sensitive data from log entries
const sanitizeLogData = (data) => {
  if (!data || typeof data !== 'object') return data;
  
  const sanitized = { ...data };
  const sensitiveKeys = ['password', 'api_key', 'apiKey', 'token', 'authorization', 'auth', 'secret', 'key'];
  
  for (const key in sanitized) {
    const lowerKey = key.toLowerCase();
    if (sensitiveKeys.some(sk => lowerKey.includes(sk))) {
      sanitized[key] = '[REDACTED]';
    }
  }
  
  return sanitized;
};

// Wrap logger methods to sanitize data
const originalMethods = {
  info: logger.info.bind(logger),
  error: logger.error.bind(logger),
  warn: logger.warn.bind(logger),
  debug: logger.debug.bind(logger)
};

logger.info = (message, meta = {}) => {
  return originalMethods.info(message, sanitizeLogData(meta));
};

logger.error = (message, meta = {}) => {
  return originalMethods.error(message, sanitizeLogData(meta));
};

logger.warn = (message, meta = {}) => {
  return originalMethods.warn(message, sanitizeLogData(meta));
};

logger.debug = (message, meta = {}) => {
  return originalMethods.debug(message, sanitizeLogData(meta));
};

module.exports = logger;

