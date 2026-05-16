/**
 * RideSync — Shared Constants
 * Used by: functions/, web/, shared logic
 */

const ROLES = Object.freeze({
  PASSENGER: 'passenger',
  OPERATOR: 'operator',
  OPERATOR_PENDING: 'operator_pending',
  ADMIN: 'admin',
});

const BUS_CLASSES = Object.freeze({
  AC: 'AC',
  NON_AC: 'NonAC',
});

const SCHEDULE_STATUSES = Object.freeze({
  SCHEDULED: 'scheduled',
  ACTIVE: 'active',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
});

const BOOKING_STATUSES = Object.freeze({
  CONFIRMED: 'confirmed',
  CANCELLED: 'cancelled',
  COMPLETED: 'completed',
});

const NOTIFICATION_TYPES = Object.freeze({
  BOOKING: 'booking',
  DELAY: 'delay',
  ALERT: 'alert',
  PROMO: 'promo',
});

/**
 * Class multipliers for fare calculation.
 */
const CLASS_MULTIPLIERS = Object.freeze({
  [BUS_CLASSES.AC]: 1.5,
  [BUS_CLASSES.NON_AC]: 1.0,
});

module.exports = {
  ROLES,
  BUS_CLASSES,
  SCHEDULE_STATUSES,
  BOOKING_STATUSES,
  NOTIFICATION_TYPES,
  CLASS_MULTIPLIERS,
};
