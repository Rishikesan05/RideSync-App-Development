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

/**
 * Approve a pending admin.
 * Promotes role: 'admin_pending' → 'admin'
 * Sets the Firebase Auth custom claim so Firestore rules take effect immediately.
 */
async function approveAdmin(uid, approverUid) {
  const userRef = usersCollection.doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    const err = new Error('User not found.');
    err.statusCode = 404;
    throw err;
  }

  const userData = userDoc.data();

  // Guard: only admin_pending users can be approved this way
  if (userData.role !== ROLES.ADMIN_PENDING) {
    const err = new Error(
      `User is not pending admin approval. Current role: "${userData.role}".`
    );
    err.statusCode = 400;
    throw err;
  }

  // Promote in Firestore
  await userRef.update({
    role: ROLES.ADMIN,
    approvedBy: approverUid,    // track which admin approved this person
    approvedAt: new Date(),
    updatedAt: new Date(),
  });

  // Promote the Firebase Auth JWT custom claim
  // (new claim takes effect on the user's next token refresh)
  await auth.setCustomUserClaims(uid, { role: ROLES.ADMIN });

  return {
    uid,
    role: ROLES.ADMIN,
    message: 'Admin approved successfully. They will have admin access on next sign-in.',
  };
}

/**
 * Reject a pending admin.
 * Reverts role: 'admin_pending' → 'passenger'
 */
async function rejectAdmin(uid, approverUid) {
  const userRef = usersCollection.doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    const err = new Error('User not found.');
    err.statusCode = 404;
    throw err;
  }

  const userData = userDoc.data();

  if (userData.role !== ROLES.ADMIN_PENDING) {
    const err = new Error(
      `User is not pending admin approval. Current role: "${userData.role}".`
    );
    err.statusCode = 400;
    throw err;
  }

  // Revert to passenger in Firestore
  await userRef.update({
    role: ROLES.PASSENGER,
    rejectedBy: approverUid,    // track which admin rejected
    rejectedAt: new Date(),
    updatedAt: new Date(),
  });

  // Revert the JWT claim as well
  await auth.setCustomUserClaims(uid, { role: ROLES.PASSENGER });

  return {
    uid,
    role: ROLES.PASSENGER,
    message: 'Admin request rejected. User has been reverted to passenger.',
  };
}

module.exports = {
  getUsers,
  approveOperator,
  rejectOperator,
  approveAdmin,
  rejectAdmin,
};

