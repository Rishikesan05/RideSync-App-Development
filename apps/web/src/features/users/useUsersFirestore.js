import { useState, useEffect } from 'react';
import { collection, onSnapshot, query, where, orderBy } from 'firebase/firestore';
import { db } from '../../api/firebase';

/**
 * useUsersFirestore
 *
 * Fetches all three user categories directly from Firestore in real-time:
 *  - passengers: docs in 'users' collection with role === 'passenger' (or no role)
 *  - operators:  docs in 'operators' collection
 *  - admins:     docs in 'users' collection with role === 'admin'
 *
 * Returns { passengers, operators, admins, loading, error }
 */
export const useUsersFirestore = () => {
  const [passengers, setPassengers] = useState([]);
  const [operators, setOperators] = useState([]);
  const [admins, setAdmins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let loadingCount = 3; // track all 3 listeners

    const decrementLoading = () => {
      loadingCount -= 1;
      if (loadingCount <= 0) setLoading(false);
    };

    const handleError = (err) => {
      console.error('[useUsersFirestore] Error:', err);
      setError(err.message || 'Failed to fetch users');
      decrementLoading();
    };

    // ── Passengers: 'users' collection where role is 'passenger' or not set ──
    const passengersQuery = query(
      collection(db, 'users'),
      where('role', 'in', ['passenger', 'user'])
    );
    const unsubPassengers = onSnapshot(
      passengersQuery,
      (snap) => {
        const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        setPassengers(docs);
        decrementLoading();
      },
      handleError
    );

    // ── Operators: 'operators' collection ─────────────────────────────────
    const unsubOperators = onSnapshot(
      collection(db, 'operators'),
      (snap) => {
        const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        setOperators(docs);
        decrementLoading();
      },
      handleError
    );

    // ── Admins: 'users' collection where role === 'admin' ─────────────────
    const adminsQuery = query(
      collection(db, 'users'),
      where('role', '==', 'admin')
    );
    const unsubAdmins = onSnapshot(
      adminsQuery,
      (snap) => {
        const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        setAdmins(docs);
        decrementLoading();
      },
      handleError
    );

    return () => {
      unsubPassengers();
      unsubOperators();
      unsubAdmins();
    };
  }, []);

  return { passengers, operators, admins, loading, error };
};
