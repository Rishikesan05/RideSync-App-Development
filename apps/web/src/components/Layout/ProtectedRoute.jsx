import React from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../../providers/AuthProvider';
import { Box, CircularProgress } from '@mui/material';

export const ProtectedRoute = () => {
  const { currentUser, isAdmin, isOperator, loading } = useAuth();
  const location = useLocation();

  // Still resolving auth state or fetching Firestore profile
  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  // Not signed in at all → send to login
  if (!currentUser) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Signed in but neither admin nor operator → send to pending-approval page
  if (!isAdmin && !isOperator) {
    return <Navigate to="/pending" replace />;
  }

  return <Outlet />;
};
