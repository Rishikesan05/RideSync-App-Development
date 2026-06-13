/**
 * useBusesFirestore.js
 *
 * Real-time Firestore hook for the `buses` collection.
 * Uses onSnapshot so the Fleet UI updates instantly whenever any bus document
 * is created, updated, or deleted — no manual refresh needed.
 *
 * Usage:
 *   const { buses, loading, error } = useBusesFirestore();
 *
 * Replaces the React Query-based useBusesList() which only polled on mount
 * via the old axios REST endpoint.
 */

import { useState, useEffect } from 'react';
import {
  collection,
  onSnapshot,
  query,
  orderBy,
} from 'firebase/firestore';
import { db } from '../../api/firebase';

const COLLECTION = 'buses';

/**
 * useBusesFirestore
 *
 * Returns:
 *   buses   — array of bus objects, each with `id` injected from doc.id
 *   loading — true while the first snapshot hasn't arrived yet
 *   error   — Error object if Firestore listener fails, otherwise null
 */
export const useBusesFirestore = () => {
  const [buses, setBuses]     = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);

  useEffect(() => {
    // Order by plateNumber ascending for a consistent list order
    const q = query(
      collection(db, COLLECTION),
      orderBy('plateNumber', 'asc')
    );

    // Subscribe to real-time updates
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setBuses(data);
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error('useBusesFirestore: snapshot error', err);
        setError(err);
        setLoading(false);
      }
    );

    // Clean up listener when component unmounts
    return () => unsubscribe();
  }, []);

  return { buses, loading, error };
};
