/**
 * RideSync — Route Repository
 *
 * Firestore data access layer for the /routes collection.
 */
const { db } = require('../../config/firebase.config');

const collection = db.collection('routes');

async function getAll() {
  const snapshot = await collection
    .where('isActive', '==', true)
    .orderBy('createdAt', 'desc')
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getById(routeId) {
  const doc = await collection.doc(routeId).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function create(data) {
  const now = new Date();
  const docRef = await collection.add({
    ...data,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  });
  return { id: docRef.id, ...data };
}

async function update(routeId, data) {
  const docRef = collection.doc(routeId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  const updateData = { ...data, updatedAt: new Date() };
  await docRef.update(updateData);
  return { id: routeId, ...doc.data(), ...updateData };
}

async function deactivate(routeId) {
  const docRef = collection.doc(routeId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  await docRef.update({ isActive: false, updatedAt: new Date() });
  return { id: routeId, deactivated: true };
}

module.exports = {
  getAll,
  getById,
  create,
  update,
  deactivate,
};
