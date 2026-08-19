/**
 * RideSync — Route Service
 *
 * Business logic layer for route management.
 */
const routeRepo = require('./route.repo');

async function getAllRoutes() {
  return routeRepo.getAll();
}

async function getRouteById(routeId) {
  const route = await routeRepo.getById(routeId);
  if (!route) {
    const err = new Error('Route not found.');
    err.statusCode = 404;
    throw err;
  }
  return route;
}

async function createRoute(data) {
  // Ensure stops are sorted by distance if present
  if (data.stops && data.stops.length > 0) {
    data.stops.sort((a, b) => a.distFromStartKm - b.distFromStartKm);
  }

  return routeRepo.create(data);
}

async function updateRoute(routeId, data) {
  // If stops are being updated, sort them
  if (data.stops) {
    data.stops.sort((a, b) => a.distFromStartKm - b.distFromStartKm);
  }

  const updated = await routeRepo.update(routeId, data);
  if (!updated) {
    const err = new Error('Route not found.');
    err.statusCode = 404;
    throw err;
  }
  return updated;
}

async function deactivateRoute(routeId) {
  const result = await routeRepo.deactivate(routeId);
  if (!result) {
    const err = new Error('Route not found.');
    err.statusCode = 404;
    throw err;
  }
  return result;
}

module.exports = {
  getAllRoutes,
  getRouteById,
  createRoute,
  updateRoute,
  deactivateRoute,
};
