/**
 * RideSync — Operator Controller
 *
 * Express router for /api/operator endpoints.
 * All routes require Firebase Auth token + operator (or admin) role.
 */
const express = require('express');
const router = express.Router();
const Joi = require('joi');
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const operatorService = require('./operator.service');

// ─── Validation Schemas ───────────────────────────────────────────────────────

const cashHandoverSchema = Joi.object({
  amount: Joi.number().positive().required(),
  notes: Joi.string().allow('').optional(),
});

const reportSchema = Joi.object({
  type: Joi.string().required(),
  title: Joi.string().allow('').optional(),
  description: Joi.string().min(5).required(),
});

const profileUpdateSchema = Joi.object({
  displayName: Joi.string().allow('').optional(),
  phone: Joi.string().allow('').optional(),
  licenseNumber: Joi.string().allow('').optional(),
  vehicleAssigned: Joi.string().allow('').optional(),
  company: Joi.string().allow('').optional(),
  yearsExperience: Joi.number().min(0).optional(),
  emergencyContact: Joi.string().allow('').optional(),
}).min(1);

// ─── Dashboard ────────────────────────────────────────────────────────────────

/**
 * GET /api/operator/dashboard
 * Returns today's schedule count, active trip, total revenue, pending handover.
 */
router.get('/dashboard', authMiddleware, rbac('operator', 'admin'), async (req, res, next) => {
  try {
    const operatorId = req.user.uid;
    const data = await operatorService.getDashboard(operatorId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
});

// ─── Earnings ─────────────────────────────────────────────────────────────────

/**
 * GET /api/operator/earnings?period=today|week|month|all
 * Returns aggregated earnings, daily breakdown chart data, recent trips, and handover summary.
 */
router.get('/earnings', authMiddleware, rbac('operator', 'admin'), async (req, res, next) => {
  try {
    const operatorId = req.user.uid;
    const period = req.query.period || 'week';

    if (!['today', 'week', 'month', 'all'].includes(period)) {
      return res.status(400).json({ success: false, error: 'Invalid period. Use: today, week, month, all.' });
    }

    const data = await operatorService.getEarnings(operatorId, period);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
});

// ─── Cash Handovers ───────────────────────────────────────────────────────────

/**
 * GET /api/operator/cash-handovers
 * List all cash handovers for the authenticated operator.
 */
router.get('/cash-handovers', authMiddleware, rbac('operator', 'admin'), async (req, res, next) => {
  try {
    const operatorId = req.user.uid;
    const handovers = await operatorService.getCashHandovers(operatorId);
    res.json({ success: true, data: handovers });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/operator/cash-handover
 * Log a new cash handover.
 * Body: { amount: number, notes?: string }
 */
router.post('/cash-handover', authMiddleware, rbac('operator'), async (req, res, next) => {
  try {
    const { error, value } = cashHandoverSchema.validate(req.body);
    if (error) {
      const validationError = new Error(error.details[0].message);
      validationError.statusCode = 400;
      throw validationError;
    }

    const operatorId = req.user.uid;
    const result = await operatorService.logCashHandover(operatorId, value.amount, value.notes);
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

// ─── Reports / Contact Admin ──────────────────────────────────────────────────

/**
 * GET /api/operator/reports
 * List all support reports submitted by the authenticated operator.
 */
router.get('/reports', authMiddleware, rbac('operator', 'admin'), async (req, res, next) => {
  try {
    const operatorId = req.user.uid;
    const reports = await operatorService.getReports(operatorId);
    res.json({ success: true, data: reports });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/operator/report
 * Submit a new support report.
 * Body: { type: string, description: string, title?: string }
 */
router.post('/report', authMiddleware, rbac('operator'), async (req, res, next) => {
  try {
    const { error, value } = reportSchema.validate(req.body);
    if (error) {
      const validationError = new Error(error.details[0].message);
      validationError.statusCode = 400;
      throw validationError;
    }

    const operatorId = req.user.uid;
    const result = await operatorService.submitReport(operatorId, value);
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

// ─── Profile ──────────────────────────────────────────────────────────────────

/**
 * GET /api/operator/profile
 * Get the authenticated operator's Firestore profile.
 */
router.get('/profile', authMiddleware, rbac('operator', 'admin'), async (req, res, next) => {
  try {
    const uid = req.user.uid;
    const profile = await operatorService.getProfile(uid);
    res.json({ success: true, data: profile });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/operator/profile
 * Update the operator's profile (licenseNumber, vehicleAssigned, company, etc.)
 * Body: { displayName?, phone?, licenseNumber?, vehicleAssigned?, company?, yearsExperience?, emergencyContact? }
 */
router.put('/profile', authMiddleware, rbac('operator', 'admin'), async (req, res, next) => {
  try {
    const { error, value } = profileUpdateSchema.validate(req.body);
    if (error) {
      const validationError = new Error(error.details[0].message);
      validationError.statusCode = 400;
      throw validationError;
    }

    const uid = req.user.uid;
    const updated = await operatorService.updateProfile(uid, value);
    res.json({ success: true, data: updated });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
