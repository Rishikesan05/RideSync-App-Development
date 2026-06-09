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
  const now = new Date();
  
  return snapshot.docs.map((doc) => {
    const data = doc.data();
    let status = data.status;

    // Check if the schedule has expired based on departureTime
    if (data.departureTime && data.departureTime.toDate) {
      const departureTime = data.departureTime.toDate();
      // Only expire if it's still 'scheduled' and the departure time is in the past
      if (departureTime < now && status === 'scheduled') {
        status = 'expired';
        // Fire and forget update to firestore
        doc.ref.update({ status: 'expired', updatedAt: now }).catch(console.error);
      }
    }

    return { id: doc.id, ...data, status };
  });
}

async function getById(scheduleId) {
  const doc = await collection.doc(scheduleId).get();
  if (!doc.exists) return null;
  
  const data = doc.data();
  let status = data.status;
  const now = new Date();

  if (data.departureTime && data.departureTime.toDate) {
    const departureTime = data.departureTime.toDate();
    if (departureTime < now && status === 'scheduled') {
      status = 'expired';
      doc.ref.update({ status: 'expired', updatedAt: now }).catch(console.error);
    }
  }

  return { id: doc.id, ...data, status };
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

  await docRef.delete();
  return { id: scheduleId, deleted: true };
}

module.exports = {
  getAll,
  getById,
  create,
  update,
  remove,
};
