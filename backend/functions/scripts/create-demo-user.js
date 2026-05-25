#!/usr/bin/env node
/**
 * Create Demo User Script
 * Usage: node scripts/create-demo-user.js [email] [password]
 * Defaults: email=demo.admin@ridesync.lk, password=DemoPass123!
 *
 * Note: Requires Firebase Admin credentials (service account) or running
 * against the Firebase Auth emulator.
 */
const { auth, db } = require('../src/config/firebase.config');

const email = process.argv[2] || 'demo.admin@ridesync.lk';
const password = process.argv[3] || 'DemoPass123!';

async function createDemo() {
  try {
    // Create Auth user
    const userRecord = await auth.createUser({
      email,
      emailVerified: true,
      password,
      disabled: false,
    });

    // Set admin role claim so this account can access admin portal
    await auth.setCustomUserClaims(userRecord.uid, { role: 'admin' });

    // Create a Firestore profile document (mirror of registerUser)
    const now = new Date();
    const userData = {
      uid: userRecord.uid,
      name: 'Demo Admin',
      email,
      phone: null,
      role: 'admin',
      busId: null,
      fcmToken: null,
      createdAt: now,
      updatedAt: now,
    };

    await db.collection('users').doc(userRecord.uid).set(userData);

    console.log(`✅ Demo user created: ${email}`);
    console.log(`👉 Password: ${password}`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed to create demo user:', err.message || err);
    process.exit(1);
  }
}

createDemo();
