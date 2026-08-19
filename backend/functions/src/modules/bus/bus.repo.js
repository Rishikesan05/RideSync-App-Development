/**
 * RideSync — Bus Repository
 *
 * Firestore data access layer for the /buses collection.
 */
const { db } = require('../../config/firebase.config');

const collection = db.collection('buses');

async function getAll() {
  const snapshot = await collection
    .where('isActive', '==', true)
    .orderBy('createdAt', 'desc')
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getById(busId) {
  const doc = await collection.doc(busId).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function create(data) {
  const now = new Date();
  const docRef = await collection.add({
    ...data,
    isActive: true,
    createdAt: now,
  });
  return { id: docRef.id, ...data };
}

async function update(busId, data) {
  const docRef = collection.doc(busId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  await docRef.update(data);
  return { id: busId, ...doc.data(), ...data };
}

async function deactivate(busId) {
  const docRef = collection.doc(busId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  await docRef.update({ isActive: false });
  return { id: busId, deactivated: true };
}

module.exports = {
  getAll,
  getById,
  create,
  update,
  deactivate,
};
