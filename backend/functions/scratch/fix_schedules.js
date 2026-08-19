const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixSchedules() {
  console.log('Fetching schedules...');
  const schedulesSnap = await db.collection('schedules').get();
  
  for (const doc of schedulesSnap.docs) {
    const data = doc.data();
    const busId = data.busId;
    
    if (busId) {
      console.log(`Checking bus ${busId} for schedule ${doc.id}...`);
      const busSnap = await db.collection('buses').doc(busId).get();
      if (busSnap.exists()) {
        const busData = busSnap.data();
        const capacity = busData.capacity || 54;
        const plateNumber = busData.plateNumber || 'N/A';
        
        console.log(`Updating schedule ${doc.id} with capacity ${capacity} and plate ${plateNumber}...`);
        await db.collection('schedules').doc(doc.id).update({
          capacity: capacity,
          plateNumber: plateNumber,
          routeName: data.routeName || 'Intercity Express'
        });
      }
    }
  }
  console.log('Done!');
}

fixSchedules().catch(console.error);
