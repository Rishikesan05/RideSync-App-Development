import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getAnalytics } from 'firebase/analytics';
import { getFirestore } from 'firebase/firestore';
import { getDatabase } from 'firebase/database';


// Replace these with actual config for production.
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
  databaseURL: import.meta.env.VITE_FIREBASE_DATABASE_URL,
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const rtdb = getDatabase(app);
export const analytics = (typeof window !== 'undefined' && firebaseConfig.measurementId) ? getAnalytics(app) : null;

// Emulators disabled — app connects to real Firebase.
// To use emulators locally, set VITE_USE_EMULATORS=true in .env and uncomment below:
// if (import.meta.env.VITE_USE_EMULATORS === 'true') {
//   connectAuthEmulator(auth, "http://127.0.0.1:9099");
//   connectFirestoreEmulator(db, "127.0.0.1", 8080);
// }

export default app;
