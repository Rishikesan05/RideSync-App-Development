import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Load env so we can inject the Google Maps key into index.html at build time
  // (Vite's %VITE_*% HTML substitution only works in the build step, not vite dev)
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      react(),
      // HTML transform: replace the %VITE_GOOGLE_MAPS_API_KEY% placeholder at
      // both dev and build time so the Maps script always receives a real key.
      {
        name: 'html-inject-google-maps',
        transformIndexHtml(html) {
          const key = env.VITE_GOOGLE_MAPS_API_KEY || ''
          return html.replace(/%VITE_GOOGLE_MAPS_API_KEY%/g, key)
        },
      },
    ],
  }
})
