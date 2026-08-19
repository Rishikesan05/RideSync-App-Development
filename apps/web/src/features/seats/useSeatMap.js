import { useState, useEffect } from 'react';
import { collection, query, onSnapshot, orderBy } from 'firebase/firestore';
import { db } from '../../api/firebase';

/**
 * Custom Hook for Real-Time Seat Map Synchronization
 * @param {string} rideId 
 * @returns {Object} { seats, loading, error }
 */
export const useSeatMap = (rideId) => {
  const [seats, setSeats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!rideId) return;

    setLoading(true);
    const seatsRef = collection(db, "schedules", rideId, "seats");
    const q = query(seatsRef, orderBy("seatNumber", "asc"));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const seatsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setSeats(seatsData);
      setLoading(false);
    }, (err) => {
      console.error("Seat map listener error:", err);
      setError(err);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [rideId]);

  return { seats, loading, error };
};
