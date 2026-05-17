# 🚀 RideSync: Integrated Bus Management Ecosystem

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

RideSync is a state-of-the-art, multi-platform solution designed to revolutionize public transportation. By integrating real-time tracking, automated scheduling, and seamless passenger interaction, RideSync provides a unified experience for passengers, operators, and administrators.

---

## 🏗️ Architecture Overview

RideSync is structured as a **Monorepo**, ensuring consistency across all platforms and simplifying the sharing of business logic and models.

```text
RideSync/
├── apps/
│   ├── mobile/         # Flutter application for Passengers and Drivers
│   └── web/            # React-based Admin Dashboard for fleet management
├── backend/
│   └── functions/      # Firebase Cloud Functions (Typescript)
├── packages/
│   └── shared/         # Shared data models and business logic
├── config/             # Centralized project configurations
└── docs/               # Detailed architecture and design specifications
```

---

## ✨ Key Features

### 📱 Mobile Application (Passenger & Driver)
- **Real-time Tracking**: Live GPS monitoring of buses on interactive maps.
- **Dynamic Booking**: Instant seat reservation and digital ticketing.
- **Smart Notifications**: Push alerts for delays, arrivals, and schedule changes.
- **Driver Portal**: Route management, occupancy tracking, and navigation.

### 💻 Web Dashboard (Admin)
- **Fleet Management**: Real-time overview of all active vehicles.
- **Route Optimization**: Tools for planning and adjusting bus routes based on demand.
- **Analytics & Reporting**: Data-driven insights into passenger volume and service efficiency.
- **User Management**: Unified control over passenger and operator accounts.

---

## 🛠️ Tech Stack

- **Frontend (Mobile)**: Flutter (Dart) with Provider/Riverpod for state management.
- **Frontend (Web)**: React.js, Vite, TailwindCSS.
- **Backend**: Firebase (Firestore, Authentication, Cloud Functions).
- **Communication**: Real-time synchronization via Firebase SDK.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable)
- [Node.js](https://nodejs.org/) (v18+)
- [Firebase CLI](https://firebase.google.com/docs/cli)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Rishikesan05/RideSync-App-Development.git
   cd RideSync-App-Development
   ```

2. **Setup Mobile App (Android):**
   ```bash
   cd apps/mobile
   flutter pub get
   ```

3. **Setup Web Dashboard:**
   ```bash
   cd apps/web
   npm install
   ```

---

## 🔐 Team Setup & Security

Since API keys and Firebase secrets are **not** stored in Git, every group member must follow these steps to set up their local environment:

### 📱 For Android Development (`apps/mobile`)
1.  **Firebase Config**: Place your `google-services.json` inside `apps/mobile/android/app/`.
2.  **Environment**: Copy `.env.example` to `.env` and fill in your `GOOGLE_MAPS_API_KEY`.

### 💻 For Web Development (`apps/web`)
1.  **Environment**: Copy `.env.example` to `.env` and fill in all `VITE_FIREBASE_*` and `VITE_GOOGLE_MAPS_API_KEY` values.

---

## 🤝 Contribution Guidelines

We follow a strict, professional branching and commit convention to ensure code quality:

- **Branches**: `feature/`, `fix/`, `refactor/`, `docs/`.
- **Commits**: `[RIDESYNC] YYYY-MM-DD | <Type>: <Description>`

*Example: `[RIDESYNC] 2026-05-16 | Feat: Implement real-time tracking`*

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Developed with ❤️ by the RideSync Team.
