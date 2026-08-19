/**
 * RideSync — Centralized Error Handler Middleware
 *
 * Must be the LAST middleware registered on the Express app.
 * Catches all errors thrown or passed via next(err).
 */
function errorHandler(err, req, res, _next) {
  console.error(`[ERROR] ${req.method} ${req.originalUrl}:`, err);

  // Joi validation errors bubble up from services
  if (err.isJoi) {
    return res.status(400).json({
      success: false,
      error: 'Validation error.',
      details: err.details.map((d) => ({
        field: d.path.join('.'),
        message: d.message,
      })),
    });
  }

  // Custom app errors with a statusCode property
  if (err.statusCode) {
    return res.status(err.statusCode).json({
      success: false,
      error: err.message,
    });
  }

  // Firebase / General errors with string codes
  if (typeof err.code === 'string' && err.code.startsWith('auth/')) {
    return res.status(400).json({
      success: false,
      error: err.message,
    });
  }

  // Handle common Firestore errors (like missing indexes)
  if (err.code === 9) { // FAILED_PRECONDITION
    return res.status(400).json({
      success: false,
      error: 'The required database index is still building. Please wait a few minutes.',
      details: err.details
    });
  }

  // express-rate-limit proxy validation — should not happen after trust proxy is set,
  // but guard defensively
  if (err.code === 'ERR_ERL_UNEXPECTED_X_FORWARDED_FOR') {
    return res.status(500).json({
      success: false,
      error: 'Server proxy configuration error. Please contact support.',
    });
  }

  // Gemini / Google AI API errors (model not found, quota, etc.)
  if (err.message?.includes('[GoogleGenerativeAI Error]') || err.message?.includes('RESOURCE_EXHAUSTED')) {
    return res.status(503).json({
      success: false,
      error: 'AI service temporarily unavailable. Please try again later.',
    });
  }

  // Default: 500 Internal Server Error
  return res.status(500).json({
    success: false,
    error: 'Internal server error.',
  });
}

module.exports = errorHandler;
