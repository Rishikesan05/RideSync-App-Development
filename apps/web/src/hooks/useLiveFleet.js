import { useEffect, useState, useRef } from 'react';
import { getDatabase, ref, onValue, off } from 'firebase/database';

/**
 * Subscribes to all entries under /busLocations in Firebase Realtime Database
 * and returns a map of busId → location snapshot.
 *
 * Automatically handles subscription cleanup when the component unmounts.
 *
 * @returns {{ fleet: Object, isLoading: boolean, error: string|null }}
 *
 * @example
 * const { fleet } = useLiveFleet();
 * // fleet = {
 * //   "BUS_001": { lat: 6.93, lng: 79.86, speed: 45, heading: 180, timestamp: ... },
 * //   "BUS_002": { ... }
 * // }
 */
export function useLiveFleet() {
  const [fleet, setFleet] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const dbRefObj = useRef(null);

  useEffect(() => {
    const db = getDatabase();
    const fleetRef = ref(db, 'busLocations');
    dbRefObj.current = fleetRef;

    const unsubscribe = onValue(
      fleetRef,
      (snapshot) => {
        const data = snapshot.val() ?? {};
        setFleet(data);
        setIsLoading(false);
        setError(null);
      },
      (err) => {
        console.error('[useLiveFleet] RTDB error:', err);
        setError('Failed to load live fleet data.');
        setIsLoading(false);
      }
    );

    return () => {
      // Cleanup RTDB listener on unmount
      if (dbRefObj.current) {
        off(dbRefObj.current);
      }
    };
  }, []);

  return { fleet, isLoading, error };
}

/**
 * Returns active buses only (those with a timestamp newer than 60 seconds).
 * Useful for filtering the fleet map to avoid showing stale markers.
 */
export function useActiveBuses() {
  const { fleet, isLoading, error } = useLiveFleet();

  const activeBuses = Object.entries(fleet).reduce((acc, [busId, loc]) => {
    const ageMs = Date.now() - (loc.timestamp ?? 0);
    if (ageMs < 60_000) {
      acc[busId] = loc;
    }
    return acc;
  }, {});

  return { activeBuses, isLoading, error };
}
