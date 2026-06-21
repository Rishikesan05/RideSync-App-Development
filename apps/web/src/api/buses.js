/**
 * buses.js — Firestore SDK write layer for the `buses` collection.
 *
 * READ path  → use useBusesFirestore() hook (real-time onSnapshot).
 * WRITE path → use the mutation hooks below (create / update / deactivate / delete).
 *
 * Firestore schema (buses/{busId}):
 *   plateNumber   string   e.g. "NA-1234"
 *   class         string   "AC" | "NonAC"
 *   capacity      number   35 | 54
 *   model         string   optional — e.g. "Ashok Leyland Viking"
 *   year          string   optional — e.g. "2019"
 *   operatorId    string   optional — UID of assigned operator
 *   isActive      boolean  true on create
 *   createdAt     Timestamp
 *   updatedAt     Timestamp
 */

import { useMutation, useQueryClient } from '@tanstack/react-query';
import {
  collection,
  addDoc,
  doc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from './firebase';

const COLLECTION = 'buses';

// ── Write functions ────────────────────────────────────────────────────────

/**
 * Create a new bus document in Firestore.
 * Automatically sets isActive: true, createdAt, updatedAt.
 */
export const createBus = async (busData) => {
  const docRef = await addDoc(collection(db, COLLECTION), {
    ...busData,
    isActive: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return { id: docRef.id, ...busData, isActive: true };
};

/**
 * Update an existing bus document.
 * Always refreshes updatedAt.
 */
export const updateBus = async ({ id, data }) => {
  const ref = doc(db, COLLECTION, id);
  await updateDoc(ref, {
    ...data,
    updatedAt: serverTimestamp(),
  });
  return { id, ...data };
};

/**
 * Deactivate a bus — sets isActive to false (soft delete).
 */
export const deactivateBus = async (id) => {
  const ref = doc(db, COLLECTION, id);
  await updateDoc(ref, { isActive: false, updatedAt: serverTimestamp() });
  return { id };
};

/**
 * Activate a bus — sets isActive to true.
 */
export const activateBus = async (id) => {
  const ref = doc(db, COLLECTION, id);
  await updateDoc(ref, { isActive: true, updatedAt: serverTimestamp() });
  return { id };
};

/**
 * Permanently delete a bus document from Firestore.
 */
export const deleteBus = async (id) => {
  await deleteDoc(doc(db, COLLECTION, id));
  return { id };
};

// ── React Query mutation hooks ──────────────────────────────────────────────

/** Create a bus and invalidate cache. */
export const useCreateBus = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: createBus,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['buses'] }),
  });
};

/** Update a bus and invalidate cache. */
export const useUpdateBus = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: updateBus,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['buses'] }),
  });
};

/** Deactivate a bus (soft delete — sets isActive: false). */
export const useDeactivateBus = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: deactivateBus,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['buses'] }),
  });
};

/** Activate a bus (sets isActive: true). */
export const useActivateBus = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: activateBus,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['buses'] }),
  });
};

/** Permanently delete a bus from Firestore. */
export const useDeleteBus = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: deleteBus,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['buses'] }),
  });
};
