/**
 * RideSync — Users Controller
 */
const express = require('express');
const router = express.Router();
const usersService = require('./users.service');
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');

/**
 * GET /api/users
 * Admin only: Get list of users, optionally filtered by role
 */
router.get('/', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { role } = req.query;
    const users = await usersService.getUsers(role);
    res.json({ success: true, data: users });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/users/:uid/approve
 * Admin only: Approve an operator registration
 */
router.put('/:uid/approve', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { uid } = req.params;
    const result = await usersService.approveOperator(uid);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/users/:uid/reject
 * Admin only: Reject an operator registration
 */
router.put('/:uid/reject', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { uid } = req.params;
    const result = await usersService.rejectOperator(uid);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
