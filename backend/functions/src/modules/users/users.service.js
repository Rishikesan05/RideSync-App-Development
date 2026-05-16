/**
 * RideSync — Users Service
 */
const { db, auth } = require('../../config/firebase.config');
const { ROLES } = require('../../shared/constants');

const usersCollection = db.collection('users');

/**
 * Get all users, or filter by role
 */
async function getUsers(role) {
  let query = usersCollection;
  if (role) {
    query = query.where('role', '==', role);
  }
  const snapshot = await query.get();
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

/**
 * Approve an operator
 */
async function approveOperator(uid) {
  const userRef = usersCollection.doc(uid);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }
  
  const userData = userDoc.data();
  if (userData.role !== ROLES.OPERATOR_PENDING) {
    const err = new Error('User is not pending approval');
    err.statusCode = 400;
    throw err;
  }

  // Update in Firestore
  await userRef.update({
    role: ROLES.OPERATOR,
    updatedAt: new Date(),
  });

  // Update custom claims in Firebase Auth
  await auth.setCustomUserClaims(uid, { role: ROLES.OPERATOR });

  return { message: 'Operator approved successfully' };
}

/**
 * Reject an operator
 */
async function rejectOperator(uid) {
  const userRef = usersCollection.doc(uid);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  const userData = userDoc.data();
  if (userData.role !== ROLES.OPERATOR_PENDING) {
    const err = new Error('User is not pending approval');
    err.statusCode = 400;
    throw err;
  }

  // Revert back to passenger or just delete? Let's revert to passenger.
  await userRef.update({
    role: ROLES.PASSENGER,
    updatedAt: new Date(),
  });

  await auth.setCustomUserClaims(uid, { role: ROLES.PASSENGER });

  return { message: 'Operator rejected and reverted to passenger' };
}

module.exports = {
  getUsers,
  approveOperator,
  rejectOperator,
};
