<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# give updated downloadable markdown file

Here is the complete updated `RIDESYNC_ARCHITECTURE.md` with all references to "Bus Driver" as a separate role removed, and driver responsibilities fully merged into the "Bus Operator" role (Flutter Mobile App):

***

```markdown
# RideSync — Software Architecture Reference
> Capstone Project | Group 21 | Sabaragamuwa University of Sri Lanka
> Prepared for: Antigravity Agentic Model Reference
> Version: 2.0 | March 2026

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Style: Pragmatic Modular Monolith](#2-architecture-style-pragmatic-modular-monolith)
3. [High-Level System Architecture](#3-high-level-system-architecture)
4. [Technology Stack](#4-technology-stack)
5. [Component Breakdown](#5-component-breakdown)
6. [Firebase / Database Design](#6-firebase--database-design)
7. [Fare Calculation Module](#7-fare-calculation-module)
8. [GPS Location Tracking](#8-gps-location-tracking)
9. [Communication Methods Summary](#9-communication-methods-summary)
10. [Security Architecture](#10-security-architecture)
11. [Deployment Architecture](#11-deployment-architecture)
12. [Data Flow Specifications](#12-data-flow-specifications)
13. [Scalability Upgrade Path](#13-scalability-upgrade-path)
14. [Known Risks & Mitigations](#14-known-risks--mitigations)
15. [14-Week Development Timeline](#15-14-week-development-timeline)
16. [Environment Variables Reference](#16-environment-variables-reference)
17. [Testing Strategy](#17-testing-strategy)

---

## 1. Project Overview

| Field | Value |
|---|---|
| Project Name | RideSync — An Intelligent Public Bus Transport Platform |
| University | Sabaragamuwa University of Sri Lanka |
| Department | Computing and Information Systems, Faculty of Computing |
| Group | Group 21 |
| Team Size | 5 students |
| Timeline | 14 weeks |
| Supervisor | Mr. A. Alan Steve Amath |
| Mentor | Mr. A. Mohamed Aslam Sujah |

### Purpose

RideSync modernizes public bus transportation in Sri Lanka by solving:
- Absence of real-time bus location information
- Route confusion among passengers
- Unfair, flat-rate fare structures for partial journeys
- Inefficient fleet and schedule management for operators
- Lack of a unified digital platform for passengers, operators, and administrators

### Target Users

| Role | Platform |
|---|---|
| Passenger | Flutter Mobile App |
| Bus Operator | Flutter Mobile App |
| Administrator | React Web Dashboard |

### Role Definitions

- **Passenger** — Books seats, tracks buses in real-time, views fare estimates, uses chatbot, submits feedback. Access via Flutter Mobile App only.
- **Bus Operator** — Drives the bus AND manages the trip. Starts/ends trips, broadcasts GPS, updates delays, manages seat availability and schedules. Access via Flutter Mobile App only.
- **Administrator** — Manages routes, schedules, fare structures, fleet, users, and analytics. Access via React Web Dashboard only.

### Core Features

- Pre-booking with seat selection and visual seat map
- Real-time GPS bus tracking on live map (operator's smartphone as GPS source)
- Rule-based ETA calculation (no custom ML)
- Segment-based distance fare calculation (AC / Non-AC classes)
- Smart route finder with alternate route suggestions
- AI chatbot for 24/7 passenger support (Dialogflow ES)
- Push notifications (FCM) + SMS alerts (Twilio)
- Analytics dashboards for administrators
- Rating and feedback system

---

## 2. Architecture Style: Pragmatic Modular Monolith

### Decision: Modular Monolith (NOT Microservices)

**Do NOT use microservices** for this project. Microservices require service discovery, API gateways, inter-service authentication, distributed tracing, and DevOps maturity that would consume the entire 14-week timeline just on infrastructure.

### Why Modular Monolith

- Single deployable unit → Firebase Cloud Functions handles the entire API
- Clear domain separation → each module has its own controller, service, and repository layer
- Team-friendly → 5 members can each own one module without complex distributed coordination
- Scalable later → modules can be extracted into separate Cloud Functions when required
- Firebase RTDB acts as the event-driven real-time backbone for GPS tracking, bypassing the Node.js API entirely

### Module Ownership (Recommended)

| Team Member | Module |
|---|---|
| MJA. Jinos | Flutter Mobile UI + Firebase Auth |
| V. Mathujan | React Web Dashboard + Google Maps integration |
| S. Rishikesan | Node.js API + CI/CD pipeline |
| E. Mayoori | Firebase RTDB GPS tracking + booking module |
| MSFI. Zeenath | FCM Notifications + Fare engine + Analytics |

---

## 3. High-Level System Architecture

```

┌──────────────────────────────────────────────────────────────────────────┐
│                             CLIENT LAYER                                  │
│  [Operator App - Flutter]  [Passenger App - Flutter]  [React Web Dashboard│
│   (GPS + Trip Mgmt)]        (Booking + Tracking)       (Admin Only)      ]│
└──────────┬──────────────────────────┬────────────────────────┬───────────┘
│ REST HTTPS               │ Firebase SDK           │ REST HTTPS
▼                          ▼                        ▼
┌──────────────────────┐   ┌──────────────────────────────────────────────┐
│    BACKEND LAYER      │   │              FIREBASE SERVICES                │
│  Node.js / Express    │   │                                              │
│  (Cloud Functions)    │   │  Cloud Firestore  │  Realtime DB  │  Auth    │
│                       │   │  FCM              │  Storage      │          │
└──────────┬────────────┘   └──────────────────────────────────────────────┘
│
├──► Google Maps API   (routing, distance matrix, geocoding)
├──► Twilio SMS API    (booking confirmations, delay alerts)
└──► Dialogflow API    (NLP chatbot, free tier)

```

### Four-Tier Overview

| Tier | Components |
|---|---|
| Client Tier | Flutter Mobile App (passengers + operators), React Web Dashboard (administrators only) |
| Backend Tier | Node.js/Express API deployed as Firebase Cloud Functions |
| Data Tier | Cloud Firestore (structured data), Firebase RTDB (live GPS stream) |
| External Services Tier | Google Maps API, Twilio SMS, Firebase FCM, Dialogflow |

---

## 4. Technology Stack

| Layer | Technology | Cost |
|---|---|---|
| Mobile App | Flutter 3 (Dart) | Free |
| State Management | Riverpod | Free |
| Navigation | go_router | Free |
| Web Dashboard | React 18 + Vite + React Query | Free |
| Web Charts | Recharts | Free |
| Backend API | Node.js 18 + Express.js | Free |
| Serverless Host | Firebase Cloud Functions (Node 18) | Free (2M calls/mo) |
| Primary Database | Firebase Firestore | Free (1GB, 50K reads/day) |
| GPS Realtime DB | Firebase Realtime Database | Free (1GB, 10GB transfer/mo) |
| Authentication | Firebase Authentication | Free |
| Push Notifications | Firebase Cloud Messaging (FCM) | Free (unlimited) |
| File Storage | Firebase Storage | Free (5GB) |
| Maps & Routing | Google Maps API | Free ($200/mo credit) |
| SMS | Twilio | ~LKR 2,000 budget |
| Chatbot | Dialogflow ES (Google) | Free tier |
| Web Hosting | Firebase Hosting + CDN | Free |
| CI/CD | GitHub Actions | Free (2,000 min/mo) |
| Input Validation | Joi | Free |
| HTTP Security | helmet.js | Free |
| Rate Limiting | express-rate-limit | Free |
| Local Caching | node-cache | Free |
| Offline Storage | Hive (Flutter) | Free |
| Design | Figma | Free (students) |
| API Testing | Postman | Free |
| Unit Testing | Jest (Node.js) + flutter_test | Free |

---

## 5. Component Breakdown

### 5.1 Flutter Mobile Application

**Architecture Pattern:** Feature-first folder structure with Riverpod providers

**Personas (role-based, single codebase, toggled by Firebase Auth role claim):**
- Passenger
- Bus Operator (handles both driving the bus AND managing the trip)

#### Passenger Screens

| Screen | Key Features |
|---|---|
| Home / Route Search | Origin-destination search, schedule listing |
| Fare Estimator | Pre-booking fare display with class options |
| Seat Picker UI | GridView seat map (green=available, red=booked, blue=selected) |
| Live Tracking Map | Google Maps widget + RTDB real-time listener, animated marker |
| Booking History | Confirmed/cancelled trips, e-ticket view |
| Notifications Center | FCM-driven, in-app notification list |
| AI Chatbot | Dialogflow WebView integration |
| Trip Ratings | Post-trip rating form (1–5 stars + comment) |

#### Bus Operator Screens

> The Bus Operator uses the Flutter mobile app to both drive the bus (GPS broadcasting) and manage trip operations (delays, seat updates, passenger manifest).

| Screen | Key Features |
|---|---|
| Login / Auth | Firebase Auth email/password |
| Trip Dashboard | Start Trip / End Trip buttons, passenger manifest view |
| GPS Broadcaster | Background geolocator writes to RTDB every 3–5s while trip is active |
| Status Update Form | Delay reporting, current stop updates |
| Seat Management | View and update seat availability in real-time |
| Schedule View | View assigned upcoming schedules |

#### Flutter Project Structure

```

/lib
/core
/constants         ← app colors, strings, routes
/errors            ← failure types
/utils             ← date helpers, formatters
/features
/auth
/data            ← auth_repository.dart
/presentation    ← login_screen.dart, register_screen.dart
/providers       ← auth_provider.dart
/booking
/data
/presentation    ← schedule_list.dart, seat_picker.dart, booking_confirm.dart
/providers
/tracking
/data
/presentation    ← tracking_map.dart
/providers       ← tracking_provider.dart (StreamProvider)
/fare
/data
/presentation    ← fare_estimator.dart
/providers
/operator
/data
/presentation    ← operator_dashboard.dart, status_update.dart, seat_manager.dart
/providers       ← gps_service.dart, trip_provider.dart
/notifications
/presentation    ← notifications_center.dart
/providers
/chatbot
/presentation    ← chatbot_webview.dart
/feedback
/presentation    ← ratings_form.dart
main.dart
firebase_options.dart

```

#### Key Flutter Packages

```yaml
dependencies:
  flutter_riverpod: ^2.x
  go_router: ^13.x
  google_maps_flutter: ^2.x
  geolocator: ^11.x
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_database: ^11.x
  firebase_messaging: ^15.x
  firebase_storage: ^12.x
  hive_flutter: ^1.x
  http: ^1.x
  intl: ^0.19.x
  cached_network_image: ^3.x
  webview_flutter: ^4.x
  flutter_local_notifications: ^17.x
```


---

### 5.2 React Web Admin Dashboard

**Built with:** Vite + React 18 + React Query + React Router v6 + Material UI or Tailwind CSS

> The React Web Dashboard is exclusively for **Administrators**. Bus Operators do not access the web dashboard — all operator functions are handled through the Flutter Mobile App.

#### Panels

| Panel | Accessible By | Key Features |
| :-- | :-- | :-- |
| Route Management | Administrator | Create/edit/deactivate routes, manage stop distances |
| Schedule Management | Administrator | Create schedules, assign buses and operators, set departure times |
| Fare Config Panel | Administrator | Set baseFare, ratePerKm per route, manage AC/NonAC rules |
| Fleet Management | Administrator | Bus CRUD, assign operators to buses, fleet health alerts |
| User Management | Administrator | View/edit users, assign roles, deactivate accounts |
| Analytics Dashboard | Administrator | Route performance charts, revenue reports, passenger feedback (Recharts) |
| Notification Broadcast | Administrator | Send FCM/SMS to all passengers on a route |

#### React Project Structure

```
/src
  /api               ← axios instances, API service functions
  /components        ← shared UI components (Table, Chart, Modal, Map)
  /features
    /auth            ← LoginPage, AuthGuard (admin-only guard)
    /routes          ← RouteManager, StopEditor
    /schedules       ← ScheduleManager, ScheduleCalendar
    /fares           ← FareConfigPanel, FareRuleEditor
    /fleet           ← BusManager, FleetMap (Google Maps JS API)
    /users           ← UserManager, RoleAssignment
    /analytics       ← RevenueChart, RoutePerfChart, FeedbackList
    /notifications   ← BroadcastForm, NotifHistory
  /hooks             ← useAuth, useRealtime, useFirestore
  /providers         ← QueryClientProvider, AuthProvider
  /router            ← route definitions with admin-only RBAC guard
  main.jsx
```


#### Key npm Packages

```json
{
  "@tanstack/react-query": "^5.x",
  "react-router-dom": "^6.x",
  "recharts": "^2.x",
  "@react-google-maps/api": "^2.x",
  "firebase": "^10.x",
  "axios": "^1.x",
  "react-hook-form": "^7.x",
  "zod": "^3.x",
  "date-fns": "^3.x",
  "@mui/material": "^5.x"
}
```


---

### 5.3 Node.js Backend — Modular Monolith

#### Project Structure

```
/functions
  /src
    /middleware
      auth.middleware.js          ← Firebase JWT verification
      rbac.middleware.js          ← Role-based access guard
      rateLimit.middleware.js     ← 100 req / 15 min per IP
      validate.middleware.js      ← Joi schema validation
      errorHandler.middleware.js  ← Centralized error formatting

    /modules
      /booking
        booking.controller.js    ← Express route handlers
        booking.service.js       ← Business logic, atomic seat lock
        booking.repo.js          ← Firestore read/write
        booking.schema.js        ← Joi validation schema
      /route
        route.controller.js
        route.service.js
        route.repo.js
      /fare
        fare.controller.js
        fare.service.js          ← Haversine + rate table engine
        fare.repo.js
      /schedule
        schedule.controller.js
        schedule.service.js
        schedule.repo.js
      /notification
        notification.service.js  ← FCM + Twilio dispatch
      /analytics
        analytics.controller.js  ← Aggregation queries
        analytics.service.js
      /chatbot
        chatbot.proxy.js         ← Dialogflow API proxy

    /config
      firebase.config.js         ← Firebase Admin SDK init
      maps.config.js             ← Google Maps client
      twilio.config.js           ← Twilio client
      dialogflow.config.js       ← Dialogflow client

    app.js                       ← Express app + middleware setup
    index.js                     ← Firebase Cloud Functions entry point

  package.json
  .env
```


#### Full API Route Map

```
AUTH
POST   /api/auth/register           → Create user + set role claim
POST   /api/auth/set-role           → Admin: assign role to user [RBAC: admin]

ROUTES
GET    /api/routes                  → List all active routes
GET    /api/routes/:id              → Route details + stops array
POST   /api/routes                  → Admin: create route [RBAC: admin]
PUT    /api/routes/:id              → Admin: update route [RBAC: admin]
DELETE /api/routes/:id              → Admin: deactivate route [RBAC: admin]

SCHEDULES
GET    /api/schedules               → Query: ?from=X&to=Y&date=YYYY-MM-DD
GET    /api/schedules/:id           → Schedule detail
GET    /api/schedules/:id/seats     → Live seat availability map
POST   /api/schedules               → Admin: create schedule [RBAC: admin]
PUT    /api/schedules/:id           → Operator: update status or delay [RBAC: operator|admin]
DELETE /api/schedules/:id           → Admin: cancel schedule [RBAC: admin]

FARE
GET    /api/fare                    → ?scheduleId=X&fromStop=A&toStop=B&class=AC
GET    /api/fares/:routeId          → All fare rules for a route
POST   /api/fares                   → Admin: create fare rule [RBAC: admin]
PUT    /api/fares/:id               → Admin: update fare rule [RBAC: admin]

BOOKINGS
POST   /api/bookings                → Passenger: book seat (Firestore transaction)
GET    /api/bookings/my             → Passenger: own booking history
GET    /api/bookings/:id            → Booking detail (own or admin)
PUT    /api/bookings/:id/cancel     → Cancel booking
GET    /api/bookings/schedule/:id   → Operator/Admin: all bookings for a schedule

ANALYTICS
GET    /api/analytics/routes        → Route performance KPIs [RBAC: admin]
GET    /api/analytics/revenue       → Revenue by route and time period [RBAC: admin]
GET    /api/analytics/fleet         → Fleet punctuality report [RBAC: admin]
GET    /api/analytics/feedback      → Aggregated passenger ratings [RBAC: admin]

NOTIFICATIONS
POST   /api/notify/broadcast        → Admin: send FCM + SMS to route passengers [RBAC: admin]
POST   /api/notify/user/:uid        → Admin: send notification to specific user [RBAC: admin]

CHATBOT
POST   /api/chatbot/message         → Proxy message to Dialogflow, return response

HEALTH
GET    /api/health                  → Service health check (no auth required)
```


---

## 6. Firebase / Database Design

> **Critical Note:** The original proposal defines relational tables with INT primary keys and FOREIGN KEY relationships. Firestore is a NoSQL document database and cannot perform SQL JOINs. All schemas below are redesigned as Firestore document collections using denormalization and document embedding.

### 6.1 Firestore Collections

#### `/users/{uid}`

```
uid:        string   (Firebase Auth UID — used as document ID)
name:       string
email:      string
phone:      string
role:       "passenger" | "operator" | "admin"
busId:      string | null   (operators only — their assigned bus)
fcmToken:   string          (updated on each app open)
createdAt:  timestamp
updatedAt:  timestamp
```


#### `/routes/{routeId}`

```
routeId:          string   (auto-generated)
startPoint:       string
endPoint:         string
totalDistanceKm:  number
stops:            array [
                    { name: string, distFromStartKm: number }
                  ]         (ordered array of all stops)
isActive:         boolean
createdAt:        timestamp
updatedAt:        timestamp
```


#### `/buses/{busId}`

```
busId:        string
operatorId:   string   (references users/{uid} — the assigned operator)
plateNumber:  string
class:        "AC" | "NonAC"
capacity:     number
isActive:     boolean
createdAt:    timestamp
```


#### `/schedules/{scheduleId}`

```
scheduleId:     string
routeId:        string
busId:          string
operatorId:     string   (the operator assigned to drive this schedule)
departureTime:  timestamp
status:         "scheduled" | "active" | "completed" | "cancelled"
delayMinutes:   number   (default 0)
currentStop:    string
eta:            timestamp
seatMap:        map {
                  "A1": null,         (null = available)
                  "A2": "uid_xyz",    (uid = booked by passenger)
                  "B1": null,
                  ...
                }
createdAt:      timestamp
updatedAt:      timestamp
```

> **Scaling note:** When bus capacity exceeds 50 seats, move seatMap to a subcollection `/schedules/{id}/seats/{seatNo}` to stay within Firestore's 1MB document size limit.

#### `/bookings/{bookingId}`

```
bookingId:      string
passengerId:    string
scheduleId:     string
fromStop:       string
toStop:         string
seatNo:         string
fare:           number
fareBreakdown:  map {
                  baseFare:         number,
                  segmentKm:        number,
                  ratePerKm:        number,
                  classMultiplier:  number,
                  busClass:         string
                }
status:         "confirmed" | "cancelled" | "completed"
bookedAt:       timestamp
updatedAt:      timestamp
```


#### `/fares/{fareId}`

```
fareId:     string
routeId:    string
class:      "AC" | "NonAC"
baseFare:   number   (LKR)
ratePerKm:  number   (LKR per km)
createdAt:  timestamp
updatedAt:  timestamp
```


#### `/feedback/{feedbackId}`

```
feedbackId:   string
passengerId:  string
scheduleId:   string
busId:        string
rating:       number   (1–5)
comment:      string
submittedAt:  timestamp
```


#### `/notifications/{uid}/items/{notifId}`

```
notifId:    string
title:      string
body:       string
type:       "booking" | "delay" | "alert" | "promo"
isRead:     boolean
createdAt:  timestamp
```


---

### 6.2 Firebase Realtime Database (GPS)

```json
{
  "busLocations": {
    "{busId}": {
      "lat": 6.9271,
      "lng": 79.8612,
      "speed": 45.2,
      "heading": 180,
      "timestamp": 1741423200000
    }
  },
  "tripStatus": {
    "{scheduleId}": {
      "status": "active",
      "currentStop": "Kadawatha",
      "eta": 1741426800000,
      "delayMinutes": 5,
      "lastUpdatedAt": 1741423200000
    }
  }
}
```

> **RTDB is used only for high-frequency, low-latency writes.** All other data lives in Firestore.

---

### 6.3 Firestore Composite Indexes (Required)

```
Collection: schedules
Fields: routeId (ASC), departureTime (ASC)
Use: Schedule search by route and date

Collection: schedules
Fields: operatorId (ASC), status (ASC)
Use: Operator's active and upcoming schedule view on mobile

Collection: bookings
Fields: passengerId (ASC), status (ASC), bookedAt (DESC)
Use: Passenger booking history

Collection: bookings
Fields: scheduleId (ASC), status (ASC)
Use: Operator view of passengers per trip

Collection: feedback
Fields: scheduleId (ASC), submittedAt (DESC)
Use: Feedback retrieval per trip
```


---

## 7. Fare Calculation Module

### Algorithm

```
fare = baseFare + (segmentDistanceKm × ratePerKm × classMultiplier)

Where:
  segmentDistanceKm  = stops[toIdx].distFromStartKm - stops[fromIdx].distFromStartKm
  classMultiplier    = 1.0 (NonAC) | 1.5 (AC)
  baseFare           = admin-configured per route (stored in /fares)
  ratePerKm          = admin-configured per route (stored in /fares)
  final total        = Math.ceil(total)   ← round up to nearest LKR
```

> **Stop distances are precomputed** via Google Maps Distance Matrix API when an admin creates or updates a route. They are stored in the route document. This avoids per-booking Maps API calls and controls cost.

### Implementation (`fare.service.js`)

```javascript
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 3600 }); // 1-hour TTL

/**
 * Calculate segment-based fare.
 * @param {string} scheduleId
 * @param {string} fromStop
 * @param {string} toStop
 * @param {string} busClass  "AC" | "NonAC"
 * @returns {FareBreakdown}
 */
async function calculateFare(scheduleId, fromStop, toStop, busClass) {
  // 1. Fetch schedule to get routeId
  const schedule = await scheduleRepo.getById(scheduleId);
  const { routeId, busId } = schedule;

  // 2. Fetch bus to get class (override if not passed)
  const bus = await busRepo.getById(busId);
  const resolvedClass = busClass || bus.class;

  // 3. Fetch route from cache or Firestore
  const cacheKey = `route_${routeId}`;
  let route = cache.get(cacheKey);
  if (!route) {
    route = await routeRepo.getById(routeId);
    cache.set(cacheKey, route);
  }

  // 4. Find stop indices
  const fromIdx = route.stops.findIndex(s => s.name === fromStop);
  const toIdx   = route.stops.findIndex(s => s.name === toStop);

  if (fromIdx === -1 || toIdx === -1) {
    throw new Error('Invalid stop names for this route');
  }
  if (fromIdx >= toIdx) {
    throw new Error('fromStop must come before toStop on this route');
  }

  // 5. Compute segment distance
  const segmentKm = route.stops[toIdx].distFromStartKm
                  - route.stops[fromIdx].distFromStartKm;

  // 6. Fetch fare rule
  const fareRule = await fareRepo.getByRouteAndClass(routeId, resolvedClass);

  // 7. Apply class multiplier
  const classMultiplier = resolvedClass === 'AC' ? 1.5 : 1.0;

  // 8. Compute total
  const rawTotal = fareRule.baseFare + (segmentKm * fareRule.ratePerKm * classMultiplier);
  const total = Math.ceil(rawTotal);

  return {
    total,
    baseFare: fareRule.baseFare,
    segmentKm: parseFloat(segmentKm.toFixed(2)),
    ratePerKm: fareRule.ratePerKm,
    classMultiplier,
    busClass: resolvedClass
  };
}

module.exports = { calculateFare };
```


### Fare API Controller (`fare.controller.js`)

```javascript
const { calculateFare } = require('./fare.service');

async function getFareEstimate(req, res, next) {
  try {
    const { scheduleId, fromStop, toStop, class: busClass } = req.query;
    const breakdown = await calculateFare(scheduleId, fromStop, toStop, busClass);
    res.json({ success: true, data: breakdown });
  } catch (err) {
    next(err);
  }
}
```


---

## 8. GPS Location Tracking

> GPS is broadcast by the **Bus Operator's smartphone** via the Flutter mobile app. There is no separate driver device — the operator handles both driving and GPS broadcasting.

### Operator App — GPS Broadcaster (`gps_service.dart`)

```dart
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GpsService {
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();
  Timer? _locationTimer;
  static const int _fastIntervalSec = 3;
  static const int _slowIntervalSec = 10;
  static const double _movingSpeedMps = 1.4; // 5 km/h

  void startBroadcasting(String busId) {
    _scheduleUpdate(busId, _fastIntervalSec);
  }

  void _scheduleUpdate(String busId, int intervalSec) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      Duration(seconds: intervalSec),
      (_) async {
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          final bool isMoving = pos.speed >= _movingSpeedMps;
          final int nextInterval = isMoving ? _fastIntervalSec : _slowIntervalSec;

          // Adaptive: reschedule at slower rate if idle
          if (nextInterval != intervalSec) {
            _scheduleUpdate(busId, nextInterval);
            return;
          }

          await _rtdb.child('busLocations/$busId').set({
            'lat': pos.latitude,
            'lng': pos.longitude,
            'speed': double.parse((pos.speed * 3.6).toStringAsFixed(1)), // m/s → km/h
            'heading': pos.heading,
            'timestamp': ServerValue.timestamp,
          });
        } catch (e) {
          debugPrint('GPS write error: $e');
        }
      },
    );
  }

  void stopBroadcasting() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
}
```


### Passenger App — Live Tracking Listener (`tracking_provider.dart`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';

class BusLocation {
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final int timestamp;

  const BusLocation({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });

  factory BusLocation.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return BusLocation(
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      speed: (data['speed'] as num).toDouble(),
      heading: (data['heading'] as num).toDouble(),
      timestamp: data['timestamp'] as int,
    );
  }

  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - timestamp > 30000; // 30s
}

final trackingProvider = StreamProvider.family<BusLocation, String>((ref, busId) {
  return FirebaseDatabase.instance
      .ref('busLocations/$busId')
      .onValue
      .map((event) => BusLocation.fromSnapshot(event.snapshot));
});
```


### Show Stale Signal Warning (Flutter Widget)

```dart
// In tracking_map.dart
Consumer(
  builder: (context, ref, child) {
    final trackingAsync = ref.watch(trackingProvider(busId));
    return trackingAsync.when(
      data: (location) {
        if (location.isStale) {
          return const Banner(
            message: 'Location signal lost',
            location: BannerLocation.topStart,
            color: Colors.orange,
            child: SizedBox.shrink(),
          );
        }
        return _updateMarker(location);
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Tracking unavailable'),
    );
  },
),
```


### ETA Cloud Function (RTDB-triggered, `index.js`)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.recalculateETA = functions.database
  .ref('/busLocations/{busId}')
  .onWrite(async (change, context) => {
    if (!change.after.exists()) return null;

    const { busId } = context.params;
    const location = change.after.val();

    try {
      // 1. Find active schedule for this bus
      const schedulesSnap = await admin.firestore()
        .collection('schedules')
        .where('busId', '==', busId)
        .where('status', '==', 'active')
        .limit(1)
        .get();

      if (schedulesSnap.empty) return null;

      const scheduleDoc = schedulesSnap.docs;
      const { routeId } = scheduleDoc.data();

      // 2. Get route for stop distances
      const routeDoc = await admin.firestore()
        .collection('routes').doc(routeId).get();
      const route = routeDoc.data();

      // 3. Find current stop index → compute remainingKm
      const currentStopIdx = route.stops.findIndex(
        s => s.name === scheduleDoc.data().currentStop
      );
      const endStop = route.stops[route.stops.length - 1];
      const remainingKm = endStop.distFromStartKm
        - route.stops[currentStopIdx].distFromStartKm;

      // 4. Compute ETA using current speed
      const avgSpeedKmh = Math.max(location.speed || 30, 10); // floor at 10 km/h
      const etaMs = Date.now() + (remainingKm / avgSpeedKmh) * 3600 * 1000;

      // 5. Write back to RTDB
      await admin.database()
        .ref(`/tripStatus/${scheduleDoc.id}`)
        .update({
          eta: etaMs,
          lastUpdatedAt: Date.now()
        });

      return null;
    } catch (err) {
      console.error('ETA calculation failed:', err);
      return null;
    }
  });
```


---

## 9. Communication Methods Summary

| Connection | Protocol | Use Case |
| :-- | :-- | :-- |
| Passenger App → Node.js API | REST HTTPS (JSON) | Booking, route search, fare query |
| Operator App → Node.js API | REST HTTPS (JSON) | Trip status updates, schedule fetch |
| React Web Dashboard → Node.js API | REST HTTPS (JSON) | Admin CRUD, reporting, analytics |
| Operator App → Firebase RTDB | Firebase SDK (WebSocket) | GPS location writes every 3–5s |
| Passenger App ← Firebase RTDB | Firebase SDK `.onValue` listener | Real-time map updates without polling |
| Node.js → Firestore | Firebase Admin SDK | Transactional booking writes, data reads |
| Node.js → Firebase FCM | Firebase Admin SDK | Push notification dispatch |
| Node.js → Twilio | REST HTTPS | SMS booking confirmation and delay alerts |
| Node.js → Google Maps | REST HTTPS | Distance matrix, geocoding for route creation |
| Node.js → Dialogflow | REST HTTPS | NLP chatbot proxy |
| Firebase Cloud Function ← RTDB trigger | RTDB write trigger | ETA recalculation on each GPS update |
| React Dashboard ← Firestore | Firebase SDK real-time listener | Live fleet status on admin map |


---

## 10. Security Architecture

### 10.1 Authentication Flow

```
1. User opens app → Firebase Auth (email/password or Google OAuth)
2. Firebase issues signed JWT (ID Token, 1-hour expiry, auto-refreshed)
3. On first login, backend POST /api/auth/register sets custom role claim:
   admin.auth().setCustomUserClaims(uid, { role: 'passenger' })
   admin.auth().setCustomUserClaims(uid, { role: 'operator', busId: 'BUS001' })
   admin.auth().setCustomUserClaims(uid, { role: 'admin' })
4. Client includes token in every API request:
   Authorization: Bearer <Firebase_ID_Token>
5. auth.middleware.js:
   const decoded = await admin.auth().verifyIdToken(token);
   req.user = decoded;
6. rbac.middleware.js:
   if (decoded.role !== requiredRole) return res.status(403).json({ error: 'Forbidden' });
```


### 10.2 RBAC Matrix

| Resource | Passenger | Bus Operator | Administrator |
| :-- | :-- | :-- | :-- |
| Read routes / schedules | ✅ | ✅ | ✅ |
| Create booking | ✅ | ❌ | ✅ |
| Cancel own booking | ✅ | ❌ | ✅ |
| Write GPS to RTDB | ❌ | ✅ (own bus only) | ✅ |
| Start / end trip | ❌ | ✅ (own schedule) | ✅ |
| Update schedule status / delay | ❌ | ✅ (own schedule) | ✅ |
| View passenger manifest | ❌ | ✅ (own schedule) | ✅ |
| Create / edit routes | ❌ | ❌ | ✅ |
| Create / edit schedules | ❌ | ❌ | ✅ |
| Create / edit fare rules | ❌ | ❌ | ✅ |
| View analytics | ❌ | ❌ | ✅ |
| Manage users / assign roles | ❌ | ❌ | ✅ |
| Broadcast notifications | ❌ | ❌ | ✅ |

### 10.3 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users: own profile only, admin reads all
    match /users/{uid} {
      allow read, update: if request.auth.uid == uid;
      allow create: if request.auth != null;
      allow read: if request.auth.token.role == 'admin';
    }

    // Routes: authenticated read, admin write
    match /routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin';
    }

    // Schedules: authenticated read, operator updates own, admin full write
    match /schedules/{scheduleId} {
      allow read: if request.auth != null;
      allow update: if request.auth.token.role == 'operator'
                    && request.auth.token.busId == resource.data.busId;
      allow create, delete: if request.auth.token.role == 'admin';
      allow update: if request.auth.token.role == 'admin';
    }

    // Fares: authenticated read, admin write
    match /fares/{fareId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin';
    }

    // Bookings: passenger reads/writes own, operator reads own schedule, admin reads all
    match /bookings/{bookingId} {
      allow read: if request.auth.uid == resource.data.passengerId
                  || request.auth.token.role in ['operator', 'admin'];
      allow create: if request.auth.token.role == 'passenger';
      allow update: if request.auth.uid == resource.data.passengerId
                    || request.auth.token.role == 'admin';
    }

    // Feedback: passenger creates own, admin reads
    match /feedback/{feedbackId} {
      allow create: if request.auth.token.role == 'passenger';
      allow read: if request.auth.token.role == 'admin';
    }

    // Notifications: user reads/writes own only
    match /notifications/{uid}/items/{notifId} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```


### 10.4 Firebase RTDB Security Rules

```json
{
  "rules": {
    "busLocations": {
      "$busId": {
        ".read": "auth != null",
        ".write": "auth != null && auth.token.role == 'operator'
                   && auth.token.busId == $busId"
      }
    },
    "tripStatus": {
      "$scheduleId": {
        ".read": "auth != null",
        ".write": "auth != null && (auth.token.role == 'operator'
                   || auth.token.role == 'admin')"
      }
    }
  }
}
```


### 10.5 Express Security Middleware (`app.js`)

```javascript
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import express from 'express';

const app = express();

// Security headers
app.use(helmet());

// Body size limit
app.use(express.json({ limit: '10kb' }));

// Rate limiting — all API routes
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000,   // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' }
}));

// Stricter limit for booking endpoint (prevent seat-lock abuse)
app.use('/api/bookings', rateLimit({
  windowMs: 60 * 1000,         // 1 minute
  max: 10,
  message: { error: 'Booking rate limit exceeded.' }
}));
```


### 10.6 Additional Security Checklist

- [ ] All environment variables in `.env` — never committed to Git
- [ ] `.gitignore` includes `.env`, `service-account.json`, `google-services.json`
- [ ] Firebase App Check enabled for mobile apps (prevents unauthorized API use)
- [ ] Joi input validation on all POST and PUT request bodies
- [ ] SSL/TLS enforced via Firebase Hosting (automatic)
- [ ] JWT role claims verified server-side — never trust client-side role data
- [ ] Firestore transactions used for all seat booking writes (prevents race conditions)
- [ ] FCM tokens rotated on each app session
- [ ] Operator GPS writes scoped strictly to their assigned `busId` via RTDB rules

---

## 11. Deployment Architecture

### 11.1 Infrastructure Map (All Free Tier)

```
[GitHub Repository — main branch]
          │
          ▼
[GitHub Actions CI/CD Pipeline]
          │
          ├─ Run Jest unit tests (Node.js)
          ├─ Run flutter test (Flutter)
          ├─ Build Flutter APK (release artifact)
          │
          ├──► Firebase Cloud Functions   (Node.js Express API)
          └──► Firebase Hosting           (React Web App + CDN + auto SSL)
                    │
                    ▼
      [Google Cloud Platform — Firebase Project: ridesync-prod]
          │
          ├── Firebase Hosting            React Admin Dashboard, CDN, SSL
          ├── Firebase Cloud Functions    Node.js 18 Express API, auto-scale
          ├── Cloud Firestore             Primary database
          ├── Firebase Realtime Database  GPS streaming (operator → passenger)
          ├── Firebase Authentication     Auth, JWT, OAuth (3 roles)
          ├── Firebase Cloud Messaging    Push notifications
          └── Firebase Storage            Assets, logs, backups
                    │
                    ├──► Google Maps API    (external — distance matrix, geocoding)
                    ├──► Twilio SMS API     (external — booking SMS)
                    └──► Dialogflow API     (external — chatbot NLP)
```


### 11.2 Free Tier Limits Reference

| Service | Free Limit | Action When Near Limit |
| :-- | :-- | :-- |
| Cloud Functions | 2M invocations/mo | Add caching to reduce call frequency |
| Firestore reads | 50,000/day | Use node-cache (TTL 1hr) for routes/fares |
| Firestore writes | 20,000/day | Batch writes where possible |
| Firestore storage | 1 GB | Archive old bookings to Cloud Storage |
| RTDB storage | 1 GB | Overwrite GPS node per bus (not append) |
| RTDB download | 10 GB/mo | Monitor GPS stream; use adaptive throttle |
| Firebase Hosting | 10 GB storage, 360 MB/day transfer | Adequate for capstone |
| Firebase Storage | 5 GB | Adequate |
| FCM | Unlimited | No action needed |
| Firebase Auth | Unlimited | No action needed |
| Google Maps | \$200/mo free credit | Precompute stop distances at route creation |

### 11.3 GitHub Actions CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: RideSync CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - name: Install dependencies
        run: cd functions && npm ci
      - name: Run Jest tests
        run: cd functions && npm test

  test-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - name: Get Flutter packages
        run: cd mobile && flutter pub get
      - name: Run Flutter tests
        run: cd mobile && flutter test
      - name: Build APK
        run: cd mobile && flutter build apk --release

  deploy:
    needs: [test-backend, test-flutter]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - name: Build React app
        run: cd web && npm ci && npm run build
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: ridesync-prod
          channelId: live
```


### 11.4 Firebase Project Setup Commands

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and init project
firebase login
firebase init

# Select: Hosting, Functions, Firestore, Database, Storage
# Functions language: JavaScript (Node 18)

# Local emulator for development
firebase emulators:start

# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only hosting
firebase deploy --only hosting
```


---

## 12. Data Flow Specifications

### Flow 1: GPS Tracking

```
Step 1:  Operator opens Flutter app → Firebase Auth → role claim verified as "operator"
Step 2:  Operator taps "Start Trip" on Operator Dashboard
Step 3:  Flutter GpsService.startBroadcasting(busId) starts Timer (3s)
Step 4:  geolocator.getCurrentPosition() → { lat, lng, speed, heading }
Step 5:  If speed < 1.4 m/s (5 km/h) → adaptive mode, use 10s interval
Step 6:  Write to Firebase RTDB: /busLocations/{busId}
           { lat, lng, speed, heading, timestamp: ServerValue.timestamp }
Step 7:  RTDB write triggers Cloud Function: recalculateETA()
           7a. Query Firestore: schedules WHERE busId=X AND status='active'
           7b. Get route document → extract stops[] with distFromStartKm
           7c. Find current stop index → compute remainingKm
           7d. avgSpeedKmh = max(location.speed, 10)
           7e. etaMs = Date.now() + (remainingKm / avgSpeedKmh) * 3,600,000
           7f. Write RTDB: /tripStatus/{scheduleId} → { eta, lastUpdatedAt }
Step 8:  Passenger app: RTDB .onValue listener on /busLocations/{busId} fires
Step 9:  trackingProvider stream emits new BusLocation
Step 10: Google Maps marker animated to new coordinates
Step 11: If (Date.now() - location.timestamp) > 30,000ms → show orange "Signal lost" banner
Step 12: Operator taps "End Trip" → GpsService.stopBroadcasting()
           Write Firestore: schedules/{id} → { status: 'completed' }
```


### Flow 2: Seat Booking

```
Step 1:  Passenger searches: GET /api/schedules?from=Colombo&to=Kandy&date=2026-04-10
Step 2:  API: Firestore query with composite index (routeId, departureTime)
Step 3:  Response: array of schedules with full seatMap (null = available, uid = booked)
Step 4:  Passenger taps schedule → visual seat picker rendered from seatMap
Step 5:  Passenger selects fromStop, toStop, seat
Step 6:  Fare estimator: GET /api/fare?scheduleId=X&fromStop=A&toStop=C&class=AC
Step 7:  Response: { total: 480, segmentKm: 115.3, ... }
Step 8:  Passenger reviews fare breakdown → taps "Confirm Booking"
Step 9:  POST /api/bookings { scheduleId, seatNo, fromStop, toStop }
Step 10: booking.service.js — Firestore transaction:
           10a. READ schedules/{scheduleId}
           10b. ASSERT seatMap[seatNo] === null → throws 409 if already taken
           10c. SET seatMap[seatNo] = req.user.uid
           10d. CREATE bookings/{auto-id} with all booking fields
           10e. COMMIT transaction atomically
Step 11: notification.service.js:
           11a. FCM push → passenger device (booking confirmed)
           11b. Twilio SMS → passenger phone (booking confirmation + seat info)
           11c. Write to /notifications/{uid}/items/{auto-id}
Step 12: Response 201: { bookingId, seatNo, fare, fareBreakdown }
```


### Flow 3: Fare Calculation

```
Step 1:  GET /api/fare?scheduleId=SCH001&fromStop=Colombo&toStop=Peradeniya&class=AC
Step 2:  fare.controller.js → fare.service.calculateFare()
Step 3:  Fetch schedule SCH001 from Firestore → get routeId, busId
Step 4:  Check node-cache for route_{routeId}:
           Cache HIT  → use cached route (no Firestore call)
           Cache MISS → fetch from Firestore, store with TTL 1hr
Step 5:  route.stops = [
           { name: 'Colombo',    distFromStartKm: 0 },
           { name: 'Kadawatha',  distFromStartKm: 18.2 },
           { name: 'Kegalle',    distFromStartKm: 82.5 },
           { name: 'Peradeniya', distFromStartKm: 115.3 },
           { name: 'Kandy',      distFromStartKm: 121.0 }
         ]
Step 6:  fromIdx = 0 (Colombo), toIdx = 3 (Peradeniya)
Step 7:  segmentKm = 115.3 - 0 = 115.3 km
Step 8:  Fetch fareRule: baseFare=50, ratePerKm=2.5
Step 9:  classMultiplier = 1.5 (AC)
Step 10: rawTotal = 50 + (115.3 × 2.5 × 1.5) = 50 + 432.375 = 482.375
Step 11: total = Math.ceil(482.375) = 483 LKR
Step 12: Response 200: {
           total: 483,
           baseFare: 50,
           segmentKm: 115.3,
           ratePerKm: 2.5,
           classMultiplier: 1.5,
           busClass: "AC"
         }
```


### Flow 4: Notification Dispatch

```
Triggering Events:
  A. Booking confirmed (immediate, on booking creation)
  B. Trip starting in 30 minutes (scheduled Cloud Function cron)
  C. Bus delayed > 10 minutes (operator updates delayMinutes on their schedule)
  D. Bus arriving at passenger's stop in ~5 minutes (ETA proximity check)
  E. Booking cancelled by administrator

notification.service.sendToUser(uid, payload):
  Step 1: Fetch users/{uid} → get fcmToken, phone
  Step 2: admin.messaging().send({
            token: fcmToken,
            notification: { title: payload.title, body: payload.body },
            data: { type: payload.type, bookingId: payload.bookingId }
          })
  Step 3: twilio.messages.create({
            to: phone,
            from: process.env.TWILIO_PHONE_NUMBER,
            body: `${payload.title}: ${payload.body}`
          })
  Step 4: admin.firestore()
            .collection('notifications').doc(uid)
            .collection('items').add({
              title: payload.title,
              body: payload.body,
              type: payload.type,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            })

notification.service.broadcastToRoute(scheduleId, payload):
  Step 1: Query bookings WHERE scheduleId=X AND status='confirmed'
  Step 2: Extract unique passengerIds
  Step 3: Fetch all FCM tokens in batch
  Step 4: admin.messaging().sendEachForMulticast({ tokens, notification })
  Step 5: Twilio sequential SMS with 100ms delay (rate limit safe)
  Step 6: Bulk-write notifications to each passenger's subcollection
```


---

## 13. Scalability Upgrade Path

### Stage 1: Optimization (0 → 5,000 users, Free Tier)

| Action | Impact |
| :-- | :-- |
| Add `node-cache` for routes/fares (TTL 1hr) | Reduces Firestore reads by ~70% |
| Add composite Firestore indexes | Eliminates full collection scans |
| Adaptive GPS throttle (3s moving / 10s idle) on operator device | Reduces RTDB writes by ~60% |
| Move seatMap to subcollection `/schedules/{id}/seats/{seatNo}` | Prevents 1MB document limit breach |
| Use Firebase Emulator Suite for demos | Prevents exhausting daily free tier quota |

### Stage 2: Upgrade Compute (5,000 → 50,000 users)

| Action | Service | Notes |
| :-- | :-- | :-- |
| Migrate API to Google Cloud Run | Cloud Run | Containerized Node.js, warm instances, still scales to zero |
| Add Redis distributed cache | Upstash (free tier) | Replace in-memory node-cache for multi-instance consistency |
| Enable Firestore offline persistence on mobile | Firebase SDK | Reduces repeated reads, works offline |
| Upgrade to Blaze (pay-as-you-go) | Firebase | Only costs when free limits are exceeded |

### Stage 3: Scale Data Layer (50,000+ users)

| Action | Service | Notes |
| :-- | :-- | :-- |
| Add Google Cloud Pub/Sub for notifications | GCP | Prevents API timeout on bulk fan-out |
| Shard high-write Firestore collections | Firestore | Distribute seat writes across shards |
| BigQuery for analytics | GCP | Stream booking/trip data for deep reporting |
| Firebase App Check | Firebase | Mobile attestation to prevent API abuse |
| Archive old data to Cloud Storage | GCS | Keep Firestore lean with TTL-based archival |


---

## 14. Known Risks \& Mitigations

| \# | Risk | Severity | Mitigation |
| :-- | :-- | :-- | :-- |
| 1 | AI scope overload — custom ML ETA + NLP chatbot + route optimization in 14 weeks | HIGH | Use rule-based ETA formula (remainingKm / avgSpeed). Use Dialogflow ES (Google, free) for chatbot. Eliminate custom ML from v1. |
| 2 | NoSQL vs relational schema mismatch — proposal uses INT PKs and FOREIGN KEY constraints but proposes Firebase | HIGH | Redesign all tables as Firestore document collections. Use denormalization and document embedding. No JOINs. |
| 3 | GPS battery drain — continuous GPS on operator's smartphone drains battery in 2–3 hours | MEDIUM | Adaptive tracking: 3s when speed > 5 km/h, 10s when stationary. Use FusedLocationProviderClient on Android. |
| 4 | No payment gateway — manual fare collection limits the platform's core value | MEDIUM | Integrate PayHere (Sri Lanka, sandbox available). Add redirect-based payment on seat booking confirmation. |
| 5 | Operator device GPS failure — passengers see frozen map with no staleness indicator | MEDIUM | Check `lastUpdatedAt` timestamp. Show orange "Location signal lost" banner if > 30s since last update. |
| 6 | Firestore 50K reads/day exhausted during demos | MEDIUM | Use Firebase Emulator Suite for demos. Cache routes/fares with node-cache. Use RTDB for all streaming data. |
| 7 | Double-booking race condition — two passengers booking same seat simultaneously | MEDIUM | Mandatory Firestore transactions for all seat writes. Never use non-transactional document.set() for booking. |
| 8 | No offline mode — poor connectivity on intercity routes in Sri Lanka | LOW | Cache booking confirmations and route data locally with Hive. Show cached e-ticket when offline. |
| 9 | Missing visual seat picker UI — proposal mentions seat booking but no UI design | LOW | Build GridView.builder seat grid in Flutter. Color-code: green (available), red (booked), blue (selected). |
| 10 | API abuse / input injection | LOW | Joi validation on all endpoints. helmet.js + express-rate-limit. Always verify Firebase token server-side. |


---

## 15. 14-Week Development Timeline

| Weeks | Phase | Deliverables |
| :-- | :-- | :-- |
| 1–2 | Foundation \& Setup | Firebase project, GitHub repo + branch strategy, CI/CD pipeline, Figma wireframes for all screens (3 roles) |
| 3–4 | Auth + Core Data Models | Firebase Auth with 3 role claims (passenger, operator, admin), Firestore schema setup, Flutter app skeleton, React admin dashboard skeleton |
| 5–6 | Booking Module | Route search API, seat availability endpoint, Firestore booking transaction, FCM + Twilio integration |
| 7–8 | GPS + Live Tracking | Operator GPS broadcaster (adaptive), RTDB writes, passenger tracking map, ETA Cloud Function |
| 9–10 | Fare Engine + Seat Picker | Fare calculation service, fare API endpoint, seat picker GridView UI, fare display pre-booking |
| 11–12 | Admin Dashboard | Route/schedule CRUD in React, Recharts analytics, fleet monitor map, fare config panel, user management |
| 13 | Chatbot + Ratings + Polish | Dialogflow ES integration, post-trip feedback form, admin notification broadcast panel, Hive offline caching |
| 14 | Testing + Production Deploy | Jest unit tests, Flutter widget tests, Firebase Emulator integration tests, production deploy, demo prep |


---

## 16. Environment Variables Reference

### Backend (`functions/.env`)

```env
# Firebase Admin SDK
FIREBASE_PROJECT_ID=ridesync-prod
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@ridesync-prod.iam.gserviceaccount.com

# Google Maps
GOOGLE_MAPS_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Twilio
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+12025551234

# Dialogflow
DIALOGFLOW_PROJECT_ID=ridesync-chatbot
GOOGLE_APPLICATION_CREDENTIALS=./dialogflow-service-account.json

# App Config
NODE_ENV=production
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
BOOKING_RATE_LIMIT_MAX=10
CACHE_TTL_SECONDS=3600
```


### React Web (`web/.env`)

```env
VITE_FIREBASE_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
VITE_FIREBASE_AUTH_DOMAIN=ridesync-prod.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=ridesync-prod
VITE_FIREBASE_STORAGE_BUCKET=ridesync-prod.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789012
VITE_FIREBASE_APP_ID=1:123456789012:web:xxxxxxxxxxxxxxxx
VITE_FIREBASE_DATABASE_URL=https://ridesync-prod-default-rtdb.asia-southeast1.firebasedatabase.app
VITE_GOOGLE_MAPS_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
VITE_API_BASE_URL=https://asia-southeast1-ridesync-prod.cloudfunctions.net/api
```


### Flutter Mobile (`mobile/lib/core/constants/env.dart`)

```dart
// Values injected via --dart-define at build time or from google-services.json
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://asia-southeast1-ridesync-prod.cloudfunctions.net/api',
  );
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
}
```


### `.gitignore` (Critical)

```
# Environment files — NEVER commit these
functions/.env
web/.env
mobile/.env
**/google-services.json
**/GoogleService-Info.plist
**/*service-account*.json
**/*dialogflow-key*.json
```


---

## 17. Testing Strategy

### 17.1 Backend Unit Tests (Jest)

```javascript
// Example: fare.service.test.js
describe('FareService.calculateFare', () => {
  it('should return correct fare for AC class segment', async () => {
    const result = await calculateFare('SCH001', 'Colombo', 'Peradeniya', 'AC');
    expect(result.segmentKm).toBeCloseTo(115.3);
    expect(result.classMultiplier).toBe(1.5);
    expect(result.total).toBe(483);
  });

  it('should throw error for invalid stop order', async () => {
    await expect(
      calculateFare('SCH001', 'Kandy', 'Colombo', 'NonAC')
    ).rejects.toThrow('fromStop must come before toStop');
  });

  it('should round up total to nearest integer', async () => {
    const result = await calculateFare('SCH001', 'Colombo', 'Kegalle', 'NonAC');
    expect(Number.isInteger(result.total)).toBe(true);
  });
});
```


### 17.2 Test Coverage Targets

| Module | Unit Tests | Integration Tests | Target Coverage |
| :-- | :-- | :-- | :-- |
| fare.service | calculateFare, edge cases, rounding | Firestore fare fetch | 90% |
| booking.service | seat lock, transaction, conflict (409) | Firestore transaction | 85% |
| notification.service | FCM dispatch, Twilio call | Mock FCM/Twilio | 80% |
| auth.middleware | valid token, expired token, wrong role | Firebase Emulator | 90% |
| route.service | stop distance calculation | Firestore fetch | 80% |
| Flutter tracking | BusLocation.isStale, stream mapping | RTDB Emulator | 75% |
| Flutter operator | GPS broadcast start/stop, adaptive interval | Unit mock | 75% |

### 17.3 Testing Tools

| Tool | Purpose |
| :-- | :-- |
| Jest + sinon | Node.js unit and integration tests |
| Firebase Emulator Suite | Local Firestore, RTDB, Auth, Functions |
| Postman Collections | REST API testing, all endpoints + auth flows for 3 roles |
| flutter_test | Flutter unit and widget tests |
| BrowserStack | Cross-device testing (Android + iOS) |
| Artillery.js | Load test: 100 concurrent bookings simulation |

### 17.4 Firebase Emulator Commands

```bash
# Start all emulators (Functions, Firestore, RTDB, Auth, Hosting)
firebase emulators:start

# Run backend tests against emulator
FIRESTORE_EMULATOR_HOST=localhost:8080 \
FIREBASE_DATABASE_EMULATOR_HOST=localhost:9000 \
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
npm test

# Export emulator data for reproducible tests
firebase emulators:export ./emulator-seed

# Import seed data
firebase emulators:start --import=./emulator-seed
```


### 17.5 Postman Collection Structure

```
RideSync API
├── Auth
│   ├── POST Register (passenger)
│   ├── POST Register (operator)
│   └── POST Set Role (admin)
├── Routes
│   ├── GET All Routes
│   ├── GET Route by ID
│   ├── POST Create Route (admin token)
│   └── PUT Update Route (admin token)
├── Schedules
│   ├── GET Search Schedules
│   ├── GET Seat Map
│   ├── POST Create Schedule (admin)
│   └── PUT Update Schedule Status (operator token)
├── Fare
│   ├── GET Fare Estimate (AC)
│   ├── GET Fare Estimate (NonAC)
│   └── GET Fare Estimate (invalid stops → expect 400)
├── Bookings
│   ├── POST Book Seat (passenger token)
│   ├── POST Book Same Seat (expect 409 conflict)
│   ├── GET My Bookings (passenger token)
│   └── PUT Cancel Booking
└── Notifications
    ├── POST Broadcast to Route (admin token)
    └── POST Send to User (admin token)
```


---

*Document: RIDESYNC_ARCHITECTURE.md*
*Version: 2.0 | March 2026*
*Change from v1.0: Removed "Bus Driver" as a separate role. Merged all driver responsibilities (GPS broadcasting, trip management, seat management) into the "Bus Operator" role on Flutter Mobile App. React Web Dashboard is now exclusively for Administrators. RBAC updated to 3 roles: passenger | operator | admin.*
*Prepared by: RideSync Architecture Review*
*For: Antigravity Agentic Model — RideSync Full Implementation Reference*
*Project: IS 4110 Capstone | Group 21 | Sabaragamuwa University of Sri Lanka*

```
```

