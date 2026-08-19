/**
 * RideSync — Fare Repository
 *
 * Firestore data access layer for the /fares collection.
 */
const { db } = require('../../config/firebase.config');

const collection = db.collection('fares');

async function getByRouteId(routeId) {
  const snapshot = await collection
    .where('routeId', '==', routeId)
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getByRouteAndClass(routeId, busClass) {
  const snapshot = await collection
    .where('routeId', '==', routeId)
    .where('class', '==', busClass)
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  const doc = snapshot.docs[0];
  return { id: doc.id, ...doc.data() };
}

async function getById(fareId) {
  const doc = await collection.doc(fareId).get();
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

async function update(fareId, data) {
  const docRef = collection.doc(fareId);
  const doc = await docRef.get();
  if (!doc.exists) return null;

  const updateData = { ...data, updatedAt: new Date() };
  await docRef.update(updateData);
  return { id: fareId, ...doc.data(), ...updateData };
}

module.exports = {
  getByRouteId,
  getByRouteAndClass,
  getById,
  create,
  update,
};
