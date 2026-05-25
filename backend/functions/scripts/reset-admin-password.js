#!/usr/bin/env node
/**
 * Reset Admin Password Script
 * Usage: node scripts/reset-admin-password.js [email] [newPassword]
 * Defaults: email=admin@ridesync.lk, newPassword=TestPass123!
 */
const path = require('path');

// Ensure we can require the project's admin config
const { auth } = require('../src/config/firebase.config');

const email = process.argv[2] || 'admin@ridesync.lk';
const newPassword = process.argv[3] || 'TestPass123!';

async function reset() {
  try {
    const userRecord = await auth.getUserByEmail(email);
    await auth.updateUser(userRecord.uid, { password: newPassword });
    console.log(`✅ Password for ${email} updated to: ${newPassword}`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed to reset password:', err.message || err);
    process.exit(1);
  }
}

reset();
