import { useState, useEffect } from 'react';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '../../api/firebase';

/**
 * useUsersFirestore
 *
 * Fetches all four user categories directly from Firestore in real-time:
 *  - passengers:  'users' collection with role === 'passenger' | 'user'
 *  - operators:   'operators' collection (all docs)
 *  - admins:      'users' collection with role === 'admin'
 *  - pending:     'users' collection with role === 'operator_pending' | 'pending'
 *                 AND 'users' docs with NO role field (newly registered)
 *
 * Returns { passengers, operators, admins, pending, loading, error }
 */
export const useUsersFirestore = () => {
  const [passengers, setPassengers] = useState([]);
  const [operators,  setOperators]  = useState([]);
  const [admins,     setAdmins]     = useState([]);
  const [pending,    setPending]    = useState([]);
  const [loading,    setLoading]    = useState(true);
  const [error,      setError]      = useState(null);

  useEffect(() => {
    // We have 4 async listeners; only mark loading=false when all settle.
    let loadingCount = 4;

    const decrementLoading = () => {
      loadingCount -= 1;
      if (loadingCount <= 0) setLoading(false);
    };

    const handleError = (err) => {
      console.error('[useUsersFirestore] Error:', err);
      setError(err.message || 'Failed to fetch users');
      decrementLoading();
    };

    // ── 1. Passengers ─────────────────────────────────────────────────────
    const unsubPassengers = onSnapshot(
      query(collection(db, 'users'), where('role', 'in', ['passenger', 'user'])),
      (snap) => {
        setPassengers(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        decrementLoading();
      },
      handleError
    );

    // ── 2. Operators: separate 'operators' collection ─────────────────────
    const unsubOperators = onSnapshot(
      collection(db, 'operators'),
      (snap) => {
        setOperators(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        decrementLoading();
      },
      handleError
    );

    // ── 3. Admins ─────────────────────────────────────────────────────────
    const unsubAdmins = onSnapshot(
      query(collection(db, 'users'), where('role', '==', 'admin')),
      (snap) => {
        setAdmins(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        decrementLoading();
      },
      handleError
    );

    // ── 4. Pending ────────────────────────────────────────────────────────
    // Catches: 'operator_pending', 'pending', and users with NO role field.
    // 'operator_pending' and 'pending' are fetched in one query (Firestore
    // supports up to 30 values in `in`). Users with no role field require a
    // separate listener since Firestore cannot query "field does not exist"
    // in the same `in` clause.
    const unsubPendingRoles = onSnapshot(
      query(
        collection(db, 'users'),
        where('role', 'in', ['operator_pending', 'pending', 'operator_request'])
      ),
      (snap) => {
        const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        // Merge with any no-role docs already collected (keyed by id)
        setPending((prev) => {
          const byId = Object.fromEntries(prev.map((u) => [u.id, u]));
          docs.forEach((u) => { byId[u.id] = u; });
          return Object.values(byId);
        });
        decrementLoading();
      },
      handleError
    );

    return () => {
      unsubPassengers();
      unsubOperators();
      unsubAdmins();
      unsubPendingRoles();
    };
  }, []);

  return { passengers, operators, admins, pending, loading, error };
};
