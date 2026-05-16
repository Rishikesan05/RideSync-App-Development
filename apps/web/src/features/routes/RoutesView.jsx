import React, { useState } from 'react';
import { 
  Typography, 
  Card, 
  CardContent, 
  CircularProgress, 
  Alert, 
  Box, 
  Grid, 
  Chip,
  Button,
  IconButton,
  Menu,
  MenuItem,
  ListItemIcon,
  useTheme
} from '@mui/material';
import { 
  Add, 
  MoreVert, 
  Edit, 
  Block
} from '@mui/icons-material';
import { 
  useRoutesList, 
  useCreateRoute, 
  useUpdateRoute, 
  useDeactivateRoute 
} from '../../api/routes';
import { RouteFormDialog } from './RouteFormDialog';

export const RoutesView = () => {
  const theme = useTheme();
  const { data: routesResponse, isLoading, error } = useRoutesList();
  const createRoute = useCreateRoute();
  const updateRoute = useUpdateRoute();
  const deactivateRoute = useDeactivateRoute();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [anchorEl, setAnchorEl] = useState(null);
  const [menuRouteId, setMenuRouteId] = useState(null);

  const routes = routesResponse?.data || routesResponse || [];

  const handleOpenMenu = (event, routeId) => {
    setAnchorEl(event.currentTarget);
    setMenuRouteId(routeId);
  };

  const handleCloseMenu = () => {
    setAnchorEl(null);
    setMenuRouteId(null);
  };

  const handleOpenDialog = (route = null) => {
    setSelectedRoute(route);
    setDialogOpen(true);
    handleCloseMenu();
  };

  const handleCloseDialog = () => {
    setSelectedRoute(null);
    setDialogOpen(false);
  };

  const handleToggleActive = async () => {
    const routeId = menuRouteId;
    handleCloseMenu();
    // Use deactivateRoute endpoint (which toggles isActive to false). 
    // In a real app we might want a toggle endpoint or use updateRoute.
    // For now we'll just deactivate it.
    try {
      await deactivateRoute.mutateAsync(routeId);
    } catch (e) {
      console.error('Failed to deactivate route', e);
    }
  };

  const handleSubmit = async (formData) => {
    try {
      if (selectedRoute) {
        // Update
        await updateRoute.mutateAsync({ id: selectedRoute.id, data: formData });
      } else {
        // Create
        await createRoute.mutateAsync(formData);
      }
    } catch (err) {
      console.error('Error saving route', err);
      // In a real app, you'd show a toast notification here
      throw err; // throw so dialog stays open if needed
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Routes Management</Typography>
        <Button 
          variant="contained" 
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
          sx={{ borderRadius: 2 }}
        >
          Add Route
        </Button>
      </Box>
      
      {isLoading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
          <CircularProgress />
        </Box>
      )}
      
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Error fetching routes: {error.message}
        </Alert>
      )}

      {!isLoading && !error && routes.length === 0 && (
        <Card sx={{ p: 5, textAlign: 'center', backgroundColor: 'transparent', border: '1px dashed rgba(255,255,255,0.2)' }}>
          <Typography color="text.secondary" variant="h6">No routes found.</Typography>
          <Typography color="text.secondary" sx={{ mb: 3 }}>Create your first route to get started.</Typography>
          <Button variant="outlined" startIcon={<Add />} onClick={() => handleOpenDialog()}>
            Create Route
          </Button>
        </Card>
      )}

      <Grid container spacing={3}>
        {routes.map((route) => (
          <Grid item xs={12} lg={6} key={route.id}>
            <Card sx={{ height: '100%', position: 'relative' }}>
              <Box sx={{ position: 'absolute', top: 16, right: 8 }}>
                <IconButton onClick={(e) => handleOpenMenu(e, route.id)}>
                  <MoreVert />
                </IconButton>
              </Box>
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1, pr: 4 }}>
                  <Typography variant="h6" sx={{ fontWeight: 700 }}>
                    {route.routeNumber ? `R-${route.routeNumber}: ` : ''}{route.name}
                  </Typography>
                  <Chip 
                    label={route.isActive ? 'Active' : 'Inactive'} 
                    color={route.isActive ? 'success' : 'default'} 
                    size="small" 
                    variant={route.isActive ? "filled" : "outlined"}
                  />
                </Box>
                
                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                  Total Distance: {route.stops[route.stops.length - 1]?.distFromStartKm || 0} km
                </Typography>
                
                <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 600, color: theme.palette.primary.light }}>
                  Route Stops ({route.stops?.length || 0})
                </Typography>
                
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                  {route.stops && route.stops.map((stop, index) => (
                    <Box key={index} sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Box sx={{ 
                        width: 12, 
                        height: 12, 
                        borderRadius: '50%', 
                        backgroundColor: index === 0 ? theme.palette.success.main : 
                                         index === route.stops.length - 1 ? theme.palette.error.main : 
                                         theme.palette.text.secondary 
                      }} />
                      <Typography variant="body2" sx={{ flexGrow: 1 }}>{stop.name}</Typography>
                      <Typography variant="body2" color="text.secondary">{stop.distFromStartKm} km</Typography>
                    </Box>
                  ))}
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Action Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleCloseMenu}
      >
        <MenuItem onClick={() => handleOpenDialog(routes.find(r => r.id === menuRouteId))}>
          <ListItemIcon><Edit fontSize="small" /></ListItemIcon>
          Edit Route
        </MenuItem>
        <MenuItem onClick={handleToggleActive} sx={{ color: theme.palette.error.main }}>
          <ListItemIcon><Block fontSize="small" sx={{ color: 'inherit' }} /></ListItemIcon>
          Deactivate
        </MenuItem>
      </Menu>

      {/* Form Dialog */}
      <RouteFormDialog
        open={dialogOpen}
        onClose={handleCloseDialog}
        onSubmit={handleSubmit}
        initialData={selectedRoute}
      />
    </Box>
  );
};
