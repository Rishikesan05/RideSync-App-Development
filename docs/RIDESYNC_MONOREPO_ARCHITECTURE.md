# RideSync — Monorepo Software Architecture
> Capstone Project | Group 21 | Sabaragamuwa University of Sri Lanka
> Architecture: Firebase Monorepo (Flutter + React + Node.js Cloud Functions)
> Version: 3.0 | May 2026

---

## 1. Project Overview

RideSync is an intelligent public bus transport platform designed to modernize the Sri Lankan transport system. This version focuses on a **monorepo architecture** using Firebase as the backend, with a specific focus on **reservations** and **real-time tracking** without external payment or SMS integrations.

### Target Users
| Role | Platform | Primary Responsibility |
|---|---|---|
| **Passenger** | Flutter Mobile App | Search routes, reserve seats, live track buses, feedback. |
| **Bus Operator** | Flutter Mobile App | Broadcast GPS, manage active trips, update seat availability. |
| **Administrator**| React Web Dashboard | Manage fleet, schedules, routes, and view analytics. |

### Core Constraints
*   **No Payment System**: The app handles seat reservations only. Fares are collected manually or outside the platform.
*   **No SMS Notifications**: Communication is strictly via Firebase Cloud Messaging (FCM) push notifications.
*   **Firebase Blaze Plan**: Utilized within the free credit limits to enable Cloud Functions and high-performance RTDB.

---

## 2. Monorepo Folder Structure

```text
ridesync/                                          ← ROOT
│
├── .github/workflows/                             ← CI/CD Pipelines
│   ├── deploy-functions.yml                       ← Backend deployment
│   ├── deploy-web.yml                             ← React web deployment
│   └── flutter-test.yml                           ← Flutter CI
│
├── mobile/                                        ← Flutter Mobile App
│   ├── lib/
│   │   ├── core/                                  ← Themes, Utils, Errors
│   │   ├── data/                                  ← Models, Repositories, Services
│   │   ├── features/                              ← Auth, Passenger, Driver (Operator)
│   │   └── shared/                                ← Common Widgets
│   └── pubspec.yaml
│
├── web/                                            ← React Admin Dashboard (Vite)
│   ├── src/
│   │   ├── api/                                   ← Axios Instance
│   │   ├── features/                              ← Domain-specific panels (Routes, Fleet, etc.)
│   │   ├── components/                            ← UI Kit (MUI/Tailwind)
│   │   └── App.jsx
│   └── package.json
│
├── functions/                                      ← Node.js Backend (Cloud Functions)
│   ├── src/
│   │   ├── modules/                               ← Domain-driven modules (Booking, Route, etc.)
│   │   ├── middleware/                            ← Auth, RBAC, Validation
│   │   └── index.js                               ← Entry point
│   └── package.json
│
├── shared/                                         ← Shared Logic
│   ├── constants.js                                ← Roles, Statuses, Classes
│   └── fareFormula.js                              ← Shared math logic
│
├── firebase.json                                   ← Root Firebase Configuration
├── firestore.rules                                 ← Security Rules
└── database.rules.json                             ← RTDB Security Rules
```

---

## 3. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Mobile** | Flutter (Riverpod) | Cross-platform passenger & operator apps. |
| **Web** | React (Vite + MUI) | Administrator dashboard. |
| **Backend** | Node.js (Express) | API hosted on Firebase Cloud Functions. |
| **Database** | Cloud Firestore | Structured metadata (users, routes, bookings). |
| **Realtime** | Firebase RTDB | High-frequency GPS streaming and trip status. |
| **Auth** | Firebase Auth | Role-based authentication (Custom Claims). |
| **Push** | Firebase FCM | App notifications (No SMS). |
| **Maps** | Google Maps SDK | Live tracking and route visualization. |

---

## 4. Database Design (NoSQL)

### 4.1 Firestore Collections
*   **/users/{uid}**: Profile info + `role` (passenger, operator, admin).
*   **/routes/{routeId}**: Route definitions with an array of stops and distances.
*   **/buses/{busId}**: Bus details (plate number, class, capacity).
*   **/schedules/{scheduleId}**: Active trip instances, seat map, and current operator.
*   **/bookings/{bookingId}**: Reservation records (no payment info).
*   **/fares/{fareId}**: Fare rules per route/class.

### 4.2 Realtime Database (RTDB)
*   **/busLocations/{busId}**: `{ lat, lng, speed, heading, timestamp }`
*   **/tripStatus/{scheduleId}**: `{ status, eta, delayMinutes, lastUpdated }`

---

## 5. Key Workflows

### 5.1 Reservation Flow (No Payment)
1.  **Search**: Passenger searches for schedules by origin/destination.
2.  **Selection**: Passenger selects a schedule and views the visual seat map.
3.  **Booking**: Passenger selects a seat and clicks "Reserve".
4.  **Transaction**: Cloud Function performs a Firestore transaction to lock the seat in the `schedule` document and create a `booking` record.
5.  **Notification**: FCM push notification sent to the passenger confirming the reservation.

### 5.2 Real-time Tracking
1.  **Broadcast**: Operator app sends GPS coordinates to RTDB every 3-5 seconds.
2.  **Listen**: Passenger app listens to the specific `busId` node in RTDB.
3.  **ETA**: RTDB trigger fires a Cloud Function to update ETA based on current speed and remaining distance.

---

## 6. Security & Infrastructure

### 6.1 RBAC (Role-Based Access Control)
*   Roles are stored as **Custom Claims** in Firebase Auth.
*   `operator` can only write to their assigned bus location in RTDB.
*   `admin` has full CRUD access to routes and fleet via the web dashboard.

### 6.2 Deployment
*   **CI/CD**: GitHub Actions automatically deploys web to Firebase Hosting and backend to Cloud Functions on push to `main`.
*   **Emulators**: Local development uses the Firebase Emulator Suite to save on usage quotas.

---

## 7. Communication Strategy
*   **SMS Removal**: All Twilio dependencies are removed.
*   **FCM Only**: All alerts (booking confirmation, trip delays, bus arrival) are handled via FCM.
*   **In-App Inbox**: A sub-collection in Firestore tracks notification history for users to view later.

---
*Prepared by RideSync Architecture Review*
*Capstone Group 21*
