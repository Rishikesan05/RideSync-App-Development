/**
 * RideSync — Auth Controller
 *
 * Express route handlers for authentication endpoints.
 */
const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const authService = require('./auth.service');

/**
 * POST /api/auth/register
 * Register user profile + set role claim.
 * The user must already be signed up via Firebase Auth on the client.
 * Body: { name, email, phone?, role }
 */
router.post('/register', authMiddleware, async (req, res, next) => {
  try {
    const { name, email, phone, role } = req.body;
    const uid = req.user.uid;

    const result = await authService.registerUser({
      uid,
      name,
      email,
      phone,
      role,
    });

    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/auth/set-role
 * Admin-only: assign role to any user.
 * Body: { targetUid, role, busId? }
 */
router.post('/set-role', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { targetUid, role, busId } = req.body;

    const result = await authService.setUserRole({
      targetUid,
      role,
      busId,
    });

    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
