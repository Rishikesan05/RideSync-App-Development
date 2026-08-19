/**
 * RideSync — Operator Service
 *
 * Business logic for operator-specific operations:
 *   - Dashboard summary
 *   - Earnings aggregation from completed schedules
 *   - Cash handover logging and retrieval
 *   - Support report submission and retrieval
 *   - Operator profile read/update
 */
const { db } = require('../../config/firebase.config');

const schedulesCol = db.collection('schedules');
const cashHandoversCol = db.collection('cash_handovers');
const reportsCol = db.collection('operator_reports');
const operatorsCol = db.collection('operators');
const bookingsCol = db.collection('bookings');

// ─── Dashboard ───────────────────────────────────────────────────────────────

/**
 * Returns a summary for the operator's home dashboard:
 *   - Today's schedules count
 *   - Active / in-transit trip (if any)
 *   - Total revenue (lifetime from completed schedules)
 *   - Pending cash handover amount
 *
 * @param {string} operatorId  — Firebase UID of the authenticated operator
 */
async function getDashboard(operatorId) {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(startOfToday.getTime() + 24 * 60 * 60 * 1000);

  // Fetch all schedules for this operator (no complex composite index needed)
  const snap = await schedulesCol
    .where('operatorId', '==', operatorId)
    .get();

  let todayCount = 0;
  let activeTrip = null;
  let totalRevenue = 0;

  snap.forEach((doc) => {
    const data = doc.data();

    // Count today's schedules
    if (data.departureTime) {
      const depTime =
        data.departureTime.toDate ? data.departureTime.toDate() : new Date(data.departureTime);
      if (depTime >= startOfToday && depTime < endOfToday) {
        todayCount++;
      }
    }

    // Accumulate completed revenue
    if (data.status === 'completed' && typeof data.revenue === 'number') {
      totalRevenue += data.revenue;
    }

    // Find active trip
    if (data.status === 'in-transit' || data.status === 'active') {
      activeTrip = { id: doc.id, ...data };
    }
  });

  // Pending cash handover amount
  const handoverSnap = await cashHandoversCol
    .where('operatorId', '==', operatorId)
    .where('status', '==', 'pending_approval')
    .get();

  let pendingHandover = 0;
  handoverSnap.forEach((doc) => {
    pendingHandover += doc.data().amount || 0;
  });

  return {
    todayTripsCount: todayCount,
    activeTrip,
    totalRevenue,
    pendingHandover,
  };
}

// ─── Earnings ────────────────────────────────────────────────────────────────

/**
 * Returns earnings aggregated from completed schedules.
 *
 * @param {string} operatorId
 * @param {string} period — 'today' | 'week' | 'month' | 'all' (default: 'week')
 */
async function getEarnings(operatorId, period = 'week') {
  const now = new Date();
  let startDate;

  switch (period) {
    case 'today':
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      break;
    case 'week':
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      break;
    case 'month':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      break;
    default:
      startDate = null; // all time
  }

  const snap = await schedulesCol
    .where('operatorId', '==', operatorId)
    .where('status', '==', 'completed')
    .get();

  const completedSchedules = [];
  let totalEarnings = 0;

  snap.forEach((doc) => {
    const data = doc.data();
    const revenue = typeof data.revenue === 'number' ? data.revenue : 0;

    let completedAt = null;
    if (data.actualEndTime) {
      completedAt = data.actualEndTime.toDate
        ? data.actualEndTime.toDate()
        : new Date(data.actualEndTime);
    } else if (data.updatedAt) {
      completedAt = data.updatedAt.toDate
        ? data.updatedAt.toDate()
        : new Date(data.updatedAt);
    }

    // Filter by period
    if (startDate && completedAt && completedAt < startDate) return;

    totalEarnings += revenue;
    completedSchedules.push({
      id: doc.id,
      routeName: data.routeName || 'Unknown Route',
      revenue,
      completedAt: completedAt ? completedAt.toISOString() : null,
      plateNumber: data.plateNumber || 'N/A',
      bookedSeats: data.bookedSeatsCount || 0,
    });
  });

  // Sort by completedAt descending
  completedSchedules.sort((a, b) => {
    if (!a.completedAt) return 1;
    if (!b.completedAt) return -1;
    return new Date(b.completedAt) - new Date(a.completedAt);
  });

  // Build daily breakdown for chart (last 7 days)
  const dailyBreakdown = _buildDailyBreakdown(completedSchedules, 7);

  // Cash handover breakdown
  const handoverSnap = await cashHandoversCol
    .where('operatorId', '==', operatorId)
    .get();

  let pendingHandover = 0;
  let awaitingApproval = 0;
  let deposited = 0;
  const handovers = [];

  handoverSnap.forEach((doc) => {
    const h = doc.data();
    const amount = h.amount || 0;
    const status = h.status || '';

    if (status === 'pending_approval') awaitingApproval += amount;
    else if (status === 'approved') deposited += amount;
    else if (status === 'pending') pendingHandover += amount;

    handovers.push({ id: doc.id, ...h });
  });

  return {
    totalEarnings,
    period,
    pendingHandover,
    awaitingApproval,
    deposited,
    dailyBreakdown,
    recentTrips: completedSchedules.slice(0, 20),
    handovers,
  };
}

/**
 * Builds an array of { day, amount } for the last N days.
 */
function _buildDailyBreakdown(trips, days) {
  const breakdown = [];
  const now = new Date();

  for (let i = days - 1; i >= 0; i--) {
    const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);

    const dayLabel = dayStart.toLocaleDateString('en-US', { weekday: 'short' });
    const amount = trips
      .filter((t) => {
        if (!t.completedAt) return false;
        const d = new Date(t.completedAt);
        return d >= dayStart && d < dayEnd;
      })
      .reduce((sum, t) => sum + t.revenue, 0);

    breakdown.push({ day: dayLabel, amount });
  }

  return breakdown;
}

// ─── Cash Handovers ──────────────────────────────────────────────────────────

/**
 * Log a new cash handover entry for this operator.
 *
 * @param {string} operatorId
 * @param {number} amount
 * @param {string} notes  — optional notes
 */
async function logCashHandover(operatorId, amount, notes = '') {
  if (!amount || amount <= 0) {
    const err = new Error('Handover amount must be greater than zero.');
    err.statusCode = 400;
    throw err;
  }

  const docRef = await cashHandoversCol.add({
    operatorId,
    amount,
    notes,
    status: 'pending_approval',
    createdAt: new Date(),
  });

  return { id: docRef.id, operatorId, amount, status: 'pending_approval' };
}

/**
 * Get all cash handovers for an operator.
 */
async function getCashHandovers(operatorId) {
  const snap = await cashHandoversCol
    .where('operatorId', '==', operatorId)
    .orderBy('createdAt', 'desc')
    .get();

  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

// ─── Support Reports ─────────────────────────────────────────────────────────

/**
 * Submit a support / contact-admin report.
 *
 * @param {string} operatorId
 * @param {{ type: string, description: string, title?: string }} reportData
 */
async function submitReport(operatorId, reportData) {
  const { type, description, title } = reportData;

  if (!type || !description) {
    const err = new Error('Report type and description are required.');
    err.statusCode = 400;
    throw err;
  }

  const docRef = await reportsCol.add({
    operatorId,
    type,
    title: title || type,
    description,
    status: 'pending',
    createdAt: new Date(),
  });

  return {
    id: docRef.id,
    operatorId,
    type,
    title: title || type,
    status: 'pending',
  };
}

/**
 * Get all reports submitted by this operator.
 */
async function getReports(operatorId) {
  const snap = await reportsCol
    .where('operatorId', '==', operatorId)
    .orderBy('createdAt', 'desc')
    .get();

  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

// ─── Operator Profile ────────────────────────────────────────────────────────

/**
 * Get the operator's Firestore profile from the `operators` collection.
 *
 * @param {string} uid — Firebase Auth UID
 */
async function getProfile(uid) {
  const doc = await operatorsCol.doc(uid).get();
  if (!doc.exists) {
    const err = new Error('Operator profile not found.');
    err.statusCode = 404;
    throw err;
  }
  return { uid, ...doc.data() };
}

/**
 * Update the operator's profile.
 * Allowed fields: licenseNumber, vehicleAssigned, company, phone, displayName
 *
 * @param {string} uid
 * @param {Object} updates
 */
async function updateProfile(uid, updates) {
  const allowedFields = [
    'displayName',
    'phone',
    'licenseNumber',
    'vehicleAssigned',
    'company',
    'yearsExperience',
    'emergencyContact',
  ];

  const sanitized = {};
  for (const field of allowedFields) {
    if (updates[field] !== undefined) {
      sanitized[field] = updates[field];
    }
  }

  if (Object.keys(sanitized).length === 0) {
    const err = new Error('No valid fields provided for update.');
    err.statusCode = 400;
    throw err;
  }

  sanitized.updatedAt = new Date();

  await operatorsCol.doc(uid).set(sanitized, { merge: true });

  const updated = await operatorsCol.doc(uid).get();
  return { uid, ...updated.data() };
}

// ─── Revenue Write on Trip Complete ──────────────────────────────────────────

/**
 * Computes and writes the `revenue` field to a schedule document when
 * the operator ends a trip. Revenue = sum of all confirmed booking fares.
 *
 * Called by schedule.service.js when status is set to 'completed'.
 *
 * @param {string} scheduleId
 */
async function finalizeScheduleRevenue(scheduleId) {
  try {
    const bookingsSnap = await bookingsCol
      .where('scheduleId', '==', scheduleId)
      .where('status', '==', 'confirmed')
      .get();

    let revenue = 0;
    let bookedSeatsCount = 0;

    bookingsSnap.forEach((doc) => {
      const data = doc.data();
      revenue += typeof data.fare === 'number' ? data.fare : 0;
      bookedSeatsCount++;
    });

    await schedulesCol.doc(scheduleId).update({
      revenue,
      bookedSeatsCount,
      revenueComputedAt: new Date(),
    });

    return { scheduleId, revenue, bookedSeatsCount };
  } catch (err) {
    console.error('[operatorService] finalizeScheduleRevenue error:', err.message);
    // Non-fatal — do not block trip completion
    return null;
  }
}

module.exports = {
  getDashboard,
  getEarnings,
  logCashHandover,
  getCashHandovers,
  submitReport,
  getReports,
  getProfile,
  updateProfile,
  finalizeScheduleRevenue,
};
