/**
 * useSchedulesFirestore.js
 *
 * Real-time Firestore hook for the `schedules` collection.
 * Uses onSnapshot so the UI updates instantly whenever any schedule document
 * is created, updated, or cancelled — no manual refresh needed.
 *
 * Usage:
 *   const { schedules, loading, error } = useSchedulesFirestore();
 *
 * Replaces the React Query-based useSchedulesList() which only polls on mount.
 * Return shape is aligned with useRoutesFirestore for consistency.
 */

import { useState, useEffect } from 'react';
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  where,
  getDocs,
  deleteDoc,
  doc
} from 'firebase/firestore';
import { db } from '../../api/firebase';

const COLLECTION = 'schedules';

/**
 * useSchedulesFirestore
 *
 * Returns:
 *   schedules — array of schedule objects, each with `id` injected from doc.id
 *   loading   — true while the first snapshot has not arrived yet
 *   error     — Error object if the Firestore listener fails, otherwise null
 */
export const useSchedulesFirestore = () => {
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading]     = useState(true);
  const [error, setError]         = useState(null);

  useEffect(() => {
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const todayStr = startOfToday.toISOString();

    // Auto-remove past schedules
    const removePastSchedules = async () => {
      try {
        const pastQuery = query(
          collection(db, COLLECTION),
          where('departureTime', '<', todayStr)
        );
        const snapshot = await getDocs(pastQuery);
        snapshot.forEach((d) => {
          deleteDoc(doc(db, COLLECTION, d.id)).catch(console.error);
        });
      } catch (err) {
        console.error('Failed to remove past schedules:', err);
      }
    };
    
    removePastSchedules();

    // Order by departureTime ascending and show only today and upcoming
    const q = query(
      collection(db, COLLECTION),
      where('departureTime', '>=', todayStr),
      orderBy('departureTime', 'asc')
    );

    // Subscribe to real-time updates
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setSchedules(data);
        setLoading(false);
        setError(null);
      },
      (err) => {
        // Surface listener failures in the UI via the error state
        console.error('useSchedulesFirestore: snapshot error', err);
        setError(err);
        setLoading(false);
      }
    );

    // Auto-unsubscribe when the component using this hook unmounts
    return () => unsubscribe();
  }, []);

  return { schedules, loading, error };
};
