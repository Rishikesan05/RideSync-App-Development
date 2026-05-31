import axios from 'axios';
import { auth } from './firebase';

// Use VITE_API_BASE_URL from .env if set.
// Defaults to the production Cloud Functions URL so the app works without
// any local emulator running. To develop against the emulator, add:
//   VITE_API_BASE_URL=http://127.0.0.1:5001/ridesync-lk/asia-south1/api/api
// to your .env file and start: firebase emulators:start --only functions
const baseURL =
  import.meta.env.VITE_API_BASE_URL ||
  'https://asia-south1-ridesync-lk.cloudfunctions.net/api/api';

const axiosInstance = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to attach Firebase ID token
axiosInstance.interceptors.request.use(
  async (config) => {
    if (auth.currentUser) {
      const token = await auth.currentUser.getIdToken();
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for generic error handling
axiosInstance.interceptors.response.use(
  (response) => {
    return response; // Return the full axios response so callers can access .data
  },
  (error) => {
    // Format error message from backend
    const message = error.response?.data?.error || error.message || 'An unknown error occurred';
    console.error('API Error:', message);
    return Promise.reject(new Error(message));
  }
);

export default axiosInstance;
