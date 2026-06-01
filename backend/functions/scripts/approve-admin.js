#!/usr/bin/env node
/**
 * Approve Admin Script
 *
 * Promotes an existing user from any role → 'admin'.
 * Sets both the Firestore /users/{uid}.role field AND the
 * Firebase Auth custom claim so Firestore rules take effect immediately.
 *
 * Usage:
 *   node scripts/approve-admin.js <uid> [--force]
 *
 * Safety: --force is required to run against the LIVE Firebase project.
 *
 * Example:
 *   node scripts/approve-admin.js sOm7lkXNCyQCSpvANE18LHEnB0N2 --force
 */

// ── Safety Guard ─────────────────────────────────────────────────────────────
// Block accidental production runs unless --force is explicitly passed.
const isEmulator = !!process.env.FIREBASE_AUTH_EMULATOR_HOST;
const isForce    = process.argv.includes('--force');

if (!isEmulator && !isForce) {
  console.error('❌  ERROR: Safety guard triggered.');
  console.error('   This script writes to Firebase Auth and Firestore.');
  console.error('   To run against the LIVE project, append the --force flag:');
  console.error('   node scripts/approve-admin.js <uid> --force');
  process.exit(1);
}

// ── Argument Validation ───────────────────────────────────────────────────────
const args = process.argv.slice(2).filter(arg => !arg.startsWith('--'));
const targetUid = args[0];

if (!targetUid) {
  console.error('❌  ERROR: Missing required argument <uid>.');
  console.error('   Usage: node scripts/approve-admin.js <uid> --force');
  process.exit(1);
}

// ── Firebase Admin SDK ────────────────────────────────────────────────────────
const { auth, db } = require('../src/config/firebase.config');
const { ROLES }    = require('../src/shared/constants');

async function approveAdmin() {
  try {
    // Warn loudly when running against live Firebase
    if (isForce && !isEmulator) {
      console.warn('\n⚠️  WARNING: --force flag active. Writing to LIVE Firebase.');
      console.warn(`   Target UID : ${targetUid}`);
      console.warn('   Proceeding in 3 seconds — press Ctrl+C to abort.\n');
      await new Promise(resolve => setTimeout(resolve, 3000));
    }

    // ── Step 1: Verify user exists in Firestore ───────────────────────────
    const userRef  = db.collection('users').doc(targetUid);
    const userDoc  = await userRef.get();

    if (!userDoc.exists) {
      console.error(`❌  ERROR: No Firestore document found for UID: ${targetUid}`);
      console.error('   Make sure the user has completed registration (/api/auth/register).');
      process.exit(1);
    }

    const userData = userDoc.data();
    console.log('\n👤  User found in Firestore:');
    console.log(`   Name  : ${userData.name  || '(not set)'}`);
    console.log(`   Email : ${userData.email || '(not set)'}`);
    console.log(`   Role  : ${userData.role  || '(not set)'}`);

    // ── Step 2: Verify user exists in Firebase Auth ───────────────────────
    const authUser = await auth.getUser(targetUid);
    console.log(`\n🔐  Firebase Auth record confirmed: ${authUser.email}`);

    // ── Step 3: Update Firestore role → 'admin' ───────────────────────────
    await userRef.update({
      role:       ROLES.ADMIN,
      approvedBy: 'script',          // audit trail — approved via CLI script
      approvedAt: new Date(),
      updatedAt:  new Date(),
    });
    console.log('\n✅  Firestore role updated → admin');

    // ── Step 4: Set Firebase Auth custom claim → { role: 'admin' } ────────
    // The user must sign out and sign back in (or wait for token refresh)
    // for the new claim to appear in their JWT and unlock Firestore rules.
    await auth.setCustomUserClaims(targetUid, { role: ROLES.ADMIN });
    console.log('✅  Firebase Auth custom claim set → { role: "admin" }');

    // ── Done ──────────────────────────────────────────────────────────────
    console.log('\n🎉  Done! Admin approved successfully.');
    console.log(`   UID   : ${targetUid}`);
    console.log(`   Email : ${authUser.email}`);
    console.log('\n⚠️  IMPORTANT: The user must sign out and sign back in for');
    console.log('   the new admin role to take effect in their Firebase JWT.\n');

    process.exit(0);
  } catch (error) {
    console.error('\n❌  Error:', error.message);
    process.exit(1);
  }
}

approveAdmin();
