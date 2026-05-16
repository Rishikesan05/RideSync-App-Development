/**
 * RideSync — Validation Middleware
 *
 * Factory function that validates req.body against a Joi schema.
 *
 * Usage:
 *   const { createRouteSchema } = require('./route.schema');
 *   router.post('/routes', validate(createRouteSchema), controller.create);
 */
function validate(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,    // Return all errors, not just the first
      stripUnknown: true,   // Remove fields not in schema
    });

    if (error) {
      const details = error.details.map((d) => ({
        field: d.path.join('.'),
        message: d.message,
      }));

      return res.status(400).json({
        success: false,
        error: 'Validation failed.',
        details,
      });
    }

    // Replace body with the validated + sanitized value
    req.body = value;
    next();
  };
}

module.exports = validate;
