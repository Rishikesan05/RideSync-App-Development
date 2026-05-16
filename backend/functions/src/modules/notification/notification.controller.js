/**
 * RideSync — Notification Controller
 *
 * Express router for /api/notify endpoints. Admin-only broadcast.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const notificationService = require('./notification.service');

/**
 * POST /api/notify/broadcast
 * Admin: broadcast FCM notification to all passengers on a schedule.
 * Body: { scheduleId, title, body, type? }
 */
router.post('/broadcast', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { scheduleId, title, body, type } = req.body;

    if (!scheduleId || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: scheduleId, title, body.',
      });
    }

    const result = await notificationService.broadcastToSchedule(scheduleId, {
      title,
      body,
      type,
    });

    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/notify/user/:uid
 * Admin: send notification to a specific user.
 * Body: { title, body, type?, bookingId? }
 */
router.post('/user/:uid', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { title, body, type, bookingId } = req.body;

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: title, body.',
      });
    }

    const result = await notificationService.sendToUser(req.params.uid, {
      title,
      body,
      type,
      bookingId,
    });

    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
