import { doc, updateDoc, deleteDoc, collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../api/firebase';

/**
 * usersApi — Firestore-native CRUD for all user categories.
 *
 * Each category maps to a Firestore collection:
 *   passenger / admin  →  'users'
 *   operator           →  'operators'
 */

const collectionForCategory = (category) =>
  category === 'operator' ? 'operators' : 'users';

export const usersApi = {
  /**
   * Update a user document's editable fields.
   * @param {string} id         - Firestore document ID
   * @param {string} category   - 'passenger' | 'operator' | 'admin'
   * @param {object} fields     - Fields to update (name, email, phone, etc.)
   */
  updateUser: async (id, category, fields) => {
    const colName = collectionForCategory(category);
    const ref = doc(db, colName, id);
    await updateDoc(ref, { ...fields, updatedAt: serverTimestamp() });
  },

  /**
   * Delete a user document from its collection.
   * @param {string} id         - Firestore document ID
   * @param {string} category   - 'passenger' | 'operator' | 'admin'
   */
  deleteUser: async (id, category) => {
    const colName = collectionForCategory(category);
    const ref = doc(db, colName, id);
    await deleteDoc(ref);
  },

  /**
   * Approve an operator (set isApproved = true in 'operators' collection).
   * @param {string} id - Firestore document ID in 'operators'
   */
  approveOperator: async (id) => {
    const ref = doc(db, 'operators', id);
    await updateDoc(ref, { isApproved: true, updatedAt: serverTimestamp() });
  },

  /**
   * Reject / suspend an operator (set isApproved = false).
   * @param {string} id - Firestore document ID in 'operators'
   */
  rejectOperator: async (id) => {
    const ref = doc(db, 'operators', id);
    await updateDoc(ref, { isApproved: false, updatedAt: serverTimestamp() });
  },
};
