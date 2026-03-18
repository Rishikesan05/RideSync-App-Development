const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('./serviceAccountKey.json');

const fares = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../firestore/route_fares.seed.json'), 'utf8')
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function run() {
  for (const item of fares) {
    const { docId, ...data } = item;
    await db.collection('route_fares').doc(docId).set(data, { merge: true });
    console.log(`Uploaded: ${docId}`);
  }

  console.log('All fares uploaded.');
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
