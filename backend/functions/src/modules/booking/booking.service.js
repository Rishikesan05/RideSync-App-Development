/**
 * RideSync — Booking Service
 *
 * Core booking logic with Firestore transactions for atomic seat locking.
 * This is the most critical service — prevents double-booking via
 * transactional read-then-write on the schedule's seatMap.
 */
const { db } = require('../../config/firebase.config');
const bookingRepo = require('./booking.repo');
const fareService = require('../fare/fare.service');
const notificationService = require('../notification/notification.service');
const { BOOKING_STATUSES } = require('../../shared/constants');

/**
 * Book a seat using a Firestore transaction.
 *
 * Transaction flow:
 *   1. READ schedule document (inside transaction)
 *   2. ASSERT seat is available (null)
 *   3. SET seatMap[seatNo] = passengerId
 *   4. CREATE booking document
 *   5. COMMIT atomically
 *
 * @param {Object} params
 * @param {string} params.passengerId - uid of the booking passenger
 * @param {string} params.scheduleId
 * @param {string} params.seatNo     - e.g. "A1", "B3"
 * @param {string} params.fromStop
 * @param {string} params.toStop
 * @returns {Object} Created booking with fare breakdown
 */
async function bookSeat({ passengerId, scheduleId, seatNo, fromStop, toStop }) {
  const scheduleRef = db.collection('schedules').doc(scheduleId);
  const bookingsCollection = db.collection('bookings');

  // Calculate fare before the transaction (reads are safe outside)
  let fareBreakdown;
  try {
    fareBreakdown = await fareService.calculateFare(
      scheduleId,
      fromStop,
      toStop
    );
  } catch (fareErr) {
    // If no fare rule exists, allow booking with fare = 0
    fareBreakdown = {
      total: 0,
      baseFare: 0,
      segmentKm: 0,
      ratePerKm: 0,
      classMultiplier: 1.0,
      busClass: 'unknown',
    };
    console.warn('Fare calculation failed, booking with fare=0:', fareErr.message);
  }

  // Execute atomic transaction
  const bookingId = await db.runTransaction(async (transaction) => {
    // 1. READ schedule inside transaction
    const scheduleDoc = await transaction.get(scheduleRef);
    if (!scheduleDoc.exists) {
      const err = new Error('Schedule not found.');
      err.statusCode = 404;
      throw err;
    }

    const scheduleData = scheduleDoc.data();

    // Verify schedule is still bookable
    if (scheduleData.status === 'cancelled') {
      const err = new Error('This schedule has been cancelled.');
      err.statusCode = 400;
      throw err;
    }
    if (scheduleData.status === 'completed') {
      const err = new Error('This trip has already been completed.');
      err.statusCode = 400;
      throw err;
    }

    // 2. ASSERT seat is available
    const seatMap = scheduleData.seatMap || {};
    if (!(seatNo in seatMap)) {
      const err = new Error(`Seat "${seatNo}" does not exist on this bus.`);
      err.statusCode = 400;
      throw err;
    }
    if (seatMap[seatNo] !== null) {
      const err = new Error(`Seat "${seatNo}" is already booked.`);
      err.statusCode = 409;
      throw err;
    }

    // 3. Lock the seat — SET seatMap[seatNo] = passengerId
    transaction.update(scheduleRef, {
      [`seatMap.${seatNo}`]: passengerId,
      updatedAt: new Date(),
    });

    // 4. CREATE booking document
    const bookingRef = bookingsCollection.doc();
    const bookingData = {
      passengerId,
      scheduleId,
      fromStop,
      toStop,
      seatNo,
      fare: fareBreakdown.total,
      fareBreakdown: {
        baseFare: fareBreakdown.baseFare,
        segmentKm: fareBreakdown.segmentKm,
        ratePerKm: fareBreakdown.ratePerKm,
        classMultiplier: fareBreakdown.classMultiplier,
        busClass: fareBreakdown.busClass,
      },
      status: BOOKING_STATUSES.CONFIRMED,
      bookedAt: new Date(),
      updatedAt: new Date(),
    };

    transaction.set(bookingRef, bookingData);

    return bookingRef.id;
  });

  // 5. Post-transaction: send notification (non-blocking)
  notificationService
    .sendToUser(passengerId, {
      title: 'Booking Confirmed! 🎉',
      body: `Seat ${seatNo} reserved from ${fromStop} to ${toStop}. Fare: LKR ${fareBreakdown.total}`,
      type: 'booking',
      bookingId,
    })
    .catch((err) => console.warn('Notification failed:', err.message));

  return {
    bookingId,
    seatNo,
    fare: fareBreakdown.total,
    fareBreakdown,
    status: BOOKING_STATUSES.CONFIRMED,
  };
}

/**
 * Get a passenger's own booking history.
 */
async function getMyBookings(passengerId) {
  return bookingRepo.getByPassenger(passengerId);
}

/**
 * Get a booking by ID. Checks ownership or admin/operator role.
 */
async function getBookingById(bookingId, requestingUser) {
  const booking = await bookingRepo.getById(bookingId);
  if (!booking) {
    const err = new Error('Booking not found.');
    err.statusCode = 404;
    throw err;
  }

  // Check access: own booking, or operator/admin
  const isOwner = booking.passengerId === requestingUser.uid;
  const isPrivileged = ['operator', 'admin'].includes(requestingUser.role);
  if (!isOwner && !isPrivileged) {
    const err = new Error('You do not have access to this booking.');
    err.statusCode = 403;
    throw err;
  }

  return booking;
}

/**
 * Cancel a booking. Releases the seat back to available.
 */
async function cancelBooking(bookingId, requestingUser) {
  const booking = await bookingRepo.getById(bookingId);
  if (!booking) {
    const err = new Error('Booking not found.');
    err.statusCode = 404;
    throw err;
  }

  // Check access
  const isOwner = booking.passengerId === requestingUser.uid;
  const isAdmin = requestingUser.role === 'admin';
  if (!isOwner && !isAdmin) {
    const err = new Error('You do not have permission to cancel this booking.');
    err.statusCode = 403;
    throw err;
  }

  if (booking.status === BOOKING_STATUSES.CANCELLED) {
    const err = new Error('Booking is already cancelled.');
    err.statusCode = 400;
    throw err;
  }

  // Release the seat in the schedule
  const scheduleRef = db.collection('schedules').doc(booking.scheduleId);
  await scheduleRef.update({
    [`seatMap.${booking.seatNo}`]: null,
    updatedAt: new Date(),
  });

  // Update booking status
  const updated = await bookingRepo.updateStatus(
    bookingId,
    BOOKING_STATUSES.CANCELLED
  );

  // Notify passenger
  notificationService
    .sendToUser(booking.passengerId, {
      title: 'Booking Cancelled',
      body: `Your reservation for seat ${booking.seatNo} has been cancelled.`,
      type: 'booking',
      bookingId,
    })
    .catch((err) => console.warn('Cancel notification failed:', err.message));

  return updated;
}

/**
 * Get all bookings for a schedule (operator/admin view).
 */
async function getBookingsBySchedule(scheduleId) {
  return bookingRepo.getBySchedule(scheduleId);
}

module.exports = {
  bookSeat,
  getMyBookings,
  getBookingById,
  cancelBooking,
  getBookingsBySchedule,
};
