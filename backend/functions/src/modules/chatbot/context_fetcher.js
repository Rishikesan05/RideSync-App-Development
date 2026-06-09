/**
 * RideSync — Chatbot Context Fetcher
 *
 * Pulls live data from Firestore before each Gemini API call.
 * This is what makes the AI "aware" of real routes, schedules, fares,
 * and the specific user's bookings.
 */
const { db } = require('../../config/firebase.config');

/**
 * Fetches all active routes from Firestore.
 * Limits to 30 to keep the prompt concise.
 */
async function fetchRoutes() {
  try {
    const snapshot = await db
      .collection('routes')
      .where('isActive', '==', true)
      .limit(30)
      .get();

    return snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        // Seed script uses startPoint/endPoint; backend admin uses origin/destination
        origin: d.origin || d.startPoint || 'Unknown',
        destination: d.destination || d.endPoint || 'Unknown',
        type: d.type || d.routeType || 'normal',
        distanceKm: d.distanceKm || d.totalDistanceKm || d.distance || null,
        estimatedDuration: d.estimatedDuration || d.duration || null,
      };
    });
  } catch (err) {
    console.error('[ContextFetcher] Failed to fetch routes:', err.message);
    return [];
  }
}

/**
 * Fetches today's schedules from Firestore.
 * Only pulls scheduled/active ones to keep context relevant.
 */
async function fetchTodaySchedules() {
  try {
    const snapshot = await db
      .collection('schedules')
      .where('status', 'in', ['scheduled', 'active', 'on_time'])
      .orderBy('departureTime', 'asc')
      .limit(20)
      .get();

    return snapshot.docs.map((doc) => {
      const d = doc.data();
      // Convert Firestore Timestamp to readable string if needed
      const depTime = d.departureTime
        ? (d.departureTime.toDate
            ? d.departureTime.toDate().toISOString()
            : d.departureTime)
        : 'N/A';
      return {
        scheduleId: doc.id,
        routeId: d.routeId,
        busNumber: d.busNumber || d.busId || 'N/A',
        departureTime: depTime,
        status: d.status,
        availableSeats: d.availableSeats ?? null,
      };
    });
  } catch (err) {
    console.error('[ContextFetcher] Failed to fetch schedules:', err.message);
    return [];
  }
}

/**
 * Fetches fares for all routes.
 * Limits to 30 entries.
 */
async function fetchFares() {
  try {
    const snapshot = await db.collection('fares').limit(30).get();
    return snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        routeId: d.routeId,
        class: d.class || d.busClass || 'standard',
        baseFare: d.baseFare || d.base_fare || null,
        farePerKm: d.farePerKm || d.fare_per_km || null,
      };
    });
  } catch (err) {
    console.error('[ContextFetcher] Failed to fetch fares:', err.message);
    return [];
  }
}

/**
 * Fetches the authenticated user's most recent bookings.
 * @param {string} userId - Firebase UID of the authenticated user
 */
async function fetchUserBookings(userId) {
  if (!userId) return [];
  try {
    const snapshot = await db
      .collection('bookings')
      .where('passengerId', '==', userId)
      .orderBy('bookedAt', 'desc')
      .limit(5)
      .get();

    return snapshot.docs.map((doc) => {
      const d = doc.data();
      const bookedAt = d.bookedAt
        ? (d.bookedAt.toDate
            ? d.bookedAt.toDate().toISOString()
            : d.bookedAt)
        : 'N/A';
      return {
        bookingId: doc.id,
        routeId: d.routeId,
        scheduleId: d.scheduleId,
        status: d.status,
        seats: d.seats || d.seatNumbers || [],
        totalFare: d.totalFare || d.fare || null,
        bookedAt,
      };
    });
  } catch (err) {
    console.error('[ContextFetcher] Failed to fetch user bookings:', err.message);
    return [];
  }
}

/**
 * Main context builder. Fetches all data in parallel for speed.
 * @param {string|null} userId - Firebase UID (optional, for personalised context)
 * @returns {Object} Structured context object for the Gemini prompt
 */
async function buildContext(userId = null) {
  const [routes, schedules, fares, userBookings] = await Promise.all([
    fetchRoutes(),
    fetchTodaySchedules(),
    fetchFares(),
    fetchUserBookings(userId),
  ]);

  return {
    fetchedAt: new Date().toISOString(),
    routes,
    schedules,
    fares,
    userBookings,
  };
}

module.exports = { buildContext };
