/**
 * RideSync — Route Joi Schemas
 */
const Joi = require('joi');

const stopSchema = Joi.object({
  name: Joi.string().trim().required(),
  distFromStartKm: Joi.number().min(0).required(),
});

const createRouteSchema = Joi.object({
  routeNumber: Joi.string().trim().required(),
  startPoint: Joi.string().trim().required(),
  endPoint: Joi.string().trim().required(),
  totalDistanceKm: Joi.number().min(0).required(),
  stops: Joi.array().items(stopSchema).min(0).required(),
});

const updateRouteSchema = Joi.object({
  routeNumber: Joi.string().trim(),
  startPoint: Joi.string().trim(),
  endPoint: Joi.string().trim(),
  totalDistanceKm: Joi.number().min(0),
  stops: Joi.array().items(stopSchema),
}).min(1);

module.exports = {
  createRouteSchema,
  updateRouteSchema,
};
