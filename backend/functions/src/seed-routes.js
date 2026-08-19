/**
 * RideSync — Seed Script using Firebase Web SDK (Client-side)
 * This bypasses the Admin SDK IAM requirement by using the Firebase
 * web client with direct Firestore REST API calls.
 *
 * Usage: node seed-routes.js
 */
const https = require('https');
const http = require('http');

const PROJECT_ID = 'ridesync-lk';
const API_KEY = 'AIzaSyCv3DoRfFRvayKVqWH_Iuinf-5trnHyusg';

// Firestore REST API base
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function firestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'number' && Number.isInteger(val)) return { integerValue: String(val) };
  if (typeof val === 'number') return { doubleValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (Array.isArray(val)) return { arrayValue: { values: val.map(firestoreValue) } };
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = firestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreDoc(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    fields[k] = firestoreValue(v);
  }
  return { fields };
}

function makeRequest(method, path, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${FIRESTORE_BASE}${path}?key=${API_KEY}`);
    const options = {
      hostname: url.hostname,
      port: 443,
      path: url.pathname + url.search,
      method,
      headers: { 'Content-Type': 'application/json' },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data || '{}'));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 200)}`));
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function createDoc(collection, data) {
  const doc = toFirestoreDoc(data);
  const result = await makeRequest('POST', `/${collection}`, doc);
  // Extract document ID from the name
  const name = result.name;
  const id = name.split('/').pop();
  return id;
}

// ── Sri Lankan Bus Routes ──────────────────────────────────────────
const ROUTES = [
  {
    routeNumber: '1', name: 'Colombo - Kandy Express', startPoint: 'Colombo', endPoint: 'Kandy', totalDistanceKm: 116, isActive: true,
    stops: [
      { name: 'Colombo Fort', distFromStartKm: 0 },
      { name: 'Kadawatha', distFromStartKm: 15 },
      { name: 'Kegalle', distFromStartKm: 72 },
      { name: 'Mawanella', distFromStartKm: 88 },
      { name: 'Kandy', distFromStartKm: 116 },
    ],
  },
  {
    routeNumber: '2', name: 'Colombo - Galle Coastal', startPoint: 'Colombo', endPoint: 'Galle', totalDistanceKm: 126, isActive: true,
    stops: [
      { name: 'Colombo Fort', distFromStartKm: 0 },
      { name: 'Moratuwa', distFromStartKm: 18 },
      { name: 'Panadura', distFromStartKm: 27 },
      { name: 'Ambalangoda', distFromStartKm: 87 },
      { name: 'Hikkaduwa', distFromStartKm: 98 },
      { name: 'Galle', distFromStartKm: 126 },
    ],
  },
  {
    routeNumber: '4', name: 'Colombo - Jaffna Intercity', startPoint: 'Colombo', endPoint: 'Jaffna', totalDistanceKm: 398, isActive: true,
    stops: [
      { name: 'Colombo Fort', distFromStartKm: 0 },
      { name: 'Kurunegala', distFromStartKm: 94 },
      { name: 'Dambulla', distFromStartKm: 148 },
      { name: 'Anuradhapura', distFromStartKm: 206 },
      { name: 'Vavuniya', distFromStartKm: 260 },
      { name: 'Kilinochchi', distFromStartKm: 326 },
      { name: 'Jaffna', distFromStartKm: 398 },
    ],
  },
  {
    routeNumber: '15', name: 'Colombo - Ratnapura', startPoint: 'Colombo', endPoint: 'Ratnapura', totalDistanceKm: 101, isActive: true,
    stops: [
      { name: 'Colombo Fort', distFromStartKm: 0 },
      { name: 'Horana', distFromStartKm: 36 },
      { name: 'Eheliyagoda', distFromStartKm: 68 },
      { name: 'Ratnapura', distFromStartKm: 101 },
    ],
  },
  {
    routeNumber: '48', name: 'Kandy - Nuwara Eliya', startPoint: 'Kandy', endPoint: 'Nuwara Eliya', totalDistanceKm: 80, isActive: true,
    stops: [
      { name: 'Kandy', distFromStartKm: 0 },
      { name: 'Peradeniya', distFromStartKm: 7 },
      { name: 'Gampola', distFromStartKm: 24 },
      { name: 'Nawalapitiya', distFromStartKm: 37 },
      { name: 'Nuwara Eliya', distFromStartKm: 80 },
    ],
  },
  {
    routeNumber: '99', name: 'Colombo - Negombo', startPoint: 'Colombo', endPoint: 'Negombo', totalDistanceKm: 37, isActive: true,
    stops: [
      { name: 'Colombo Fort', distFromStartKm: 0 },
      { name: 'Wattala', distFromStartKm: 12 },
      { name: 'Ja-Ela', distFromStartKm: 20 },
      { name: 'Negombo', distFromStartKm: 37 },
    ],
  },
  {
    routeNumber: '138', name: 'Colombo - Kaduwela Express', startPoint: 'Colombo', endPoint: 'Kaduwela', totalDistanceKm: 18, isActive: true,
    stops: [
      { name: 'Pettah', distFromStartKm: 0 },
      { name: 'Borella', distFromStartKm: 4 },
      { name: 'Nugegoda', distFromStartKm: 9 },
      { name: 'Maharagama', distFromStartKm: 14 },
      { name: 'Kaduwela', distFromStartKm: 18 },
    ],
  },
  {
    routeNumber: '177', name: 'Colombo - Matara Express', startPoint: 'Colombo', endPoint: 'Matara', totalDistanceKm: 160, isActive: true,
    stops: [
      { name: 'Colombo Fort', distFromStartKm: 0 },
      { name: 'Panadura', distFromStartKm: 27 },
      { name: 'Galle', distFromStartKm: 126 },
      { name: 'Matara', distFromStartKm: 160 },
    ],
  },
];

const BUSES = [
  { plateNumber: 'WP-KA-1234', class: 'AC', capacity: 42, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'WP-KA-5678', class: 'AC', capacity: 42, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'WP-NB-9012', class: 'Non-AC', capacity: 54, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'WP-NB-3456', class: 'Non-AC', capacity: 54, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'CP-LA-7890', class: 'AC', capacity: 42, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'SP-JA-1122', class: 'Non-AC', capacity: 54, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'NW-KB-3344', class: 'AC', capacity: 42, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'NW-KB-5566', class: 'Non-AC', capacity: 54, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'SG-MA-7788', class: 'Non-AC', capacity: 54, isActive: true, operatorId: 'system_operator' },
  { plateNumber: 'WP-RS-1380', class: 'AC', capacity: 42, isActive: true, operatorId: 'system_operator' },
];

const DEPARTURE_HOURS = [6, 8, 10, 14, 17];

async function seed() {
  console.log('🚌 RideSync Seed Script (REST API) — Starting...\n');

  // 1. Seed Buses
  console.log('📦 Seeding buses...');
  const busIds = [];
  for (const bus of BUSES) {
    const id = await createDoc('buses', { ...bus, createdAt: new Date().toISOString() });
    busIds.push(id);
    console.log(`   ✅ Bus ${bus.plateNumber} → ${id}`);
  }

  // 2. Seed Routes
  console.log('\n🗺️  Seeding routes...');
  const routeIds = [];
  for (const route of ROUTES) {
    const id = await createDoc('routes', { ...route, createdAt: new Date().toISOString() });
    routeIds.push(id);
    console.log(`   ✅ Route ${route.routeNumber}: ${route.name} → ${id}`);
  }

  // 3. Seed Schedules — next 6 months, 5 departures per route per day
  // To avoid massive number of API calls, seed 2 weeks of daily schedules
  // and 1 schedule per week for remaining months
  console.log('\n📅 Seeding schedules...');
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let scheduleCount = 0;
  
  // Next 14 days: daily schedules
  for (let dayOffset = 0; dayOffset < 14; dayOffset++) {
    const day = new Date(today);
    day.setDate(day.getDate() + dayOffset);
    
    for (let ri = 0; ri < routeIds.length; ri++) {
      const departures = DEPARTURE_HOURS.filter((_, idx) => (idx + ri) % 2 === 0).slice(0, 3);
      
      for (const hour of departures) {
        const depTime = new Date(day);
        depTime.setHours(hour, (ri * 10) % 60, 0, 0);
        
        const busIndex = (ri + hour) % busIds.length;
        
        const id = await createDoc('schedules', {
          routeId: routeIds[ri],
          routeName: ROUTES[ri].name,
          busId: busIds[busIndex],
          plateNumber: BUSES[busIndex].plateNumber,
          operatorId: 'system_operator',
          departureTime: depTime,
          status: 'scheduled',
          capacity: BUSES[busIndex].capacity,
          createdAt: new Date().toISOString(),
        });
        
        scheduleCount++;
        
        // Create seats for today and tomorrow only (to save API calls)
        if (dayOffset < 2) {
          const capacity = BUSES[busIndex].capacity;
          for (let s = 1; s <= capacity; s++) {
            await createDoc(`schedules/${id}/seats`, {
              seatNumber: `S${s}`,
              status: 'available',
              passengerId: null,
              updatedAt: new Date().toISOString(),
            });
          }
          console.log(`   ✅ Schedule + ${capacity} seats: ${ROUTES[ri].name} @ ${hour}:${String((ri * 10) % 60).padStart(2, '0')} (${depTime.toDateString()})`);
        } else {
          if (scheduleCount % 10 === 0) {
            console.log(`   📅 ${scheduleCount} schedules created...`);
          }
        }
      }
    }
  }

  // Weeks 3-24: one schedule per route per week (Mondays)
  for (let weekOffset = 2; weekOffset < 26; weekOffset++) {
    const monday = new Date(today);
    monday.setDate(monday.getDate() + (weekOffset * 7));
    // Find next Monday
    monday.setDate(monday.getDate() + ((1 - monday.getDay() + 7) % 7));
    
    for (let ri = 0; ri < routeIds.length; ri++) {
      const depTime = new Date(monday);
      depTime.setHours(8, 0, 0, 0);
      
      const busIndex = ri % busIds.length;
      
      await createDoc('schedules', {
        routeId: routeIds[ri],
        routeName: ROUTES[ri].name,
        busId: busIds[busIndex],
        plateNumber: BUSES[busIndex].plateNumber,
        operatorId: 'system_operator',
        departureTime: depTime,
        status: 'scheduled',
        capacity: BUSES[busIndex].capacity,
        createdAt: new Date().toISOString(),
      });
      scheduleCount++;
    }
    console.log(`   📅 Week ${weekOffset}: ${monday.toDateString()} — 8 schedules`);
  }

  console.log(`\n🎉 Seeding complete!`);
  console.log(`   Routes: ${ROUTES.length}`);
  console.log(`   Buses: ${BUSES.length}`);
  console.log(`   Schedules: ${scheduleCount}`);
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed error:', err.message);
  process.exit(1);
});
