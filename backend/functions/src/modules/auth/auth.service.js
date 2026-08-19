/**
 * RideSync — Auth Service
 *
 * Handles user registration (Firestore profile + custom claims)
 * and admin-level role assignment.
 */
const { auth, db } = require('../../config/firebase.config');
const { ROLES } = require('../../shared/constants');

const usersCollection = db.collection('users');

/**
 * Register a new user profile in Firestore and set their role as a custom claim.
 * Called after the client-side Firebase Auth sign-up.
 */
async function registerUser({ uid, name, email, phone, role }) {
  // Validate role
  const validRoles = Object.values(ROLES);
  if (!validRoles.includes(role)) {
    const err = new Error(`Invalid role: "${role}". Must be one of: ${validRoles.join(', ')}`);
    err.statusCode = 400;
    throw err;
  }

  // Check if user profile already exists
  const existingDoc = await usersCollection.doc(uid).get();
  if (existingDoc.exists) {
    const err = new Error('User profile already exists.');
    err.statusCode = 409;
    throw err;
  }

  // Set custom claims on Firebase Auth
  const claims = { role };
  await auth.setCustomUserClaims(uid, claims);

  // Create Firestore user document
  const now = new Date();
  const userData = {
    uid,
    name,
    email,
    phone: phone || null,
    role,
    busId: null,
    fcmToken: null,
    createdAt: now,
    updatedAt: now,
  };

  await usersCollection.doc(uid).set(userData);

  return { uid, role, message: 'User registered successfully.' };
}

/**
 * Admin-only: assign or change a user's role.
 * Also updates the custom claim.
 */
async function setUserRole({ targetUid, role, busId }) {
  const validRoles = Object.values(ROLES);
  if (!validRoles.includes(role)) {
    const err = new Error(`Invalid role: "${role}". Must be one of: ${validRoles.join(', ')}`);
    err.statusCode = 400;
    throw err;
  }

  // Check target user exists
  const userDoc = await usersCollection.doc(targetUid).get();
  if (!userDoc.exists) {
    const err = new Error('Target user not found.');
    err.statusCode = 404;
    throw err;
  }

  // Build claims
  const claims = { role };
  if (role === ROLES.OPERATOR && busId) {
    claims.busId = busId;
  }

  // Update Firebase Auth custom claims
  await auth.setCustomUserClaims(targetUid, claims);

  // Update Firestore document
  const updateData = {
    role,
    updatedAt: new Date(),
  };
  if (role === ROLES.OPERATOR && busId) {
    updateData.busId = busId;
  }

  await usersCollection.doc(targetUid).update(updateData);

  return { uid: targetUid, role, message: 'Role updated successfully.' };
}

module.exports = {
  registerUser,
  setUserRole,
};
