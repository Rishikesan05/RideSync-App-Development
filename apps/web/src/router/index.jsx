import React from 'react';
import { Routes, Route } from 'react-router-dom';
import { AdminLayout } from '../components/Layout/AdminLayout';
import { ProtectedRoute } from '../components/Layout/ProtectedRoute';
import { Login } from '../features/auth/Login';
import { Dashboard } from '../features/dashboard/Dashboard';
import { RoutesView } from '../features/routes/RoutesView';
import { SchedulesView } from '../features/schedules/SchedulesView';
import { FleetView } from '../features/fleet/FleetView';
import { UsersView } from '../features/users/UsersView';
import { AnalyticsView } from '../features/analytics/AnalyticsView';
import { NotificationsView } from '../features/notifications/NotificationsView';
import { SettingsView } from '../features/settings/SettingsView';
import SeatManagementView from '../features/seats/SeatManagementView';

export const AppRouter = () => {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<ProtectedRoute />}>
        <Route path="/" element={<AdminLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="routes" element={<RoutesView />} />
          <Route path="schedules" element={<SchedulesView />} />
          <Route path="fleet" element={<FleetView />} />
          <Route path="seats" element={<SeatManagementView />} />
          <Route path="users" element={<UsersView />} />
          <Route path="analytics" element={<AnalyticsView />} />
          <Route path="notifications" element={<NotificationsView />} />
          <Route path="settings" element={<SettingsView />} />
        </Route>
      </Route>
    </Routes>
  );
};
