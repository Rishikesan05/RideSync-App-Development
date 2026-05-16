/**
 * RideSync — Booking Repository
 *
 * Firestore data access for the /bookings collection.
 */
const { db } = require('../../config/firebase.config');

const collection = db.collection('bookings');

async function getById(bookingId) {
  const doc = await collection.doc(bookingId).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function getByPassenger(passengerId) {
  const snapshot = await collection
    .where('passengerId', '==', passengerId)
    .orderBy('bookedAt', 'desc')
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getBySchedule(scheduleId) {
  const snapshot = await collection
    .where('scheduleId', '==', scheduleId)
    .where('status', '==', 'confirmed')
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function create(data) {
  const now = new Date();
  const docRef = await collection.add({
    ...data,
    bookedAt: now,
    updatedAt: now,
  });
  return { id: docRef.id, ...data, bookedAt: now };
}

async function updateStatus(bookingId, status) {
  const docRef = collection.doc(bookingId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  await docRef.update({ status, updatedAt: new Date() });
  return { id: bookingId, ...doc.data(), status };
}

module.exports = {
  getById,
  getByPassenger,
  getBySchedule,
  create,
  updateStatus,
};
