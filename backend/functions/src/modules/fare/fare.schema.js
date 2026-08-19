/**
 * RideSync — Fare Joi Schemas
 */
const Joi = require('joi');
const { BUS_CLASSES } = require('../../shared/constants');

const createFareSchema = Joi.object({
  routeId: Joi.string().trim().required(),
  class: Joi.string().valid(BUS_CLASSES.AC, BUS_CLASSES.NON_AC).required(),
  baseFare: Joi.number().min(0).required(),
  ratePerKm: Joi.number().positive().required(),
});

const updateFareSchema = Joi.object({
  baseFare: Joi.number().min(0),
  ratePerKm: Joi.number().positive(),
}).min(1);

module.exports = {
  createFareSchema,
  updateFareSchema,
};
