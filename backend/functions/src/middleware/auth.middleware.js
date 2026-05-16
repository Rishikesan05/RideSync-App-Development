/**
 * RideSync — Auth Middleware
 *
 * Verifies Firebase ID tokens from the Authorization header.
 * Attaches the decoded token (including custom claims) to req.user.
 */
const { auth } = require('../config/firebase.config');

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Missing or malformed Authorization header. Expected: Bearer <token>',
    });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decoded = await auth.verifyIdToken(idToken);
    req.user = decoded;
    next();
  } catch (err) {
    console.error('Auth token verification failed:', err.message);
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired authentication token.',
    });
  }
}

module.exports = authMiddleware;
