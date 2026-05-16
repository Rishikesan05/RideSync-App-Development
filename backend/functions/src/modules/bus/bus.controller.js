/**
 * RideSync — Bus Controller
 *
 * Express router for /api/buses endpoints. Admin-only CRUD.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const validate = require('../../middleware/validate.middleware');
const busService = require('./bus.service');
const { createBusSchema, updateBusSchema } = require('./bus.schema');

/**
 * GET /api/buses
 * List all active buses. Accessible by any authenticated user.
 */
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const buses = await busService.getAllBuses();
    res.json({ success: true, data: buses });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/buses/:id
 * Get a specific bus by ID.
 */
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const bus = await busService.getBusById(req.params.id);
    res.json({ success: true, data: bus });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/buses
 * Admin: add a new bus to the fleet.
 */
router.post(
  '/',
  authMiddleware,
  rbac('admin'),
  validate(createBusSchema),
  async (req, res, next) => {
    try {
      const bus = await busService.createBus(req.body);
      res.status(201).json({ success: true, data: bus });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * PUT /api/buses/:id
 * Admin: update bus details.
 */
router.put(
  '/:id',
  authMiddleware,
  rbac('admin'),
  validate(updateBusSchema),
  async (req, res, next) => {
    try {
      const bus = await busService.updateBus(req.params.id, req.body);
      res.json({ success: true, data: bus });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * DELETE /api/buses/:id
 * Admin: deactivate a bus.
 */
router.delete('/:id', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const result = await busService.deactivateBus(req.params.id);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
