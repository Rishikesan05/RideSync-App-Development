#!/usr/bin/env node
/**
 * Create Demo Admin User Script
 * Usage: node scripts/create-demo-user.js <email> <password> [--force]
 *
 * Safety: By default this script only runs against the Firebase Auth Emulator.
 *         Pass --force to run against a live project (use with caution).
 */

// 1. Safety Guard — block production runs unless --force is passed
const isEmulator = !!process.env.FIREBASE_AUTH_EMULATOR_HOST;
const isForce = process.argv.includes('--force');

if (!isEmulator && !isForce) {
  console.error(' ERROR: Guard triggered. This script is intended for development environments.');
  console.error('   To create a verified admin user in production, append the --force flag.');
  process.exit(1);
}

// 2. Validate arguments — no hardcoded defaults
const args = process.argv.slice(2).filter(arg => !arg.startsWith('--'));
const email = args[0];
const password = args[1];

if (!email || !password) {
  console.error(' ERROR: Missing required arguments.');
  console.error('   Usage: node scripts/create-demo-user.js <email> <password> [--force]');
  process.exit(1);
}

// Reuse project firebase-admin config (auto-discovers credentials)
const { auth, db } = require('../src/config/firebase.config');

// 3. Code Consistency — import ROLES from the centralized constants file
//    rather than using raw 'admin' strings scattered across scripts.
const { ROLES } = require('../src/shared/constants');

async function createDemoAdmin() {
  try {
    console.log(`Creating admin account for: ${email}...`);

    // Explicit point-of-use guard: warn loudly right before the high-impact
    // Firebase calls when --force is active against a live project, so the
    // risk is visible even if the top-of-file guard is missed during review.
    if (isForce && !isEmulator) {
      console.warn('\n⚠️  WARNING: --force flag active. Writing a verified admin user to LIVE Firebase.');
      console.warn(`   Project: ${process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || 'unknown'}`);
      console.warn('   Proceeding in 3 seconds — press Ctrl+C to abort.\n');
      await new Promise(resolve => setTimeout(resolve, 3000));
    }

    const userRecord = await auth.createUser({
      email,
      emailVerified: true,
      password,
      disabled: false,
    });

    // Use ROLES.ADMIN constant for Custom Claims
    await auth.setCustomUserClaims(userRecord.uid, { role: ROLES.ADMIN });

    const now = new Date();
    const userData = {
      uid: userRecord.uid,
      name: 'Demo Admin',
      email,
      phone: null,
      role: ROLES.ADMIN, // Use ROLES.ADMIN constant for Firestore profile
      busId: null,
      fcmToken: null,
      createdAt: now,
      updatedAt: now,
    };

    await db.collection('users').doc(userRecord.uid).set(userData);

    // 4. Security: do NOT echo the password back to stdout
    console.log(` Demo admin user created successfully!`);
    console.log(`   Email: ${email}`);
    console.log(`   UID:   ${userRecord.uid}`);
    process.exit(0);
  } catch (error) {
    console.error(' Error creating demo user:', error.message);
    process.exit(1);
  }
}

createDemoAdmin();
