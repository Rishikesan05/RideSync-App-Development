/**
 * useRoutesFirestore.js
 *
 * Real-time Firestore hook for the `routes` collection.
 * Uses onSnapshot so the UI updates instantly whenever any route document
 * is created, updated, or deleted — no manual refresh needed.
 *
 * Usage:
 *   const { routes, loading, error } = useRoutesFirestore();
 *
 * Replaces the React Query-based useRoutesList() which only polls on mount.
 */

import { useState, useEffect } from 'react';
import {
  collection,
  onSnapshot,
  query,
  orderBy,
} from 'firebase/firestore';
import { db } from '../../api/firebase';

const COLLECTION = 'routes';

/**
 * useRoutesFirestore
 *
 * Returns:
 *   routes  — array of route objects, each with `id` injected from doc.id
 *   loading — true while the first snapshot hasn't arrived yet
 *   error   — Error object if Firestore listener fails, otherwise null
 */
export const useRoutesFirestore = () => {
  const [routes, setRoutes]   = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);

  useEffect(() => {
    // Order by routeNumber ascending — same as the REST API returned
    const q = query(
      collection(db, COLLECTION),
      orderBy('routeNumber', 'asc')
    );

    // Subscribe to real-time updates
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const data = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setRoutes(data);
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error('useRoutesFirestore: snapshot error', err);
        setError(err);
        setLoading(false);
      }
    );

    // Clean up listener when component unmounts
    return () => unsubscribe();
  }, []);

  return { routes, loading, error };
};
