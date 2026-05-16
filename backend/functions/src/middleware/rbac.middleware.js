/**
 * RideSync — RBAC Middleware
 *
 * Factory function that returns middleware to restrict access to specific roles.
 * Must be used AFTER authMiddleware (req.user must exist).
 *
 * Usage:
 *   router.post('/routes', authMiddleware, rbac('admin'), controller.create);
 *   router.put('/schedules/:id', authMiddleware, rbac('operator', 'admin'), controller.update);
 */
function rbac(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required before role check.',
      });
    }

    const userRole = req.user.role;

    if (!userRole || !allowedRoles.includes(userRole)) {
      return res.status(403).json({
        success: false,
        error: `Forbidden. Required role(s): ${allowedRoles.join(', ')}. Your role: ${userRole || 'none'}.`,
      });
    }

    next();
  };
}

module.exports = rbac;
