/**
 * RideSync — Bus Service
 *
 * Business logic for fleet management.
 */
const busRepo = require('./bus.repo');

async function getAllBuses() {
  return busRepo.getAll();
}

async function getBusById(busId) {
  const bus = await busRepo.getById(busId);
  if (!bus) {
    const err = new Error('Bus not found.');
    err.statusCode = 404;
    throw err;
  }
  return bus;
}

async function createBus(data) {
  return busRepo.create(data);
}

async function updateBus(busId, data) {
  const updated = await busRepo.update(busId, data);
  if (!updated) {
    const err = new Error('Bus not found.');
    err.statusCode = 404;
    throw err;
  }
  return updated;
}

async function deactivateBus(busId) {
  const result = await busRepo.deactivate(busId);
  if (!result) {
    const err = new Error('Bus not found.');
    err.statusCode = 404;
    throw err;
  }
  return result;
}

module.exports = {
  getAllBuses,
  getBusById,
  createBus,
  updateBus,
  deactivateBus,
};
