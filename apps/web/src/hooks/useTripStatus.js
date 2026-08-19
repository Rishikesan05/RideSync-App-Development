import { useEffect, useState, useRef } from 'react';
import { ref, onValue, off } from 'firebase/database';
import { rtdb } from '../api/firebase';

/**
 * Subscribes to a single trip's status under /tripStatus/{scheduleId}
 * in Firebase Realtime Database and returns the live payload.
 *
 * Automatically handles subscription cleanup when the component unmounts
 * or when scheduleId changes.
 *
 * @param {string|null} scheduleId - Active schedule document ID to subscribe to.
 * @returns {{ tripStatus: Object|null, isLoading: boolean }}
 *
 * @example
 * const { tripStatus } = useTripStatus(selectedSchedule?.id);
 * // tripStatus = { status, currentStop, eta, delayMinutes, lastUpdatedAt }
 */
export function useTripStatus(scheduleId) {
  const [tripStatus, setTripStatus] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const dbRefObj = useRef(null);

  useEffect(() => {
    // Clear previous data when scheduleId changes
    setTripStatus(null);
    setIsLoading(true);

    if (!scheduleId) {
      setIsLoading(false);
      return;
    }

    const tripRef = ref(rtdb, `tripStatus/${scheduleId}`);
    dbRefObj.current = tripRef;

    const unsubscribe = onValue(
      tripRef,
      (snapshot) => {
        setTripStatus(snapshot.val());
        setIsLoading(false);
      },
      (err) => {
        console.error('[useTripStatus] RTDB error:', err);
        setIsLoading(false);
      }
    );

    return () => {
      if (dbRefObj.current) {
        off(dbRefObj.current);
      }
    };
  }, [scheduleId]);

  return { tripStatus, isLoading };
}

/**
 * Formats an epoch-ms ETA value to a human-readable "HH:MM AM/PM" string.
 * Returns '--:--' if etaMs is null or undefined.
 *
 * @param {number|null} etaMs - Epoch milliseconds ETA from RTDB.
 * @returns {string}
 */
export function formatEta(etaMs) {
  if (!etaMs) return '--:--';
  const dt = new Date(etaMs);
  let h = dt.getHours();
  const amPm = h >= 12 ? 'PM' : 'AM';
  h = h % 12 || 12;
  const mm = String(dt.getMinutes()).padStart(2, '0');
  return `${h}:${mm} ${amPm}`;
}
