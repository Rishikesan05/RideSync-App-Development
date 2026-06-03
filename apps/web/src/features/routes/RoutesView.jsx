import React, { useState, useMemo } from 'react';
import { 
  Typography, 
  Card, 
  CardContent, 
  CardActions,
  Collapse,
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
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Divider,
  useTheme
} from '@mui/material';
import { 
  Add, 
  MoreVert, 
  Edit, 
  Block,
  Search,
  FilterList,
  PowerSettingsNew,
  DeleteOutlined,
  ExpandMore,
  ExpandLess
} from '@mui/icons-material';
import { 
  useCreateRoute, 
  useUpdateRoute, 
  useToggleRouteActive,
  useDeleteRoute
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
  const deleteRoute      = useDeleteRoute();

  const [dialogOpen, setDialogOpen]   = useState(false);
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [anchorEl, setAnchorEl]       = useState(null);
  const [menuRouteId, setMenuRouteId]           = useState(null);
  const [search, setSearch]                     = useState('');
  const [statusFilter, setStatusFilter]         = useState('all');
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [routeToDelete, setRouteToDelete]       = useState(null);
  const [expandedRoutes, setExpandedRoutes]     = useState(new Set());

  const toggleExpand = (routeId) =>
    setExpandedRoutes((prev) => {
      const next = new Set(prev);
      next.has(routeId) ? next.delete(routeId) : next.add(routeId);
      return next;
    });

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

  const handleDeleteClick = () => {
    const route = routes.find(r => r.id === menuRouteId);
    setRouteToDelete(route);
    handleCloseMenu();
    setDeleteConfirmOpen(true);
  };

  const handleDeleteConfirm = async () => {
    setDeleteConfirmOpen(false);
    try {
      await deleteRoute.mutateAsync(routeToDelete.id);
    } catch (e) {
      console.error('Failed to delete route', e);
    } finally {
      setRouteToDelete(null);
    }
  };

  const handleDeleteCancel = () => {
    setDeleteConfirmOpen(false);
    setRouteToDelete(null);
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
                
              </CardContent>

              {/* ── Expand toggle ────────────────────────────────── */}
              {route.stops?.length > 0 && (
                <>
                  <CardActions sx={{ px: 2, pt: 0, pb: expandedRoutes.has(route.id) ? 0 : 1 }}>
                    <Button
                      size="small"
                      onClick={() => toggleExpand(route.id)}
                      endIcon={expandedRoutes.has(route.id) ? <ExpandLess /> : <ExpandMore />}
                      sx={{ color: 'primary.light', fontWeight: 600, fontSize: '0.75rem' }}
                    >
                      {expandedRoutes.has(route.id)
                        ? 'Hide Stops'
                        : `Show ${route.stops.length} Stop${route.stops.length !== 1 ? 's' : ''}`}
                    </Button>
                  </CardActions>

                  {/* ── Stops timeline panel ────────────────────────── */}
                  <Collapse in={expandedRoutes.has(route.id)} timeout="auto" unmountOnExit>
                    <Box
                      sx={{
                        mx: 2,
                        mb: 2,
                        p: 2,
                        borderRadius: 2,
                        backgroundColor: 'rgba(255,255,255,0.03)',
                        border: '1px solid rgba(255,255,255,0.06)',
                      }}
                    >
                      {route.stops.map((stop, idx) => {
                        const isFirst = idx === 0;
                        const isLast  = idx === route.stops.length - 1;
                        const dotColor = isFirst
                          ? theme.palette.success.main
                          : isLast
                          ? theme.palette.error.main
                          : theme.palette.primary.main;
                        return (
                          <Box key={idx} sx={{ display: 'flex', alignItems: 'flex-start', gap: 1.5 }}>
                            {/* Vertical connector + dot */}
                            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: 16, flexShrink: 0 }}>
                              <Box sx={{ width: 12, height: 12, borderRadius: '50%', backgroundColor: dotColor, flexShrink: 0, mt: 0.3, boxShadow: `0 0 6px ${dotColor}88` }} />
                              {!isLast && (
                                <Box sx={{ width: 2, flex: 1, minHeight: 20, backgroundColor: 'rgba(255,255,255,0.1)', borderRadius: 1, my: 0.3 }} />
                              )}
                            </Box>

                            {/* Stop info */}
                            <Box sx={{ pb: isLast ? 0 : 1.5, flex: 1 }}>
                              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <Typography
                                  variant="body2"
                                  sx={{
                                    fontWeight: isFirst || isLast ? 700 : 400,
                                    color: isFirst ? 'success.light' : isLast ? 'error.light' : 'text.primary',
                                  }}
                                >
                                  {stop.name}
                                </Typography>
                                <Chip
                                  label={`${stop.distFromStartKm} km`}
                                  size="small"
                                  sx={{
                                    height: 20,
                                    fontSize: '0.68rem',
                                    fontWeight: 700,
                                    backgroundColor: `${dotColor}18`,
                                    color: dotColor,
                                    border: `1px solid ${dotColor}40`,
                                  }}
                                />
                              </Box>
                              {isFirst && <Typography variant="caption" color="success.dark">Origin</Typography>}
                              {isLast  && <Typography variant="caption" color="error.dark">Destination</Typography>}
                            </Box>
                          </Box>
                        );
                      })}
                    </Box>
                  </Collapse>
                </>
              )}
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

            <MenuItem onClick={handleToggleActive}
              sx={{ color: isCurrentlyActive ? theme.palette.error.main : theme.palette.success.main }}
            >
              <ListItemIcon>
                {isCurrentlyActive
                  ? <Block fontSize="small" sx={{ color: 'inherit' }} />
                  : <PowerSettingsNew fontSize="small" sx={{ color: 'inherit' }} />}
              </ListItemIcon>
              {isCurrentlyActive ? 'Deactivate Route' : 'Activate Route'}
            </MenuItem>

            <Divider sx={{ my: 0.5, borderColor: 'rgba(255,255,255,0.06)' }} />

            <MenuItem onClick={handleDeleteClick} sx={{ color: theme.palette.error.main }}>
              <ListItemIcon>
                <DeleteOutlined fontSize="small" sx={{ color: 'inherit' }} />
              </ListItemIcon>
              Delete Route
            </MenuItem>
          </Menu>
        );
      })()}

      {/* ── Delete confirmation dialog ─────────────────────────────────── */}
      <Dialog
        open={deleteConfirmOpen}
        onClose={handleDeleteCancel}
        maxWidth="xs"
        fullWidth
        PaperProps={{
          sx: {
            backgroundColor: 'background.paper',
            backgroundImage: 'none',
            border: '1px solid rgba(255,255,255,0.1)',
            borderRadius: 2,
          }
        }}
      >
        <DialogTitle sx={{ fontWeight: 700, color: 'error.main', display: 'flex', alignItems: 'center', gap: 1 }}>
          <DeleteOutlined />
          Delete Route
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary">
            Are you sure you want to permanently delete:
          </Typography>
          <Typography variant="subtitle1" sx={{ fontWeight: 700, mt: 1 }}>
            {routeToDelete?.routeNumber ? `R-${routeToDelete.routeNumber}: ` : ''}
            {routeToDelete?.name || 'this route'}
          </Typography>
          <Alert severity="warning" sx={{ mt: 2, fontSize: '0.8rem' }}>
            This action cannot be undone. All associated data will be lost.
          </Alert>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2, gap: 1 }}>
          <Button onClick={handleDeleteCancel} color="inherit" variant="outlined">
            Cancel
          </Button>
          <Button
            onClick={handleDeleteConfirm}
            color="error"
            variant="contained"
            disabled={deleteRoute.isPending}
            startIcon={<DeleteOutlined />}
          >
            {deleteRoute.isPending ? 'Deleting...' : 'Yes, Delete'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Form Dialog ────────────────────────────────────────────────── */}
      <RouteFormDialog
        open={dialogOpen}
        onClose={handleCloseDialog}
        onSubmit={handleSubmit}
        initialData={selectedRoute}
      />
    </Box>
  );
};
