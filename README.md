# 🚀 RideSync: Integrated Smart Bus Management & Telemetry Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**RideSync** is an end-to-end, multi-platform transit operating ecosystem designed to revolutionize public transportation. By integrating continuous real-time telemetry, automated dispatching, multi-stop fare computation, and role-based access control, RideSync delivers a seamless experience for passengers, bus operators, and transit administrators.

---

## 🏗️ Architecture Overview

RideSync is structured as a scalable **Monorepo**, separating concerns across mobile clients, administrative web portals, and serverless backend cloud functions:

```text
RideSync/
├── apps/
│   ├── mobile/         # Flutter application for Passengers and Bus Operators (iOS & Android)
│   └── web/            # React 19 + MUI Administrative Portal for fleet & transit management
├── backend/
│   └── functions/      # Firebase Cloud Functions (Node.js + Express API & Gemini AI services)
├── packages/
│   └── shared/         # Shared data models, validation schemas, and constants
├── firestore.rules     # Granular Role-Based Access Control (RBAC) security rules
└── database.rules.json # Realtime Database rules for ultra-low latency GPS streaming
```

---

## ✨ Key Capabilities

### 📱 Mobile Application (Passenger & Operator)
* **Live GPS Tracking**: Real-time bus movement with stop-by-stop polylines and smooth marker animations.
* **Dynamic Seat Booking**: Interactive seat layout matrix with real-time seat locking and confirmation.
* **Stop-to-Stop Fare Engine**: Automated stage-based fare computation per route stop.
* **Operator In-Transit Hub**: Turn-by-turn navigation overlay, continuous GPS broadcasting, walk-in counter, and delay reporting.
* **AI Transit Assistant**: Integrated conversational assistant powered by Google Gemini SDK for schedule queries.

### 💻 Web Dashboard (Admin & Fleet Management)
* **Live Fleet Telemetry**: Simultaneous multi-bus GPS map view with real-time speed, heading, and delay monitoring.
* **Route & Schedule Dispatcher**: Visual route geometry planning, waypoint sequencing, and automated schedule generation.
* **User & Operator Governance**: Role management with approval workflows for new bus operators and administrators.
* **Seat & Revenue Analytics**: Seat occupancy rates, route profitability, and operational performance metrics.

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Mobile Client** | Flutter, Dart, Provider, Google Maps Flutter, Geolocator, Google Generative AI |
| **Web Portal** | React 19, Vite, Material UI (MUI), TanStack React Query, Recharts, Framer Motion |
| **Backend & APIs** | Node.js (Express), Firebase Cloud Functions, Google Generative AI SDK, Joi |
| **Cloud & Database** | Cloud Firestore, Firebase Realtime Database (RTDB), Firebase Auth, Cloud Storage |

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)
* [Node.js](https://nodejs.org/) (v18 or v20)
* [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)

---

### 1. Clone & Setup Repository

```bash
git clone https://github.com/Rishikesan05/RideSync-App-Development.git
cd RideSync-App-Development
```

### 2. Run the Mobile App (`apps/mobile`)

```bash
cd apps/mobile
flutter pub get
flutter run
```

### 3. Run the Admin Web Portal (`apps/web`)

```bash
cd apps/web
npm install
npm run dev
```
*The administrative portal will launch at `http://localhost:5173`.*

### 4. Run Backend Functions Locally (Optional)

```bash
cd backend/functions
npm install
npm run serve
```

---

## 🔐 Environment Configuration

Environment secrets and API credentials are kept out of source control:

* **Mobile (`apps/mobile`)**:
  * Place `google-services.json` in `apps/mobile/android/app/`.
  * Create `.env` in `apps/mobile/` with `GOOGLE_MAPS_API_KEY` and `GEMINI_API_KEY`.
* **Web (`apps/web`)**:
  * Create `.env` in `apps/web/` containing your `VITE_FIREBASE_*` credentials and `VITE_GOOGLE_MAPS_API_KEY`.

---

## 🤝 Branching & Commit Guidelines

To ensure academic and professional software development standards:

* **Branch format**: `feature/<feature-name>`, `fix/<bug-name>`, `chore/<task-name>`
* **Commit convention**: `[RIDESYNC] YYYY-MM-DD | <Type>: <Description>`

*Example:* `[RIDESYNC] 2026-08-18 | Feat: Implement multi-bus live fleet telemetry`

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Developed with ❤️ by the **RideSync Team**.
