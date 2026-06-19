import { doc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../api/firebase';

/**
 * usersApi — Firestore-native CRUD for all user categories.
 *
 * Collection mapping:
 *   passenger / admin / pending  →  'users'
 *   operator                     →  'operators'
 */

const collectionForCategory = (category) =>
  category === 'operators' || category === 'operator' ? 'operators' : 'users';

export const usersApi = {
  /**
   * Update a user document's editable fields (name, email, phone…).
   */
  updateUser: async (id, category, fields) => {
    const ref = doc(db, collectionForCategory(category), id);
    await updateDoc(ref, { ...fields, updatedAt: serverTimestamp() });
  },

  /**
   * Delete a user document from its Firestore collection.
   */
  deleteUser: async (id, category) => {
    const ref = doc(db, collectionForCategory(category), id);
    await deleteDoc(ref);
  },

  /**
   * Change a pending user's role in the 'users' collection.
   * Used by the admin to approve / verify a pending account.
   *
   * @param {string} id      - Firestore document ID (in 'users' collection)
   * @param {string} newRole - 'admin' | 'operator' | 'passenger'
   */
  changeRole: async (id, newRole) => {
    const ref = doc(db, 'users', id);
    await updateDoc(ref, {
      role:        newRole,
      isApproved:  true,
      status:      'approved',
      updatedAt:   serverTimestamp(),
    });

    // Also approve in operators collection if applicable
    if (newRole === 'operator') {
      try {
        const opRef = doc(db, 'operators', id);
        await updateDoc(opRef, {
          isApproved: true,
          status: 'approved',
          updatedAt: serverTimestamp(),
        });
      } catch (e) {
        console.warn('Could not update operator doc (might not exist yet):', e);
      }
    }
  },

  /**
   * Approve an operator (set isApproved = true in 'operators' collection).
   */
  approveOperator: async (id) => {
    const ref = doc(db, 'operators', id);
    await updateDoc(ref, { isApproved: true, updatedAt: serverTimestamp() });
  },

  /**
   * Reject / suspend an operator (set isApproved = false).
   */
  rejectOperator: async (id) => {
    const ref = doc(db, 'operators', id);
    await updateDoc(ref, { isApproved: false, updatedAt: serverTimestamp() });
  },
};
