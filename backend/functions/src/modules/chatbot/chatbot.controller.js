const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middleware/auth.middleware');
const chatbotService = require('./chatbot.service');
const Joi = require('joi');

/**
 * RideSync — Chatbot Controller
 */

const messageSchema = Joi.object({
  message: Joi.string().min(1).max(256).required(),
});

/**
 * POST /api/chatbot/message
 * Send a message to the AI Chatbot and receive a reply.
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

    // We use the authenticated user's UID as the Dialogflow Session ID
    // This allows Dialogflow to remember context for this specific user.
    const sessionId = req.user.uid;
    const userMessage = value.message;

    // Send to Dialogflow service
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
    if (err.message.includes('credentials') || err.message.includes('unavailable')) {
      err.statusCode = 503; // Service Unavailable
    }
    next(err);
  }
});

module.exports = router;
