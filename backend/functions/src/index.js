/**
 * RideSync — Firebase Cloud Functions Entry Point
 *
 * Exports the Express app as an HTTPS Cloud Function.
 * This is the single entry point for the entire backend API.
 */
const { onRequest } = require('firebase-functions/v2/https');
const app = require('./app');

// Export as a v2 Cloud Function
// Region: asia-south1 (Mumbai) — closest to Sri Lanka
exports.api = onRequest(
  {
    region: 'asia-south1',
    timeoutSeconds: 60,
    memory: '256MiB',
    invoker: 'public',
  },
  app
);

