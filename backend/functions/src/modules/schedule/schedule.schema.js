/**
 * RideSync — Schedule Joi Schemas
 */
const Joi = require('joi');
const { SCHEDULE_STATUSES } = require('../../shared/constants');

const createScheduleSchema = Joi.object({
  routeId: Joi.string().trim().required(),
  busId: Joi.string().trim().required(),
  operatorId: Joi.string().trim().required(),
  departureTime: Joi.date().iso().required(),
});

const updateScheduleSchema = Joi.object({
  status: Joi.string().valid(
    SCHEDULE_STATUSES.SCHEDULED,
    SCHEDULE_STATUSES.ACTIVE,
    SCHEDULE_STATUSES.COMPLETED,
    SCHEDULE_STATUSES.CANCELLED
  ),
  delayMinutes: Joi.number().integer().min(0),
  currentStop: Joi.string().trim(),
}).min(1);

module.exports = {
  createScheduleSchema,
  updateScheduleSchema,
};
