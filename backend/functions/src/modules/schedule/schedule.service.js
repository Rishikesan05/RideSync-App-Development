/**
 * RideSync — Schedule Service
 *
 * Business logic for schedule management including seat map generation.
 */
const scheduleRepo = require('./schedule.repo');
const busRepo = require('../bus/bus.repo');
const routeRepo = require('../route/route.repo');
const { SCHEDULE_STATUSES } = require('../../shared/constants');

/**
 * Generate a seat map for a bus based on its capacity.
 * Seat naming: A1, A2, B1, B2, C1, C2... (2 seats per row per side).
 * All seats initialize as null (available).
 */
function generateSeatMap(capacity) {
  const seatMap = {};
  const seatsPerRow = 4; // 2 left + 2 right
  const totalRows = Math.ceil(capacity / seatsPerRow);

  for (let row = 0; row < totalRows; row++) {
    const rowLetter = String.fromCharCode(65 + row); // A, B, C, ...
    for (let seat = 1; seat <= seatsPerRow; seat++) {
      const seatIndex = row * seatsPerRow + seat;
      if (seatIndex <= capacity) {
        seatMap[`${rowLetter}${seat}`] = null; // null = available
      }
    }
  }

  return seatMap;
}

async function getAllSchedules(filters) {
  return scheduleRepo.getAll(filters);
}

async function getScheduleById(scheduleId) {
  const schedule = await scheduleRepo.getById(scheduleId);
  if (!schedule) {
    const err = new Error('Schedule not found.');
    err.statusCode = 404;
    throw err;
  }
  return schedule;
}

async function getSeats(scheduleId) {
  const schedule = await getScheduleById(scheduleId);
  return {
    scheduleId,
    seatMap: schedule.seatMap || {},
  };
}

async function createSchedule(data) {
  // Verify bus exists and is active
  const bus = await busRepo.getById(data.busId);
  if (!bus || !bus.isActive) {
    const err = new Error('Bus not found or inactive.');
    err.statusCode = 400;
    throw err;
  }

  // Verify route exists and is active
  const route = await routeRepo.getById(data.routeId);
  if (!route || !route.isActive) {
    const err = new Error('Route not found or inactive.');
    err.statusCode = 400;
    throw err;
  }

  const departureDate = new Date(data.departureTime);
  if (isNaN(departureDate.getTime())) {
    const err = new Error('Invalid departure time format.');
    err.statusCode = 400;
    throw err;
  }

  const scheduleData = {
    ...data,
    departureTime: departureDate,
    capacity: data.capacity || bus.capacity || 54,
    plateNumber: data.plateNumber || bus.plateNumber || 'N/A',
    routeName: data.routeName || route.name || route.routeName || 'Intercity Express',
    status: SCHEDULE_STATUSES.SCHEDULED,
    delayMinutes: 0,
    currentStop: route.stops[0].name, // Start at first stop
    eta: null,
  };

  return scheduleRepo.create(scheduleData);
}

async function updateSchedule(scheduleId, data) {
  const updated = await scheduleRepo.update(scheduleId, data);
  if (!updated) {
    const err = new Error('Schedule not found.');
    err.statusCode = 404;
    throw err;
  }
  return updated;
}

async function cancelSchedule(scheduleId) {
  const result = await scheduleRepo.remove(scheduleId);
  if (!result) {
    const err = new Error('Schedule not found.');
    err.statusCode = 404;
    throw err;
  }
  return result;
}

module.exports = {
  getAllSchedules,
  getScheduleById,
  getSeats,
  createSchedule,
  updateSchedule,
  cancelSchedule,
};
