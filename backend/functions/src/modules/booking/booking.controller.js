/**
 * RideSync — Booking Controller
 *
 * Express router for /api/bookings endpoints.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const validate = require('../../middleware/validate.middleware');
const bookingService = require('./booking.service');
const { createBookingSchema } = require('./booking.schema');

/**
 * POST /api/bookings
 * Passenger: book a seat (uses Firestore transaction).
 * Body: { scheduleId, seatNo, fromStop, toStop }
 */
router.post(
  '/',
  authMiddleware,
  rbac('passenger'),
  validate(createBookingSchema),
  async (req, res, next) => {
    try {
      const passengerId = req.user.uid;
      const { scheduleId, seatNo, fromStop, toStop } = req.body;

      const booking = await bookingService.bookSeat({
        passengerId,
        scheduleId,
        seatNo,
        fromStop,
        toStop,
      });

      res.status(201).json({ success: true, data: booking });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * GET /api/bookings/my
 * Passenger: own booking history.
 */
router.get('/my', authMiddleware, rbac('passenger'), async (req, res, next) => {
  try {
    const passengerId = req.user.uid;
    const bookings = await bookingService.getMyBookings(passengerId);
    res.json({ success: true, data: bookings });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/bookings/schedule/:id
 * Operator/Admin: view all confirmed bookings for a schedule (manifest).
 */
router.get(
  '/schedule/:id',
  authMiddleware,
  rbac('operator', 'admin'),
  async (req, res, next) => {
    try {
      const bookings = await bookingService.getBookingsBySchedule(req.params.id);
      res.json({ success: true, data: bookings });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * GET /api/bookings/:id
 * Booking detail. Accessible to owner, operator, admin.
 */
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const booking = await bookingService.getBookingById(
      req.params.id,
      req.user
    );
    res.json({ success: true, data: booking });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/bookings/:id/cancel
 * Cancel booking. Accessible to owner or admin.
 */
router.put('/:id/cancel', authMiddleware, async (req, res, next) => {
  try {
    const result = await bookingService.cancelBooking(req.params.id, req.user);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
