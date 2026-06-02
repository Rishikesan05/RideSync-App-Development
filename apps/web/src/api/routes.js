/**
 * routes.js — Firestore SDK write layer for the `routes` collection.
 *
 * READ path  → use useRoutesFirestore() hook (real-time onSnapshot).
 * WRITE path → use the mutation hooks below (create / update / toggle / delete).
 *
 * Firestore schema (confirmed from backend route.schema.js + seed-routes.js):
 *   routeNumber      string   e.g. "1", "99"
 *   name             string   e.g. "Colombo - Kandy Express"
 *   startPoint       string   origin city / stop name
 *   endPoint         string   destination city / stop name
 *   stops            array    [{ name: string, distFromStartKm: number }]
 *   totalDistanceKm  number
 *   isActive         boolean  true on create
 *   createdAt        Timestamp
 *   updatedAt        Timestamp
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

const COLLECTION = 'routes';

// ── Write functions (create / update / toggle / delete) ───────────────────

/**
 * Create a new route document.
 * Adds createdAt / updatedAt / isActive automatically.
 */
export const createRoute = async (routeData) => {
  const docRef = await addDoc(collection(db, COLLECTION), {
    ...routeData,
    isActive:  true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  return { id: docRef.id, ...routeData, isActive: true };
};

/**
 * Update an existing route document.
 * Always refreshes updatedAt.
 */
export const updateRoute = async ({ id, data }) => {
  const ref = doc(db, COLLECTION, id);
  await updateDoc(ref, {
    ...data,
    updatedAt: serverTimestamp(),
  });
  return { id, ...data };
};

/**
 * Deactivate a route — sets isActive to false.
 * Kept for backwards-compat with RoutesView's existing handleToggleActive.
 */
export const deactivateRoute = async (id) => {
  const ref = doc(db, COLLECTION, id);
  await updateDoc(ref, { isActive: false, updatedAt: serverTimestamp() });
  return { id };
};

/**
 * Toggle isActive on a route.
 * Pass the current isActive boolean so we can flip it.
 */
export const toggleRouteActive = async ({ id, currentIsActive }) => {
  const ref = doc(db, COLLECTION, id);
  await updateDoc(ref, {
    isActive:  !currentIsActive,
    updatedAt: serverTimestamp(),
  });
  return { id, isActive: !currentIsActive };
};

/**
 * Permanently delete a route document.
 */
export const deleteRoute = async (id) => {
  await deleteDoc(doc(db, COLLECTION, id));
  return { id };
};

// ── React Query mutation hooks ──────────────────────────────────────────────
// READ: use useRoutesFirestore() from features/routes/useRoutesFirestore.js
/** Create a route and invalidate cache. */
export const useCreateRoute = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: createRoute,
    onSuccess:  () => qc.invalidateQueries({ queryKey: ['routes'] }),
  });
};

/** Update a route and invalidate cache. */
export const useUpdateRoute = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: updateRoute,
    onSuccess:  () => qc.invalidateQueries({ queryKey: ['routes'] }),
  });
};

/** Deactivate a route (legacy — sets isActive: false). */
export const useDeactivateRoute = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: deactivateRoute,
    onSuccess:  () => qc.invalidateQueries({ queryKey: ['routes'] }),
  });
};

/** Toggle active/inactive state of a route. */
export const useToggleRouteActive = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: toggleRouteActive,
    onSuccess:  () => qc.invalidateQueries({ queryKey: ['routes'] }),
  });
};

/** Permanently delete a route. */
export const useDeleteRoute = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: deleteRoute,
    onSuccess:  () => qc.invalidateQueries({ queryKey: ['routes'] }),
  });
};
