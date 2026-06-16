/**
 * RideSync — Firebase Cloud Functions Entry Point
 *
 * Exports:
 *   api           — The entire Express REST API (HTTPS v2)
 *   recalculateETA — RTDB-triggered ETA calculator (fires on every GPS update)
 */
const { onRequest } = require('firebase-functions/v2/https');
const { onValueUpdated } = require('firebase-functions/v2/database');
const admin = require('firebase-admin');
const app = require('./app');

// ── HTTPS API ─────────────────────────────────────────────────────────────────
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

// ── ETA Calculator (RTDB trigger) ─────────────────────────────────────────────
/**
 * Fires on every GPS update written to /busLocations/{busId}.
 * Reads the active schedule for this bus from Firestore, computes the
 * remaining distance using pre-stored stop distances, then writes the
 * calculated ETA back to /tripStatus/{scheduleId}.
 *
 * Cost note: RTDB triggers are NOT counted against Cloud Functions invocation
 * quotas; they run on the same pricing tier as HTTPS functions.
 */
exports.recalculateETA = onValueUpdated(
  {
    ref: '/busLocations/{busId}',
    region: 'asia-southeast1',
    instance: 'ridesync-lk-default-rtdb', // Replace with your RTDB instance name
  },
  async (event) => {
    const { busId } = event.params;
    const location = event.data.after.val();

    // Operator stopped broadcasting (node was deleted)
    if (!location) return null;

    try {
      // 1. Find the active schedule for this bus
      const schedulesSnap = await admin
        .firestore()
        .collection('schedules')
        .where('busId', '==', busId)
        .where('status', 'in', ['in-transit', 'active'])
        .limit(1)
        .get();

      if (schedulesSnap.empty) {
        // No active trip — nothing to compute
        return null;
      }

      const scheduleDoc = schedulesSnap.docs[0];
      const scheduleId = scheduleDoc.id;
      const scheduleData = scheduleDoc.data();
      const { routeId, currentStop } = scheduleData;

      // 2. Fetch route to get ordered stops with precomputed distances
      const routeDoc = await admin
        .firestore()
        .collection('routes')
        .doc(routeId)
        .get();

      if (!routeDoc.exists) return null;

      const route = routeDoc.data();
      const stops = route.stops; // [{ name, distFromStartKm }, ...]

      if (!stops || stops.length < 2) return null;

      // 3. Find the current stop index
      const currentIdx = stops.findIndex(
        (s) => s.name === currentStop
      );
      const useIdx = currentIdx >= 0 ? currentIdx : 0;

      const endStop = stops[stops.length - 1];
      const remainingKm =
        endStop.distFromStartKm - stops[useIdx].distFromStartKm;

      // 4. Compute ETA using live speed (floor at 10 km/h to avoid huge ETAs)
      const speedKmh = Math.max(location.speed || 30, 10);
      const etaMs = Date.now() + (remainingKm / speedKmh) * 3_600_000;

      // 5. Write ETA + delay back to RTDB
      const delayMinutes = scheduleData.delayMinutes || 0;
      await admin
        .database()
        .ref(`/tripStatus/${scheduleId}`)
        .update({
          status: 'active',
          currentStop: currentStop || stops[0].name,
          eta: etaMs,
          delayMinutes,
          lastUpdatedAt: Date.now(),
        });

      return null;
    } catch (err) {
      console.error('[recalculateETA] Error:', err);
      return null;
    }
  }
);
