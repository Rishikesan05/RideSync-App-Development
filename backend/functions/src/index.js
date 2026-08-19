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
 *
 * ## Gap 8 improvements (2026-08-17 — gps-fixing-2.0 branch)
 * 1. Reads `scheduleId` and `routeId` directly from the RTDB payload written
 *    by the updated GpsService, saving one Firestore query per GPS tick.
 * 2. Writes `nextStop` (the stop after currentStop) to /tripStatus.
 * 3. Writes `remainingDistanceKm` to /tripStatus for client-side display.
 * 4. Falls back to a Firestore query if scheduleId is not in the RTDB payload
 *    (backward-compatible with older client versions).
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

    // If isBroadcasting is explicitly false, skip ETA recalc
    if (location.isBroadcasting === false) return null;

    try {
      let scheduleId = location.scheduleId || null;
      let routeId = location.routeId || null;
      let scheduleData = null;

      if (scheduleId) {
        // ── Fast path: scheduleId was written directly to RTDB by GpsService ──
        // One Firestore read instead of a query.
        const scheduleDoc = await admin
          .firestore()
          .collection('schedules')
          .doc(scheduleId)
          .get();

        if (!scheduleDoc.exists) return null;
        scheduleData = scheduleDoc.data();
        routeId = routeId || scheduleData.routeId;
      } else {
        // ── Fallback: query Firestore by busId (old client behaviour) ──────────
        const schedulesSnap = await admin
          .firestore()
          .collection('schedules')
          .where('busId', '==', busId)
          .where('status', 'in', ['in-transit', 'active'])
          .limit(1)
          .get();

        if (schedulesSnap.empty) return null;

        const scheduleDoc = schedulesSnap.docs[0];
        scheduleId = scheduleDoc.id;
        scheduleData = scheduleDoc.data();
        routeId = scheduleData.routeId;
      }

      if (!routeId) return null;

      const { currentStop, delayMinutes = 0 } = scheduleData;

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
      const currentIdx = stops.findIndex((s) => s.name === currentStop);
      const useIdx = currentIdx >= 0 ? currentIdx : 0;

      const endStop = stops[stops.length - 1];
      const remainingKm =
        endStop.distFromStartKm - stops[useIdx].distFromStartKm;

      // 4. Compute ETA using live speed (floor at 10 km/h to avoid huge ETAs)
      const speedKmh = Math.max(location.speed || 30, 10);
      const etaMs = Date.now() + (remainingKm / speedKmh) * 3_600_000;

      // 5. Determine next stop (Gap 8 enhancement)
      const nextStopIdx = useIdx + 1;
      const nextStop =
        nextStopIdx < stops.length ? stops[nextStopIdx].name : null;

      // 6. Write ETA, nextStop, remainingDistanceKm, and delay to RTDB
      await admin
        .database()
        .ref(`/tripStatus/${scheduleId}`)
        .update({
          status: 'active',
          currentStop: currentStop || stops[0].name,
          nextStop: nextStop ?? stops[stops.length - 1].name,
          eta: etaMs,
          remainingDistanceKm: Math.round(remainingKm * 10) / 10,
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
