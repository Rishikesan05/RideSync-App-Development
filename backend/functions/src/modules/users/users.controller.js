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

/**
 * PUT /api/users/:uid/approve-admin
 * Admin only: Approve a pending admin (role: admin_pending → admin).
 *
 * Flow:
 *   1. An existing admin calls this endpoint with the pending admin's UID.
 *   2. Service checks the target user's role is 'admin_pending'.
 *   3. Updates Firestore role to 'admin' and sets the Firebase Auth JWT claim.
 *   4. Pending user's JWT refreshes → they now pass isAdmin() in Firestore rules.
 */
router.put('/:uid/approve-admin', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { uid } = req.params;
    const approverUid = req.user.uid;   // the admin who clicked Approve
    const result = await usersService.approveAdmin(uid, approverUid);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/users/:uid/reject-admin
 * Admin only: Reject a pending admin (role: admin_pending → passenger).
 */
router.put('/:uid/reject-admin', authMiddleware, rbac('admin'), async (req, res, next) => {
  try {
    const { uid } = req.params;
    const approverUid = req.user.uid;
    const result = await usersService.rejectAdmin(uid, approverUid);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
