/**
 * RideSync — Fare Service
 *
 * Segment-based fare calculation engine with in-memory caching.
 * Formula: fare = baseFare + (segmentKm × ratePerKm × classMultiplier)
 */
const NodeCache = require('node-cache');
const fareRepo = require('./fare.repo');
const routeRepo = require('../route/route.repo');
const busRepo = require('../bus/bus.repo');
const scheduleRepo = require('../schedule/schedule.repo');
const { CLASS_MULTIPLIERS } = require('../../shared/constants');

// Cache routes for 1 hour to reduce Firestore reads
const cache = new NodeCache({ stdTTL: 3600 });

/**
 * Calculate segment-based fare between two stops.
 *
 * @param {string} scheduleId
 * @param {string} fromStop - Name of the boarding stop
 * @param {string} toStop   - Name of the alighting stop
 * @param {string} [busClass] - "AC" or "NonAC" (auto-detected from bus if omitted)
 * @returns {Object} Fare breakdown
 */
async function calculateFare(scheduleId, fromStop, toStop, busClass) {
  // 1. Fetch schedule to get routeId and busId
  const schedule = await scheduleRepo.getById(scheduleId);
  if (!schedule) {
    const err = new Error('Schedule not found.');
    err.statusCode = 404;
    throw err;
  }
  const { routeId, busId } = schedule;

  // 2. Fetch bus to get class (override if not passed)
  const bus = await busRepo.getById(busId);
  if (!bus) {
    const err = new Error('Bus not found for this schedule.');
    err.statusCode = 404;
    throw err;
  }
  const resolvedClass = busClass || bus.class;

  // 3. Fetch route from cache or Firestore
  const cacheKey = `route_${routeId}`;
  let route = cache.get(cacheKey);
  if (!route) {
    route = await routeRepo.getById(routeId);
    if (!route) {
      const err = new Error('Route not found for this schedule.');
      err.statusCode = 404;
      throw err;
    }
    cache.set(cacheKey, route);
  }

  // 4. Find stop indices
  const fromIdx = route.stops.findIndex((s) => s.name === fromStop);
  const toIdx = route.stops.findIndex((s) => s.name === toStop);

  if (fromIdx === -1 || toIdx === -1) {
    const err = new Error('Invalid stop names for this route.');
    err.statusCode = 400;
    throw err;
  }
  if (fromIdx >= toIdx) {
    const err = new Error('fromStop must come before toStop on this route.');
    err.statusCode = 400;
    throw err;
  }

  // 5. Compute segment distance
  const segmentKm =
    route.stops[toIdx].distFromStartKm - route.stops[fromIdx].distFromStartKm;

  // 6. Fetch fare rule
  const fareRule = await fareRepo.getByRouteAndClass(routeId, resolvedClass);
  if (!fareRule) {
    const err = new Error(
      `No fare rule found for route "${routeId}" and class "${resolvedClass}".`
    );
    err.statusCode = 404;
    throw err;
  }

  // 7. Apply class multiplier
  const classMultiplier = CLASS_MULTIPLIERS[resolvedClass] || 1.0;

  // 8. Compute total
  const rawTotal =
    fareRule.baseFare + segmentKm * fareRule.ratePerKm * classMultiplier;
  const total = Math.ceil(rawTotal);

  return {
    total,
    baseFare: fareRule.baseFare,
    segmentKm: parseFloat(segmentKm.toFixed(2)),
    ratePerKm: fareRule.ratePerKm,
    classMultiplier,
    busClass: resolvedClass,
  };
}

/**
 * Get all fare rules for a route.
 */
async function getFaresByRoute(routeId) {
  return fareRepo.getByRouteId(routeId);
}

/**
 * Admin: create a new fare rule.
 */
async function createFare(data) {
  // Check if a rule already exists for this route + class combo
  const existing = await fareRepo.getByRouteAndClass(data.routeId, data.class);
  if (existing) {
    const err = new Error(
      `Fare rule already exists for route "${data.routeId}" class "${data.class}". Use PUT to update.`
    );
    err.statusCode = 409;
    throw err;
  }
  return fareRepo.create(data);
}

/**
 * Admin: update an existing fare rule.
 */
async function updateFare(fareId, data) {
  const updated = await fareRepo.update(fareId, data);
  if (!updated) {
    const err = new Error('Fare rule not found.');
    err.statusCode = 404;
    throw err;
  }
  return updated;
}

module.exports = {
  calculateFare,
  getFaresByRoute,
  createFare,
  updateFare,
};
