const admin = require('firebase-admin');

/**
 * RideSync - Feedback Service
 * Handles business logic for passenger ratings and feedback.
 */

const db = admin.firestore();

/**
 * Submit feedback for a specific schedule.
 * Only allows users who actually had a booking on that schedule to rate it.
 * 
 * @param {string} userId - ID of the passenger
 * @param {Object} feedbackData - { scheduleId, rating, comment }
 * @returns {Object} - Result of the submission
 */
exports.submitFeedback = async (userId, feedbackData) => {
  const { scheduleId, rating, comment } = feedbackData;

  if (!scheduleId || !rating) {
    throw new Error('Schedule ID and Rating are required.');
  }

  if (rating < 1 || rating > 5) {
    throw new Error('Rating must be between 1 and 5.');
  }

  // 1. Verify the user actually booked this schedule
  const bookingsSnapshot = await db.collection('bookings')
    .where('userId', '==', userId)
    .where('scheduleId', '==', scheduleId)
    .get();

  if (bookingsSnapshot.empty) {
    throw new Error('You cannot rate a trip you did not book.');
  }

  // Check if they already submitted feedback for this schedule
  const existingFeedback = await db.collection('feedback')
    .where('userId', '==', userId)
    .where('scheduleId', '==', scheduleId)
    .get();

  if (!existingFeedback.empty) {
    throw new Error('You have already submitted feedback for this trip.');
  }

  // 2. Fetch the schedule to get the bus ID and operator ID so we can aggregate later
  const scheduleDoc = await db.collection('schedules').doc(scheduleId).get();
  if (!scheduleDoc.exists) {
    throw new Error('Schedule not found.');
  }
  const scheduleData = scheduleDoc.data();

  // 3. Create the feedback document
  const feedbackRef = db.collection('feedback').doc();
  const feedbackRecord = {
    id: feedbackRef.id,
    userId,
    scheduleId,
    busId: scheduleData.busId || null,
    operatorId: scheduleData.operatorId || null,
    rating,
    comment: comment || '',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await feedbackRef.set(feedbackRecord);

  // 4. (Optional/Future Phase) Update aggregated ratings for the Bus or Operator
  // This could be done here or in a background Cloud Function trigger.
  // We'll leave it as a direct write for now.

  return { success: true, id: feedbackRef.id, message: 'Feedback submitted successfully' };
};

/**
 * Get feedback summary for a specific bus (Admin/Operator view)
 */
exports.getBusFeedback = async (busId) => {
  const snapshot = await db.collection('feedback')
    .where('busId', '==', busId)
    .orderBy('createdAt', 'desc')
    .limit(50)
    .get();

  const reviews = [];
  let totalRating = 0;

  snapshot.forEach(doc => {
    const data = doc.data();
    reviews.push(data);
    totalRating += data.rating;
  });

  const averageRating = reviews.length > 0 ? (totalRating / reviews.length).toFixed(1) : 0;

  return {
    busId,
    totalReviews: reviews.length,
    averageRating: Number(averageRating),
    reviews
  };
};
