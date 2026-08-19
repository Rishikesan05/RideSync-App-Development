/**
 * RideSync — Booking Joi Schemas
 */
const Joi = require('joi');

const createBookingSchema = Joi.object({
  scheduleId: Joi.string().trim().required(),
  seatNo: Joi.string().trim().uppercase().required(),
  fromStop: Joi.string().trim().required(),
  toStop: Joi.string().trim().required(),
});

module.exports = {
  createBookingSchema,
};
