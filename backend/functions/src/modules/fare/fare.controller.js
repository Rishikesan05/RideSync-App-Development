/**
 * RideSync — Fare Controller
 *
 * Express router for /api/fare and /api/fares endpoints.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const validate = require('../../middleware/validate.middleware');
const fareService = require('./fare.service');
const { createFareSchema, updateFareSchema } = require('./fare.schema');

/**
 * GET /api/fare?scheduleId=X&fromStop=A&toStop=B&class=AC
 * Calculate fare estimate. Accessible by any authenticated user.
 */
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const { scheduleId, fromStop, toStop, class: busClass } = req.query;

    if (!scheduleId || !fromStop || !toStop) {
      return res.status(400).json({
        success: false,
        error: 'Missing required query params: scheduleId, fromStop, toStop.',
      });
    }

    const breakdown = await fareService.calculateFare(
      scheduleId,
      fromStop,
      toStop,
      busClass
    );
    res.json({ success: true, data: breakdown });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/fare/rules/:routeId
 * Get all fare rules for a specific route.
 */
router.get('/rules/:routeId', authMiddleware, async (req, res, next) => {
  try {
    const fares = await fareService.getFaresByRoute(req.params.routeId);
    res.json({ success: true, data: fares });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/fare/rules
 * Admin: create a new fare rule.
 */
router.post(
  '/rules',
  authMiddleware,
  rbac('admin'),
  validate(createFareSchema),
  async (req, res, next) => {
    try {
      const fare = await fareService.createFare(req.body);
      res.status(201).json({ success: true, data: fare });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * PUT /api/fare/rules/:id
 * Admin: update a fare rule.
 */
router.put(
  '/rules/:id',
  authMiddleware,
  rbac('admin'),
  validate(updateFareSchema),
  async (req, res, next) => {
    try {
      const fare = await fareService.updateFare(req.params.id, req.body);
      res.json({ success: true, data: fare });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
