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

    let pendingFromUsers = [];
    let pendingFromOps = [];
    const updatePending = () => {
      const byId = {};
      pendingFromUsers.forEach(u => { byId[u.id] = u; });
      pendingFromOps.forEach(u => { byId[u.id] = u; });
      setPending(Object.values(byId));
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
        const allOps = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        const approvedOps = [];
        const pOps = [];
        allOps.forEach(o => {
          if (o.status === 'pending_review' || o.status === 'pending' || o.isApproved === false) {
            pOps.push({ ...o, role: o.role || 'operator_pending' });
          } else {
            approvedOps.push(o);
          }
        });
        setOperators(approvedOps);
        pendingFromOps = pOps;
        updatePending();
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

    // ── 4. Pending from 'users' collection ────────────────────────────────
    const unsubPendingRoles = onSnapshot(
      query(
        collection(db, 'users'),
        where('role', 'in', ['operator_pending', 'pending', 'operator_request'])
      ),
      (snap) => {
        pendingFromUsers = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        updatePending();
        decrementLoading();
      },
      handleError
    );

    // Also listen for users with status == 'pending_review'
    const unsubPendingStatus = onSnapshot(
      query(collection(db, 'users'), where('status', '==', 'pending_review')),
      (snap) => {
        // Merge them into pendingFromUsers
        const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        const existingIds = new Set(pendingFromUsers.map(u => u.id));
        docs.forEach(d => {
          if (!existingIds.has(d.id)) {
            pendingFromUsers.push(d);
          }
        });
        updatePending();
      },
      handleError
    );

    return () => {
      unsubPassengers();
      unsubOperators();
      unsubAdmins();
      unsubPendingRoles();
      unsubPendingStatus();
    };
  }, []);

  return { passengers, operators, admins, pending, loading, error };
};
