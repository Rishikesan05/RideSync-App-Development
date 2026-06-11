import { 
  collection, 
  doc, 
  writeBatch, 
  runTransaction, 
  query, 
  onSnapshot,
  serverTimestamp 
} from "firebase/firestore";
import { db } from "../../api/firebase";
import { generateBusLayout } from "./SeatLayouts";

/**
 * Seat Service for RideSync
 * Handles seat initialization, real-time sync, and atomic booking
 */

/**
 * Initializes seats for a new ride
 * @param {string} rideId 
 * @param {string} layoutType - '35' or '54'
 */
export const initializeRideSeats = async (rideId, layoutType) => {
  const seats = generateBusLayout(layoutType);
  const batch = writeBatch(db);
  
  const seatsRef = collection(db, "schedules", rideId, "seats");

  seats.forEach((seat) => {
    const seatDoc = doc(seatsRef, seat.seatNumber.toString());
    batch.set(seatDoc, {
      ...seat,
      layoutType,
      passengerId: null,
      bookedAt: null,
      updatedAt: serverTimestamp()
    });
  });

  await batch.commit();
};

/**
 * Atomic seat booking using Firestore Transactions
 * Prevents double booking by checking status before update
 */
export const bookSeat = async (rideId, seatNumber, passengerId) => {
  const seatRef = doc(db, "schedules", rideId, "seats", seatNumber.toString());

  try {
    await runTransaction(db, async (transaction) => {
      const seatSnap = await transaction.get(seatRef);
      
      if (!seatSnap.exists()) {
        throw new Error("Seat does not exist!");
      }

      const seatData = seatSnap.data();
      
      if (seatData.status !== 'available') {
        throw new Error(`Seat ${seatNumber} is already ${seatData.status}`);
      }

      // Perform the update
      transaction.update(seatRef, {
        status: 'reserved',
        passengerId: passengerId,
        bookedAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
    });
    return { success: true };
  } catch (error) {
    console.error("Booking Transaction Failed: ", error);
    return { success: false, error: error.message };
  }
};

/**
 * Admin: Update seat status (Block, VIP, Driver)
 */
export const updateSeatMeta = async (rideId, seatNumber, updates) => {
  const seatRef = doc(db, "schedules", rideId, "seats", seatNumber.toString());
  const batch = writeBatch(db);
  batch.update(seatRef, {
    ...updates,
    updatedAt: serverTimestamp()
  });
  await batch.commit();
};

/**
 * Admin: Move a booking from an old seat to a new seat atomically using a transaction
 */
export const relocateSeat = async (rideId, oldSeatNumber, newSeatNumber, oldSeatData) => {
  const oldSeatRef = doc(db, "schedules", rideId, "seats", oldSeatNumber.toString());
  const newSeatRef = doc(db, "schedules", rideId, "seats", newSeatNumber.toString());

  try {
    await runTransaction(db, async (transaction) => {
      const newSeatSnap = await transaction.get(newSeatRef);
      if (!newSeatSnap.exists()) {
        throw new Error("Target seat does not exist!");
      }
      
      const newSeatData = newSeatSnap.data();
      if (newSeatData.status !== 'available') {
        throw new Error(`Target seat ${newSeatNumber} is already ${newSeatData.status}`);
      }

      // Free old seat (reset status and clear passenger info)
      transaction.update(oldSeatRef, {
        status: 'available',
        passengerId: null,
        bookedAt: null,
        updatedAt: serverTimestamp()
      });

      // Move booking info to target seat
      transaction.update(newSeatRef, {
        status: oldSeatData.status || 'booked',
        passengerId: oldSeatData.passengerId || null,
        bookedAt: oldSeatData.bookedAt || serverTimestamp(),
        updatedAt: serverTimestamp()
      });
    });
    return { success: true };
  } catch (error) {
    console.error("Relocation Transaction Failed: ", error);
    return { success: false, error: error.message };
  }
};

