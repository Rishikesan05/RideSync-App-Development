import React, { useState, useMemo } from 'react';
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
  TextField,
  InputAdornment,
  ToggleButtonGroup,
  ToggleButton,
  useTheme
} from '@mui/material';
import { 
  Add, 
  MoreVert, 
  Edit, 
  Block,
  Search,
  FilterList,
  PowerSettingsNew
} from '@mui/icons-material';
import { 
  useCreateRoute, 
  useUpdateRoute, 
  useToggleRouteActive 
} from '../../api/routes';
import { useRoutesFirestore } from './useRoutesFirestore';
import { RouteFormDialog } from './RouteFormDialog';
import { RouteStatsBar } from './RouteStatsBar';

export const RoutesView = () => {
  const theme = useTheme();
  const { routes, loading, error } = useRoutesFirestore();
  const createRoute      = useCreateRoute();
  const updateRoute      = useUpdateRoute();
  const toggleActive     = useToggleRouteActive();

  const [dialogOpen, setDialogOpen]   = useState(false);
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [anchorEl, setAnchorEl]       = useState(null);
  const [menuRouteId, setMenuRouteId] = useState(null);
  const [search, setSearch]           = useState('');
  const [statusFilter, setStatusFilter] = useState('all'); // 'all' | 'active' | 'inactive'

  // Client-side filter — no extra Firestore reads
  const filteredRoutes = useMemo(() => {
    const q = search.toLowerCase();
    return routes.filter((r) => {
      const matchesSearch =
        !q ||
        (r.name || '').toLowerCase().includes(q) ||
        (r.routeNumber || '').toString().includes(q) ||
        (r.startPoint || '').toLowerCase().includes(q) ||
        (r.endPoint || '').toLowerCase().includes(q);
      const matchesStatus =
        statusFilter === 'all' ||
        (statusFilter === 'active' && r.isActive) ||
        (statusFilter === 'inactive' && !r.isActive);
      return matchesSearch && matchesStatus;
    });
  }, [routes, search, statusFilter]);


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
    const route = routes.find(r => r.id === menuRouteId);
    handleCloseMenu();
    try {
      await toggleActive.mutateAsync({ id: menuRouteId, currentIsActive: route?.isActive ?? true });
    } catch (e) {
      console.error('Failed to toggle route active state', e);
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
      {/* ── Header row ─────────────────────────────────────────────────── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
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

      {/* ── Stats summary bar ────────────────────────────────────────────── */}
      <RouteStatsBar routes={routes} loading={loading} />

      {/* ── Search + Filter bar ─────────────────────────────────────────── */}
      <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', mb: 3, flexWrap: 'wrap' }}>
        <TextField
          size="small"
          placeholder="Search by name, number, origin or destination…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search fontSize="small" sx={{ color: 'text.secondary' }} />
              </InputAdornment>
            ),
          }}
          sx={{ flex: 1, minWidth: 240 }}
        />

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <FilterList fontSize="small" sx={{ color: 'text.secondary' }} />
          <ToggleButtonGroup
            size="small"
            exclusive
            value={statusFilter}
            onChange={(_, val) => val && setStatusFilter(val)}
          >
            <ToggleButton value="all">All ({routes.length})</ToggleButton>
            <ToggleButton value="active" sx={{ color: 'success.main' }}>
              Active ({routes.filter(r => r.isActive).length})
            </ToggleButton>
            <ToggleButton value="inactive" sx={{ color: 'error.main' }}>
              Inactive ({routes.filter(r => !r.isActive).length})
            </ToggleButton>
          </ToggleButtonGroup>
        </Box>
      </Box>
      
      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
          <CircularProgress />
        </Box>
      )}
      
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Error fetching routes: {error.message}
        </Alert>
      )}

      {!loading && !error && routes.length === 0 && (
        <Card sx={{ p: 5, textAlign: 'center', backgroundColor: 'transparent', border: '1px dashed rgba(255,255,255,0.2)' }}>
          <Typography color="text.secondary" variant="h6">No routes found.</Typography>
          <Typography color="text.secondary" sx={{ mb: 3 }}>Create your first route to get started.</Typography>
          <Button variant="outlined" startIcon={<Add />} onClick={() => handleOpenDialog()}>
            Create Route
          </Button>
        </Card>
      )}

      {!loading && !error && routes.length > 0 && filteredRoutes.length === 0 && (
        <Alert severity="info" sx={{ mb: 3 }}>
          No routes match your search or filter. Try a different keyword or select "All".
        </Alert>
      )}

      <Grid container spacing={3}>
        {filteredRoutes.map((route) => (
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
                
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">
                    {route.startPoint || 'Origin'}
                  </Typography>
                  <Typography variant="body2" color="text.disabled">→</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {route.endPoint || 'Destination'}
                  </Typography>
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                  Total Distance:{' '}
                  <strong>
                    {route.totalDistanceKm
                      ?? route.stops?.[route.stops.length - 1]?.distFromStartKm
                      ?? 0} km
                  </strong>
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
      {/* menuRoute lets us read isActive of the currently-targeted route */}
      {(() => {
        const menuRoute = routes.find(r => r.id === menuRouteId);
        const isCurrentlyActive = menuRoute?.isActive ?? true;
        return (
          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleCloseMenu}
          >
            <MenuItem onClick={() => handleOpenDialog(menuRoute)}>
              <ListItemIcon><Edit fontSize="small" /></ListItemIcon>
              Edit Route
            </MenuItem>

            <MenuItem
              onClick={handleToggleActive}
              sx={{ color: isCurrentlyActive ? theme.palette.error.main : theme.palette.success.main }}
            >
              <ListItemIcon>
                {isCurrentlyActive
                  ? <Block fontSize="small" sx={{ color: 'inherit' }} />
                  : <PowerSettingsNew fontSize="small" sx={{ color: 'inherit' }} />}
              </ListItemIcon>
              {isCurrentlyActive ? 'Deactivate Route' : 'Activate Route'}
            </MenuItem>
          </Menu>
        );
      })()}

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
