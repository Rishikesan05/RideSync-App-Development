/**
 * RideSync — Schedule Repository
 *
 * Firestore data access layer for the /schedules collection.
 */
const { db } = require('../../config/firebase.config');

const collection = db.collection('schedules');

async function getAll(filters = {}) {
  let query = collection.orderBy('departureTime', 'asc');

  if (filters.routeId) {
    query = query.where('routeId', '==', filters.routeId);
  }
  if (filters.status) {
    query = query.where('status', '==', filters.status);
  }
  if (filters.operatorId) {
    query = query.where('operatorId', '==', filters.operatorId);
  }

  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getById(scheduleId) {
  const doc = await collection.doc(scheduleId).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function create(data) {
  const now = new Date();
  const docRef = await collection.add({
    ...data,
    createdAt: now,
    updatedAt: now,
  });
  return { id: docRef.id, ...data };
}

async function update(scheduleId, data) {
  const docRef = collection.doc(scheduleId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  const updateData = { ...data, updatedAt: new Date() };
  await docRef.update(updateData);
  return { id: scheduleId, ...doc.data(), ...updateData };
}

async function remove(scheduleId) {
  const docRef = collection.doc(scheduleId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  await docRef.update({
    status: 'cancelled',
    updatedAt: new Date(),
  });
  return { id: scheduleId, cancelled: true };
}

module.exports = {
  getAll,
  getById,
  create,
  update,
  remove,
};
