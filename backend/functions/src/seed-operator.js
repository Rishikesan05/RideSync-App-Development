/**
 * Seed Script: Create Sample Operator
 * Run with: node src/seed-operator.js
 */
const { db } = require('./config/firebase.config');

const operatorData = {
  name: "Kamal Perera",
  role: "operator",
  email: "kamal.operator@ridesync.lk",
  phone: "+94771234567",
  isApproved: true,
  createdAt: new Date(),
  updatedAt: new Date()
};

async function seed() {
  const operatorId = "OP_TEST_KAMAL_001";
  console.log(`🚀 Seeding operator ${operatorId}...`);
  
  try {
    await db.collection('users').doc(operatorId).set(operatorData);
    console.log("✅ Success! Operator created.");
    console.log(`👉 Use ID: ${operatorId} in the schedule form.`);
    process.exit(0);
  } catch (err) {
    console.error("❌ Error seeding operator:", err);
    process.exit(1);
  }
}

seed();
