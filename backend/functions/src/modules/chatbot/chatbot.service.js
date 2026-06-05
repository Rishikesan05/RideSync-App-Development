/**
 * RideSync — Chatbot Service (Gemini 1.5 Flash)
 *
 * Replaces the previous Dialogflow ES integration.
 * Uses Google Gemini 1.5 Flash via the @google/generative-ai SDK.
 * Live Firestore context is injected into every prompt via context_fetcher.js
 * so the AI always answers with real route, schedule, fare, and booking data.
 */
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { buildContext } = require('./context_fetcher');

// ─── Gemini Client Initialisation ────────────────────────────────────────────

const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey && process.env.NODE_ENV === 'production') {
  console.warn('[ChatbotService] GEMINI_API_KEY is not set. Chatbot will be unavailable.');
}

let genAI;

try {
  if (apiKey) {
    genAI = new GoogleGenerativeAI(apiKey, { apiVersion: 'v1' });
  }
} catch (error) {
  console.error('[ChatbotService] Failed to initialise Gemini client:', error.message);
}

// ─── System Prompt Builder ────────────────────────────────────────────────────

/**
 * Builds a dynamic system prompt with live Firestore context injected.
 * @param {Object} context - Live data from context_fetcher.js
 * @returns {string} Full system instruction string
 */
function buildSystemPrompt(context) {
  const routesSummary = context.routes.length > 0
    ? context.routes.map(r =>
        `  - Route ID: ${r.id} | ${r.origin} → ${r.destination} | Type: ${r.type}` +
        (r.distanceKm ? ` | ${r.distanceKm} km` : '') +
        (r.estimatedDuration ? ` | ~${r.estimatedDuration}` : '')
      ).join('\n')
    : '  No active routes found.';

  const schedulesSummary = context.schedules.length > 0
    ? context.schedules.map(s =>
        `  - Bus: ${s.busNumber} | Route: ${s.routeId} | Departs: ${s.departureTime} | Status: ${s.status}` +
        (s.availableSeats !== null ? ` | Seats Available: ${s.availableSeats}` : '')
      ).join('\n')
    : '  No upcoming schedules found for today.';

  const faresSummary = context.fares.length > 0
    ? context.fares.map(f =>
        `  - Route: ${f.routeId} | Class: ${f.class}` +
        (f.baseFare ? ` | Base: LKR ${f.baseFare}` : '') +
        (f.farePerKm ? ` | Per km: LKR ${f.farePerKm}` : '')
      ).join('\n')
    : '  No fare data found.';

  const bookingsSummary = context.userBookings.length > 0
    ? context.userBookings.map(b =>
        `  - Booking ${b.bookingId} | Route: ${b.routeId} | Status: ${b.status}` +
        (b.totalFare ? ` | Fare: LKR ${b.totalFare}` : '') +
        ` | Booked: ${b.bookedAt}`
      ).join('\n')
    : '  No bookings found for this user.';

  return `You are "RideSync Assistant", a friendly and knowledgeable AI assistant built into the RideSync public bus transport app in Sri Lanka.

Your role is to help passengers with:
- Finding bus routes between locations
- Checking departure times and schedules
- Understanding fares and ticket prices
- Managing their bookings (view, status)
- How to use RideSync app features (search, book, track, cancel)
- General transport tips in Sri Lanka

IMPORTANT RULES:
- Only answer questions relevant to public transport and RideSync features.
- Never make up routes, fares, or schedules not in the data below.
- If data is not in the context, say "I don't have that information right now, please check the app or contact support."
- Keep replies concise and friendly (2–4 sentences max unless detail is needed).
- Use LKR for currency. Use Sri Lankan city names as-is.
- Format route info as: Origin → Destination (type, duration, fare range).

--- LIVE RIDESYNC DATA (as of ${context.fetchedAt}) ---

ACTIVE ROUTES:
${routesSummary}

TODAY'S SCHEDULES:
${schedulesSummary}

FARES:
${faresSummary}

USER'S RECENT BOOKINGS:
${bookingsSummary}

--- END OF LIVE DATA ---

Now answer the user's question helpfully based on the data above.`;
}

// ─── Main Export ──────────────────────────────────────────────────────────────

/**
 * Sends a message to Gemini 1.5 Flash with live Firestore context.
 * Maintains the same export signature as the old Dialogflow service
 * so chatbot.controller.js requires zero changes.
 *
 * @param {string} sessionId - The authenticated user's Firebase UID
 * @param {string} text - The user's message
 * @returns {Object} { fulfillmentText, intent, confidence, action, parameters }
 */
exports.detectIntent = async (sessionId, text) => {
  if (!genAI) {
    throw new Error(
      'Chatbot service is currently unavailable. GEMINI_API_KEY may be missing from environment variables.'
    );
  }

  try {
    // Step 1: Fetch live Firestore context (userId = sessionId for personalised data)
    const context = await buildContext(sessionId);

    // Step 2: Build the system prompt with live data injected
    const systemPrompt = buildSystemPrompt(context);

    // Step 3: Create a personalised model instance and send to Gemini
    const userSpecificModel = genAI.getGenerativeModel({ 
      model: 'gemini-flash-latest',
      systemInstruction: systemPrompt
    });

    const chat = userSpecificModel.startChat({
      history: [],
    });

    const result = await chat.sendMessage(text);
    const response = await result.response;
    const fulfillmentText = response.text();

    // Step 4: Return in a format compatible with the existing controller
    return {
      fulfillmentText: fulfillmentText || "I'm sorry, I couldn't generate a response. Please try again.",
      intent: 'gemini-response',
      confidence: 1.0,
      action: 'gemini.response',
      parameters: {},
    };
  } catch (error) {
    console.error('[ChatbotService] Gemini API Error:', error);

    // Surface specific helpful errors
    if (error.message?.includes('API_KEY_INVALID') || error.message?.includes('API key')) {
      throw new Error('Server configuration error: GEMINI_API_KEY is invalid or missing.');
    }
    if (error.message?.includes('quota') || error.message?.includes('RESOURCE_EXHAUSTED')) {
      throw new Error('The AI assistant is temporarily unavailable due to usage limits. Please try again later.');
    }

    throw error;
  }
};
