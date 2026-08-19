/**
 * RideSync — Schedule Controller
 *
 * Express router for /api/schedules endpoints.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const validate = require('../../middleware/validate.middleware');
const scheduleService = require('./schedule.service');
const { createScheduleSchema, updateScheduleSchema } = require('./schedule.schema');

/**
 * GET /api/schedules
 * Query schedules. Supports filters: ?routeId=X&status=Y&operatorId=Z
 */
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const { routeId, status, operatorId } = req.query;
    const schedules = await scheduleService.getAllSchedules({
      routeId,
      status,
      operatorId,
    });
    res.json({ success: true, data: schedules });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/schedules/:id
 * Get schedule detail.
 */
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const schedule = await scheduleService.getScheduleById(req.params.id);
    res.json({ success: true, data: schedule });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/schedules/:id/seats
 * Live seat availability map for a schedule.
 */
router.get('/:id/seats', authMiddleware, async (req, res, next) => {
  try {
    const seats = await scheduleService.getSeats(req.params.id);
    res.json({ success: true, data: seats });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/schedules
 * Admin: create a new schedule.
 */
router.post(
  '/',
  authMiddleware,
  rbac('admin'),
  validate(createScheduleSchema),
  async (req, res, next) => {
    try {
      const schedule = await scheduleService.createSchedule(req.body);
      res.status(201).json({ success: true, data: schedule });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * PUT /api/schedules/:id
 * Operator or Admin: update status, delay, current stop.
 */
router.put(
  '/:id',
  authMiddleware,
  rbac('operator', 'admin'),
  validate(updateScheduleSchema),
  async (req, res, next) => {
    try {
      const schedule = await scheduleService.updateSchedule(req.params.id, req.body);
      res.json({ success: true, data: schedule });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * DELETE /api/schedules/:id
 * Admin: cancel a schedule.
 */
router.delete('/:id', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const result = await scheduleService.cancelSchedule(req.params.id);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
