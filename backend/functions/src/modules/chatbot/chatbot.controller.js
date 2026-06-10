const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const chatbotService = require('./chatbot.service');
const Joi = require('joi');

/**
 * RideSync — Chatbot Controller
 * Powered by Google Gemini AI via the @google/generative-ai SDK.
 */

const messageSchema = Joi.object({
  message: Joi.string().min(1).max(256).required(),
});

/**
 * POST /api/chatbot/message
 * Send a message to the Gemini AI Chatbot and receive a reply.
 * Requires Authentication.
 */
router.post('/message', authMiddleware, async (req, res, next) => {
  try {
    const { error, value } = messageSchema.validate(req.body);
    if (error) {
      const validationError = new Error(error.details[0].message);
      validationError.statusCode = 400;
      throw validationError;
    }

    // Use the authenticated user's Firebase UID as the session ID
    // so Gemini context fetcher can load personalised booking data.
    const sessionId = req.user.uid;
    const userMessage = value.message;

    // Send to Gemini AI service
    const response = await chatbotService.detectIntent(sessionId, userMessage);

    res.json({
      success: true,
      data: {
        reply: response.fulfillmentText || "I'm not sure how to respond to that.",
        intent: response.intent,
        parameters: response.parameters
      }
    });

  } catch (err) {
    console.error('[Chatbot Controller Error]', err.stack || err.message || err);

    if (err.message && (err.message.includes('unavailable') || err.message.includes('usage limits'))) {
      err.statusCode = 503; // Service Unavailable
    }
    next(err);
  }
});

module.exports = router;
