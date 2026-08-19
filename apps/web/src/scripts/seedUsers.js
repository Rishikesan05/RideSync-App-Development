import { doc, setDoc } from 'firebase/firestore';
import { db } from '../api/firebase';

export const seedOperatorAndAdmin = async () => {
  try {
    // Create an operator document in the canonical 'operators' collection.
    // The 'operatorId' field must match the document ID so the schedule form
    // can validate via: where('operatorId', '==', typedValue)
    const operatorId = 'OP-12345';
    await setDoc(doc(db, 'operators', operatorId), {
      operatorId,                           // explicit field for Firestore queries
      fullName: 'John Operator',
      role: 'operator',
      email: 'operator@ridesync.com'
    });
    console.log(`Created operator with ID: ${operatorId}`);

    // Create an admin document where document ID is aId
    const aId = 'ADM-98765';
    await setDoc(doc(db, 'admin', aId), {
      fullName: 'Jane Admin',
      role: 'admin',
      email: 'admin@ridesync.com'
    });
    console.log(`Created admin with ID: ${aId}`);

  } catch (error) {
    console.error('Error seeding users:', error);
  }
};

