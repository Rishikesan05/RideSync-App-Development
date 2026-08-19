const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const rbac = require('../../middleware/rbac.middleware');
const feedbackService = require('./feedback.service');
const Joi = require('joi');

/**
 * RideSync — Feedback Controller
 */

// Validation schema for submitting feedback
const feedbackSchema = Joi.object({
  scheduleId: Joi.string().required(),
  rating: Joi.number().integer().min(1).max(5).required(),
  comment: Joi.string().allow('').optional()
});

/**
 * POST /api/feedback
 * Submit a rating for a completed trip.
 * Role: passenger
 */
router.post('/', authMiddleware, rbac('passenger'), async (req, res, next) => {
  try {
    const { error, value } = feedbackSchema.validate(req.body);
    if (error) {
      const validationError = new Error(error.details[0].message);
      validationError.statusCode = 400;
      throw validationError;
    }

    const userId = req.user.uid;
    const result = await feedbackService.submitFeedback(userId, value);
    
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    if (err.message.includes('cannot rate') || err.message.includes('already submitted')) {
      err.statusCode = 403; // Forbidden
    }
    next(err);
  }
});

/**
 * GET /api/feedback/bus/:busId
 * Get aggregated ratings for a specific bus.
 * Role: admin, operator
 */
router.get('/bus/:busId', authMiddleware, async (req, res, next) => {
  try {
    // Only admins or the operator assigned to this bus should see this (in a strict scenario)
    // For MVP, we'll just let any authenticated user (or at least admin/operator) see it.
    
    const result = await feedbackService.getBusFeedback(req.params.busId);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
