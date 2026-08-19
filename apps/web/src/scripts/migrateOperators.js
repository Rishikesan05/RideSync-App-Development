import { collection, getDocs, query, where, doc, setDoc } from 'firebase/firestore';
import { db } from '../api/firebase';

export const migrateOperatorsAndAdmins = async () => {
  try {
    console.log('Starting migration of operators and admins...');
    const usersRef = collection(db, 'users');
    
    // 1. Migrate Operators into the canonical 'operators' collection.
    //    Each document stores an explicit 'operatorId' field (= document ID)
    //    so the schedule form can validate via: where('operatorId', '==', input)
    const operatorQuery = query(usersRef, where('role', '==', 'operator'));
    const opSnapshot = await getDocs(operatorQuery);
    
    for (const userDoc of opSnapshot.docs) {
      const userData = userDoc.data();
      const operatorId = userDoc.id;
      await setDoc(doc(db, 'operators', operatorId), {
        operatorId,                                         // explicit field for Firestore queries
        fullName: userData.fullName || '',
        email: userData.email || '',
        role: 'operator',
        createdAt: userData.createdAt || new Date().toISOString(),
      });
      console.log(`Migrated operator: ${operatorId}`);
    }

    // 2. Migrate Admins
    const adminQuery = query(usersRef, where('role', '==', 'admin'));
    const adminSnapshot = await getDocs(adminQuery);
    
    for (const userDoc of adminSnapshot.docs) {
      const userData = userDoc.data();
      const aId = userDoc.id;
      await setDoc(doc(db, 'admin', aId), {
        fullName: userData.fullName || '',
        email: userData.email || '',
        role: 'admin',
        createdAt: userData.createdAt || new Date().toISOString(),
      });
      console.log(`Migrated admin: ${aId}`);
    }

    console.log('Migration completed successfully!');
  } catch (error) {
    console.error('Error during migration:', error);
  }
};
