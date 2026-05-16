const admin = require('firebase-admin');

const serviceAccount = require('../dialogflow-service-account.json');

// Initialize the Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'ridesync-lk'
  });
}

const auth = admin.auth();
const db = admin.firestore();

async function fixAdminRole(email) {
  try {
    const user = await auth.getUserByEmail(email);
    console.log(`Found user: ${user.uid} (${user.email})`);
    
    // Set custom claims
    await auth.setCustomUserClaims(user.uid, { role: 'admin' });
    console.log(`Successfully set admin role for ${email}`);
    
    // Update Firestore document if it exists
    const userRef = db.collection('users').doc(user.uid);
    const doc = await userRef.get();
    if (doc.exists) {
      await userRef.update({ role: 'admin' });
      console.log(`Updated Firestore document for ${email}`);
    } else {
      console.log(`Firestore document for ${user.uid} not found, but claims are set.`);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
  }
}

// Target email
const targetEmail = 'jinosuniversity@gmail.com';
fixAdminRole(targetEmail);
