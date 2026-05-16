/**
 * RideSync — Route Controller
 *
 * Express router for /api/routes endpoints.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const validate = require('../../middleware/validate.middleware');
const routeService = require('./route.service');
const { createRouteSchema, updateRouteSchema } = require('./route.schema');

/**
 * GET /api/routes
 * List all active routes. Accessible by any authenticated user.
 */
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const routes = await routeService.getAllRoutes();
    res.json({ success: true, data: routes });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/routes/:id
 * Get a specific route with its stops array.
 */
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const route = await routeService.getRouteById(req.params.id);
    res.json({ success: true, data: route });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/routes
 * Admin: create a new route.
 */
router.post(
  '/',
  authMiddleware,
  rbac('admin'),
  validate(createRouteSchema),
  async (req, res, next) => {
    try {
      const route = await routeService.createRoute(req.body);
      res.status(201).json({ success: true, data: route });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * PUT /api/routes/:id
 * Admin: update a route.
 */
router.put(
  '/:id',
  authMiddleware,
  rbac('admin'),
  validate(updateRouteSchema),
  async (req, res, next) => {
    try {
      const route = await routeService.updateRoute(req.params.id, req.body);
      res.json({ success: true, data: route });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * DELETE /api/routes/:id
 * Admin: soft-delete (deactivate) a route.
 */
router.delete('/:id', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const result = await routeService.deactivateRoute(req.params.id);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
