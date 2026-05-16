/**
 * RideSync — Bus Joi Schemas
 */
const Joi = require('joi');
const { BUS_CLASSES } = require('../../shared/constants');

const createBusSchema = Joi.object({
  plateNumber: Joi.string().trim().uppercase().required(),
  class: Joi.string().valid(BUS_CLASSES.AC, BUS_CLASSES.NON_AC).required(),
  capacity: Joi.number().integer().min(10).max(80).required(),
  operatorId: Joi.string().trim().allow(null, '').optional(),
});

const updateBusSchema = Joi.object({
  plateNumber: Joi.string().trim().uppercase(),
  class: Joi.string().valid(BUS_CLASSES.AC, BUS_CLASSES.NON_AC),
  capacity: Joi.number().integer().min(10).max(80),
  operatorId: Joi.string().trim().allow(null, ''),
  isActive: Joi.boolean(),
}).min(1);

module.exports = {
  createBusSchema,
  updateBusSchema,
};
