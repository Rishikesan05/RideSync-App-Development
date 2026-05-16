/**
 * RideSync — Express Application
 *
 * Central Express setup with all middleware and route mounting.
 */
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middleware/errorHandler.middleware');

// Module controllers
const authController = require('./modules/auth/auth.controller');
const routeController = require('./modules/route/route.controller');
const busController = require('./modules/bus/bus.controller');
const scheduleController = require('./modules/schedule/schedule.controller');
const fareController = require('./modules/fare/fare.controller');
const bookingController = require('./modules/booking/booking.controller');
const notificationController = require('./modules/notification/notification.controller');
const feedbackController = require('./modules/feedback/feedback.controller');
const chatbotController = require('./modules/chatbot/chatbot.controller');
const usersController = require('./modules/users/users.controller');

const app = express();

// ─── Global Middleware ───────────────────────────────────────────

// CORS — allow all origins for development, restrict in production
app.use(cors({ origin: true }));

// Security headers
app.use(helmet());

// Body parsing with size limit
app.use(express.json({ limit: '10kb' }));

// Rate limiting — all API routes
app.use(
  '/api/',
  rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, error: 'Too many requests, please try again later.' },
  })
);

// ─── Health Check ────────────────────────────────────────────────

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
    },
  });
});

// ─── Route Mounting ──────────────────────────────────────────────

app.use('/api/auth', authController);
app.use('/api/users', usersController);
app.use('/api/routes', routeController);
app.use('/api/buses', busController);
app.use('/api/schedules', scheduleController);
app.use('/api/fares', fareController);
app.use('/api/bookings', bookingController);
app.use('/api/notify', notificationController);
app.use('/api/feedback', feedbackController);
app.use('/api/chatbot', chatbotController);

// ─── 404 Handler ─────────────────────────────────────────────────

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: `Route not found: ${req.method} ${req.originalUrl}`,
  });
});

// ─── Centralized Error Handler (must be last) ────────────────────

app.use(errorHandler);

module.exports = app;
