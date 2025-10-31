/**
 * Error Sanitization Utilities
 * Prevents sensitive information from being logged or exposed in error messages
 */

/**
 * Sanitizes error messages to remove sensitive information
 * @param {Error|string} error - The error to sanitize
 * @returns {string} - Sanitized error message
 */
function sanitizeError(error) {
  if (!error) return 'Unknown error occurred';
  
  const errorMessage = error.message || error.toString();
  
  // Patterns to remove sensitive information
  const sensitivePatterns = [
    // API keys and tokens
    /[Aa]pi[_\s]*[Kk]ey[:\s]*[a-zA-Z0-9_-]{10,}/g,
    /[Tt]oken[:\s]*[a-zA-Z0-9_-]{10,}/g,
    /[Bb]earer\s+[a-zA-Z0-9_-]{10,}/g,
    
    // Database connection strings
    /postgresql:\/\/[^@]+@[^\/]+\/[^\s]+/g,
    /mysql:\/\/[^@]+@[^\/]+\/[^\s]+/g,
    /mongodb:\/\/[^@]+@[^\/]+\/[^\s]+/g,
    
    // URLs with credentials
    /https?:\/\/[^:]+:[^@]+@[^\s]+/g,
    
    // Environment variable values (common patterns)
    /[A-Z_]+=[^\s]+/g,
    
    // IP addresses (optional - might be needed for debugging)
    // /\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/g,
    
    // File paths that might contain usernames
    /\/Users\/[^\/\s]+/g,
    /C:\\Users\\[^\\\/\s]+/g,
  ];
  
  let sanitized = errorMessage;
  
  // Replace sensitive patterns
  sensitivePatterns.forEach(pattern => {
    sanitized = sanitized.replace(pattern, '[REDACTED]');
  });
  
  return sanitized;
}

/**
 * Sanitizes an entire error object for logging
 * @param {Error} error - The error object to sanitize
 * @returns {Object} - Sanitized error object safe for logging
 */
function sanitizeErrorForLogging(error) {
  if (!error) return { message: 'Unknown error occurred' };
  
  return {
    message: sanitizeError(error.message || error.toString()),
    name: error.name || 'Error',
    stack: error.stack ? sanitizeError(error.stack) : undefined,
    code: error.code || undefined,
    status: error.status || error.statusCode || undefined,
    timestamp: new Date().toISOString()
  };
}

/**
 * Creates a safe error response for API endpoints
 * @param {Error} error - The original error
 * @param {boolean} includeDetails - Whether to include error details (for development)
 * @returns {Object} - Safe error response
 */
function createSafeErrorResponse(error, includeDetails = false) {
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  const baseResponse = {
    error: 'An error occurred while processing your request',
    timestamp: new Date().toISOString()
  };
  
  if (isDevelopment || includeDetails) {
    baseResponse.details = sanitizeError(error.message || error.toString());
    
    if (error.code) {
      baseResponse.code = error.code;
    }
  }
  
  return baseResponse;
}

module.exports = {
  sanitizeError,
  sanitizeErrorForLogging,
  createSafeErrorResponse
};