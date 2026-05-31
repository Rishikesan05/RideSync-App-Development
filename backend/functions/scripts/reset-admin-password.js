#!/usr/bin/env node
/**
 * Reset Admin Password Script
 * Usage: node scripts/reset-admin-password.js <email> <newPassword> [--force]
 *
 * Safety: By default this script only runs against the Firebase Auth Emulator.
 *         Pass --force to run against a live project (use with caution).
 */

// 1. Safety Guard — block production runs unless --force is passed
const isEmulator = !!process.env.FIREBASE_AUTH_EMULATOR_HOST;
const isForce = process.argv.includes('--force');

if (!isEmulator && !isForce) {
  console.error(' ERROR: This script should only be run against the Firebase Auth Emulator.');
  console.error('   To run against a live project, append the --force flag.');
  process.exit(1);
}

// 2. Validate arguments — no hardcoded defaults
//    Parsed inside the function so the password value is scoped as tightly as
//    possible and can never be accidentally referenced at module level.
const args = process.argv.slice(2).filter(arg => !arg.startsWith('--'));
const email = args[0];

if (!email || !args[1]) {
  console.error('❌ ERROR: Missing required arguments.');
  console.error('   Usage: node scripts/reset-admin-password.js <email> <newPassword> [--force]');
  process.exit(1);
}

// Reuse project firebase-admin config (auto-discovers credentials)
// Note: 'path' import removed — it was unused.
const { auth } = require('../src/config/firebase.config');

async function resetPassword() {
  // Password is scoped exclusively inside this function — never at module level —
  // to prevent any accidental logging or exposure outside this call site.
  const newPassword = args[1];

  try {
    const userRecord = await auth.getUserByEmail(email);
    await auth.updateUser(userRecord.uid, { password: newPassword });

    // Log only identity info — the password value is intentionally never printed.
    console.log(`✅ Password successfully updated for: ${email} (UID: ${userRecord.uid})`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error resetting password:', error.message);
    process.exit(1);
  }
}

resetPassword();
