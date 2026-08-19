/**
 * RideSync — Firebase Admin SDK Configuration
 *
 * Initializes the Firebase Admin SDK for use across all backend modules.
 * In Cloud Functions production, credentials are auto-discovered.
 * Locally with emulators, the FIREBASE_DATABASE_EMULATOR_HOST env var
 * must be set (firebase emulators:start handles this automatically).
 *
 * IMPORTANT: RTDB is accessed lazily via getRtdb() to avoid startup
 * errors when FIREBASE_DATABASE_URL is not set in the environment.
 */
const admin = require('firebase-admin');

// Initialize only once — auto-discovers credentials in Cloud Functions
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();
const messaging = admin.messaging();

/**
 * Lazily get the Realtime Database instance.
 * Only call this inside a request handler, not at module-load time.
 * This prevents startup failures when FIREBASE_DATABASE_URL is absent.
 */
function getRtdb() {
  return admin.database();
}

module.exports = {
  admin,
  db,
  auth,
  messaging,
  getRtdb,
};
