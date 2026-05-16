/**
 * RideSync — Notification Service
 *
 * FCM-only push notification dispatch.
 * No SMS/Twilio — all communication is via Firebase Cloud Messaging.
 *
 * Also writes to the in-app notification inbox:
 *   /notifications/{uid}/items/{notifId}
 */
const { db, messaging } = require('../../config/firebase.config');

const usersCollection = db.collection('users');

/**
 * Send a push notification to a single user.
 *
 * @param {string} uid         - Target user's Firebase Auth UID
 * @param {Object} payload     - { title, body, type, bookingId? }
 */
async function sendToUser(uid, payload) {
  // 1. Fetch user to get FCM token
  const userDoc = await usersCollection.doc(uid).get();
  if (!userDoc.exists) {
    console.warn(`Notification skipped: user ${uid} not found.`);
    return { sent: false, reason: 'User not found.' };
  }

  const { fcmToken } = userDoc.data();

  // 2. Send FCM push if token exists
  let fcmResult = null;
  if (fcmToken) {
    try {
      fcmResult = await messaging.send({
        token: fcmToken,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: {
          type: payload.type || 'alert',
          bookingId: payload.bookingId || '',
        },
      });
    } catch (err) {
      // Token may be stale — log but don't throw
      console.warn(`FCM send failed for ${uid}:`, err.message);
    }
  }

  // 3. Write to in-app notification inbox
  await db
    .collection('notifications')
    .doc(uid)
    .collection('items')
    .add({
      title: payload.title,
      body: payload.body,
      type: payload.type || 'alert',
      isRead: false,
      createdAt: new Date(),
    });

  return { sent: true, fcmResult };
}

/**
 * Broadcast a notification to all passengers with confirmed bookings
 * on a specific schedule.
 *
 * @param {string} scheduleId
 * @param {Object} payload - { title, body, type }
 */
async function broadcastToSchedule(scheduleId, payload) {
  // 1. Query confirmed bookings for this schedule
  const bookingsSnap = await db
    .collection('bookings')
    .where('scheduleId', '==', scheduleId)
    .where('status', '==', 'confirmed')
    .get();

  if (bookingsSnap.empty) {
    return { sent: 0, message: 'No confirmed bookings for this schedule.' };
  }

  // 2. Extract unique passenger IDs
  const passengerIds = [
    ...new Set(bookingsSnap.docs.map((doc) => doc.data().passengerId)),
  ];

  // 3. Fetch all FCM tokens in batch
  const tokens = [];
  const batch = db.batch();

  for (const pid of passengerIds) {
    const userDoc = await usersCollection.doc(pid).get();
    if (userDoc.exists && userDoc.data().fcmToken) {
      tokens.push(userDoc.data().fcmToken);
    }

    // 4. Write to each passenger's in-app inbox
    const notifRef = db
      .collection('notifications')
      .doc(pid)
      .collection('items')
      .doc();

    batch.set(notifRef, {
      title: payload.title,
      body: payload.body,
      type: payload.type || 'alert',
      isRead: false,
      createdAt: new Date(),
    });
  }

  // 5. Commit all inbox writes
  await batch.commit();

  // 6. Send multicast FCM if tokens exist
  let fcmResult = null;
  if (tokens.length > 0) {
    try {
      fcmResult = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: {
          type: payload.type || 'alert',
          scheduleId,
        },
      });
    } catch (err) {
      console.warn('FCM multicast failed:', err.message);
    }
  }

  return {
    sent: passengerIds.length,
    fcmTokensUsed: tokens.length,
    fcmResult,
  };
}

module.exports = {
  sendToUser,
  broadcastToSchedule,
};
