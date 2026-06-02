/**
 * routes.js — Firestore SDK layer for the `routes` collection.
 *
 * Previously called the backend REST API via axios.
 * Now reads/writes Firestore directly — no backend needed.
 *
 * Exported names are kept identical so RoutesView.jsx needs no changes.
 * New exports added: toggleRouteActive, deleteRoute,
 *                    useToggleRouteActive, useDeleteRoute.
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

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  collection,
  getDocs,
  addDoc,
  doc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  query,
  orderBy,
} from 'firebase/firestore';
import { db } from './firebase';

const COLLECTION = 'routes';

// ── Pure async functions ────────────────────────────────────────────────────

/**
 * Fetch all routes ordered by routeNumber ascending.
 * Returns an array of plain objects with `id` injected.
 */
export const fetchRoutes = async () => {
  const q = query(collection(db, COLLECTION), orderBy('routeNumber', 'asc'));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
};

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

// ── React Query hooks ───────────────────────────────────────────────────────

/** Fetch + cache all routes. */
export const useRoutesList = () =>
  useQuery({
    queryKey: ['routes'],
    queryFn:  fetchRoutes,
    staleTime: 30_000, // 30 s — Firestore is the source of truth
  });

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
