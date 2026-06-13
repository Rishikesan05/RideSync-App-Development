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
  useTheme,
  Divider,
  Avatar,
  Snackbar,
  Paper
} from '@mui/material';
import { 
  Add, 
  MoreVert, 
  Edit, 
  Block, 
  DirectionsBus,
  Person,
  Delete,
  CheckCircle,
  Cancel,
  AcUnit,
  AirlineSeatReclineNormal
} from '@mui/icons-material';
import { 
  useCreateBus, 
  useUpdateBus, 
  useDeactivateBus,
  useDeleteBus
} from '../../api/buses';
import { useBusesFirestore } from './useBusesFirestore';
import { BusFormDialog } from './BusFormDialog';

// ── Stats summary card ──────────────────────────────────────────────────────
const StatCard = ({ icon, label, value, color }) => {
  const theme = useTheme();
  return (
    <Paper
      elevation={0}
      sx={{
        p: 2.5,
        display: 'flex',
        alignItems: 'center',
        gap: 2,
        borderRadius: 3,
        border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`,
        background: theme.palette.mode === 'dark'
          ? 'rgba(255,255,255,0.03)'
          : 'rgba(0,0,0,0.02)',
        flex: 1,
        minWidth: 130,
      }}
    >
      <Avatar sx={{ bgcolor: `${color}22`, color, width: 44, height: 44 }}>
        {icon}
      </Avatar>
      <Box>
        <Typography variant="h5" sx={{ fontWeight: 700, lineHeight: 1 }}>{value}</Typography>
        <Typography variant="caption" color="text.secondary">{label}</Typography>
      </Box>
    </Paper>
  );
};

// ── Main Fleet View ────────────────────────────────────────────────────────
export const FleetView = () => {
  const theme = useTheme();

  // Real-time Firestore listener — replaces old useBusesList() (axios)
  const { buses, loading, error } = useBusesFirestore();

  const createBus    = useCreateBus();
  const updateBus    = useUpdateBus();
  const deactivateBus = useDeactivateBus();
  const deleteBus    = useDeleteBus();

  const [dialogOpen, setDialogOpen]   = useState(false);
  const [selectedBus, setSelectedBus] = useState(null);
  const [anchorEl, setAnchorEl]       = useState(null);
  const [menuBusId, setMenuBusId]     = useState(null);
  const [toast, setToast]             = useState({ open: false, message: '', severity: 'success' });

  // ── computed stats ──────────────────────────────────────────────────────
  const totalBuses    = buses.length;
  const activeBuses   = buses.filter((b) => b.isActive).length;
  const inactiveBuses = totalBuses - activeBuses;
  const acBuses       = buses.filter((b) => b.class === 'AC').length;

  const showToast = (message, severity = 'success') => {
    setToast({ open: true, message, severity });
  };

  // ── menu handlers ────────────────────────────────────────────────────────
  const handleOpenMenu = (event, busId) => {
    setAnchorEl(event.currentTarget);
    setMenuBusId(busId);
  };

  const handleCloseMenu = () => {
    setAnchorEl(null);
    setMenuBusId(null);
  };

  // ── dialog handlers ──────────────────────────────────────────────────────
  const handleOpenDialog = (bus = null) => {
    setSelectedBus(bus);
    setDialogOpen(true);
    handleCloseMenu();
  };

  const handleCloseDialog = () => {
    setSelectedBus(null);
    setDialogOpen(false);
  };

  // ── CRUD handlers ────────────────────────────────────────────────────────
  const handleDeactivate = async () => {
    const busId = menuBusId;
    handleCloseMenu();
    try {
      await deactivateBus.mutateAsync(busId);
      showToast('Bus deactivated successfully.');
    } catch (e) {
      console.error('Failed to deactivate bus', e);
      showToast('Failed to deactivate bus.', 'error');
    }
  };

  const handleDelete = async () => {
    const busId = menuBusId;
    handleCloseMenu();
    if (!window.confirm('Permanently delete this bus? This cannot be undone.')) return;
    try {
      await deleteBus.mutateAsync(busId);
      showToast('Bus permanently deleted.');
    } catch (e) {
      console.error('Failed to delete bus', e);
      showToast('Failed to delete bus.', 'error');
    }
  };

  const handleSubmit = async (formData) => {
    try {
      if (selectedBus) {
        await updateBus.mutateAsync({ id: selectedBus.id, data: formData });
        showToast('Bus updated successfully.');
      } else {
        await createBus.mutateAsync(formData);
        showToast('Bus registered successfully.');
      }
    } catch (err) {
      console.error('Error saving bus', err);
      showToast('Failed to save bus.', 'error');
      throw err;
    }
  };

  return (
    <Box>
      {/* ── Header ──────────────────────────────────────────────────────── */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>Bus Management</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
            Register, edit and manage your fleet of buses.
          </Typography>
        </Box>
        <Button 
          variant="contained" 
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
          sx={{ borderRadius: 2, px: 3 }}
        >
          Add Bus
        </Button>
      </Box>

      {/* ── Stats Bar ───────────────────────────────────────────────────── */}
      {!loading && !error && (
        <Box sx={{ display: 'flex', gap: 2, mb: 4, flexWrap: 'wrap' }}>
          <StatCard
            icon={<DirectionsBus />}
            label="Total Buses"
            value={totalBuses}
            color={theme.palette.primary.main}
          />
          <StatCard
            icon={<CheckCircle />}
            label="Active"
            value={activeBuses}
            color={theme.palette.success.main}
          />
          <StatCard
            icon={<Cancel />}
            label="Inactive"
            value={inactiveBuses}
            color={theme.palette.error.main}
          />
          <StatCard
            icon={<AcUnit />}
            label="A/C Buses"
            value={acBuses}
            color={theme.palette.info.main}
          />
        </Box>
      )}

      {/* ── Loading state ───────────────────────────────────────────────── */}
      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
          <CircularProgress />
        </Box>
      )}
      
      {/* ── Error state ─────────────────────────────────────────────────── */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Error fetching fleet: {error.message}
        </Alert>
      )}

      {/* ── Empty state ─────────────────────────────────────────────────── */}
      {!loading && !error && buses.length === 0 && (
        <Card
          sx={{
            p: 6,
            textAlign: 'center',
            backgroundColor: 'transparent',
            border: `2px dashed ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.1)'}`,
            borderRadius: 4,
          }}
        >
          <Avatar sx={{ bgcolor: 'rgba(230,141,51,0.12)', color: '#E68D33', width: 72, height: 72, mx: 'auto', mb: 2 }}>
            <DirectionsBus sx={{ fontSize: 40 }} />
          </Avatar>
          <Typography color="text.primary" variant="h6" sx={{ fontWeight: 600 }}>No buses registered yet</Typography>
          <Typography color="text.secondary" sx={{ mb: 3 }}>
            Add your first bus to start managing your fleet.
          </Typography>
          <Button variant="contained" startIcon={<Add />} onClick={() => handleOpenDialog()}>
            Register First Bus
          </Button>
        </Card>
      )}

      {/* ── Bus Grid ────────────────────────────────────────────────────── */}
      <Grid container spacing={3}>
        {buses.map((bus) => (
          <Grid item xs={12} sm={6} lg={4} key={bus.id}>
            <Card
              sx={{
                height: '100%',
                borderRadius: '16px',
                border: '1.5px solid rgba(230, 141, 51, 0.25)',
                borderTop: '4px solid #E68D33',
                background: theme.palette.mode === 'dark'
                  ? 'linear-gradient(135deg, rgba(30, 41, 59, 0.75) 0%, rgba(15, 23, 42, 0.8) 100%)'
                  : 'linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(248, 250, 252, 0.9) 100%)',
                backdropFilter: 'blur(20px)',
                boxShadow: theme.palette.mode === 'dark'
                  ? '0 4px 20px -2px rgba(0, 0, 0, 0.3)'
                  : '0 4px 20px -2px rgba(0, 0, 0, 0.03)',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                position: 'relative',
                overflow: 'visible',
                '&:hover': {
                  transform: 'translateY(-6px)',
                  boxShadow: theme.palette.mode === 'dark'
                    ? '0 16px 28px -10px rgba(230, 141, 51, 0.25), 0 8px 30px rgba(0,0,0,0.4)'
                    : '0 16px 24px -10px rgba(230, 141, 51, 0.18), 0 6px 20px rgba(0,0,0,0.06)',
                  borderColor: '#E68D33',
                  '& .ticket-notch': {
                    borderColor: '#E68D33',
                  }
                },
              }}
            >
              {/* ── Context menu button ─────────────────────────────────── */}
              <Box sx={{ position: 'absolute', top: 12, right: 8, zIndex: 1 }}>
                <IconButton size="small" onClick={(e) => handleOpenMenu(e, bus.id)}>
                  <MoreVert fontSize="small" />
                </IconButton>
              </Box>

              <CardContent sx={{ p: 3 }}>
                {/* ── Bus header ──────────────────────────────────────── */}
                <Box sx={{ display: 'flex', alignItems: 'flex-start', mb: 2 }}>
                  <Avatar 
                    sx={{ 
                      bgcolor: bus.class === 'AC'
                        ? `${theme.palette.info.main}22`
                        : `${theme.palette.primary.main}22`,
                      color: bus.class === 'AC' ? theme.palette.info.main : theme.palette.primary.main,
                      width: 52, 
                      height: 52,
                      mr: 2,
                    }}
                  >
                    <DirectionsBus />
                  </Avatar>
                  <Box sx={{ flex: 1, minWidth: 0 }}>
                    <Typography variant="h6" sx={{ fontWeight: 700, letterSpacing: 0.5 }} noWrap>
                      {bus.plateNumber}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mt: 0.5 }}>
                      <Chip 
                        label={bus.isActive ? 'Active' : 'Inactive'} 
                        color={bus.isActive ? 'success' : 'default'} 
                        size="small" 
                        variant="outlined"
                        sx={{ height: 20, fontSize: '0.7rem' }}
                      />
                      <Chip
                        label={bus.class === 'AC' ? 'Express A/C' : 'Normal'}
                        color={bus.class === 'AC' ? 'info' : 'default'}
                        size="small"
                        sx={{ height: 20, fontSize: '0.7rem' }}
                      />
                    </Box>
                  </Box>
                </Box>
                
                {/* Ticket Divider & Cutout Notches */}
                <Box sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'space-between', 
                  mx: -3, 
                  my: 2.5,
                  height: '20px',
                  position: 'relative'
                }}>
                  {/* Left Notch */}
                  <Box 
                    className="ticket-notch"
                    sx={{
                      position: 'absolute',
                      left: '-10px',
                      top: '50%',
                      transform: 'translateY(-50%)',
                      width: '20px',
                      height: '20px',
                      borderRadius: '50%',
                      backgroundColor: theme.palette.background.default,
                      border: '1.5px solid rgba(230, 141, 51, 0.25)',
                      borderLeftColor: 'transparent',
                      borderTopColor: 'transparent',
                      borderBottomColor: 'transparent',
                      zIndex: 2,
                      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    }} 
                  />
                  
                  {/* Perforation Line */}
                  <Box sx={{ 
                    flex: 1, 
                    borderTop: `1.2px dashed ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)'}`, 
                    height: '1px', 
                    mx: 1.5
                  }} />
                  
                  {/* Right Notch */}
                  <Box 
                    className="ticket-notch"
                    sx={{
                      position: 'absolute',
                      right: '-10px',
                      top: '50%',
                      transform: 'translateY(-50%)',
                      width: '20px',
                      height: '20px',
                      borderRadius: '50%',
                      backgroundColor: theme.palette.background.default,
                      border: '1.5px solid rgba(230, 141, 51, 0.25)',
                      borderRightColor: 'transparent',
                      borderTopColor: 'transparent',
                      borderBottomColor: 'transparent',
                      zIndex: 2,
                      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    }} 
                  />
                </Box>
                
                {/* ── Details grid ────────────────────────────────────── */}
                <Grid container spacing={2}>
                  <Grid item xs={6}>
                    <Typography variant="caption" color="text.secondary" display="block">Capacity</Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                      <AirlineSeatReclineNormal sx={{ fontSize: 14, color: 'text.secondary' }} />
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{bus.capacity} seats</Typography>
                    </Box>
                  </Grid>
                  {bus.model && (
                    <Grid item xs={6}>
                      <Typography variant="caption" color="text.secondary" display="block">Model</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }} noWrap>{bus.model}</Typography>
                    </Grid>
                  )}
                  {bus.year && (
                    <Grid item xs={6}>
                      <Typography variant="caption" color="text.secondary" display="block">Year</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{bus.year}</Typography>
                    </Grid>
                  )}
                </Grid>

                {/* ── Operator info ───────────────────────────────────── */}
                <Box
                  sx={{
                    mt: 2,
                    p: 1.5,
                    backgroundColor: theme.palette.mode === 'dark' ? 'rgba(0,0,0,0.2)' : 'rgba(0,0,0,0.04)',
                    borderRadius: 2,
                    display: 'flex',
                    alignItems: 'center',
                  }}
                >
                  <Person sx={{ fontSize: 18, color: theme.palette.text.secondary, mr: 1 }} />
                  <Typography
                    variant="body2"
                    color={bus.operatorId ? 'text.primary' : 'text.secondary'}
                    noWrap
                  >
                    {bus.operatorId
                      ? `Operator: ${bus.operatorId.substring(0, 12)}...`
                      : 'No Operator Assigned'}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* ── Context Menu ────────────────────────────────────────────────── */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleCloseMenu}
        PaperProps={{
          sx: {
            minWidth: 160,
            boxShadow: '0 8px 24px rgba(0,0,0,0.2)',
            border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`,
          }
        }}
      >
        <MenuItem onClick={() => handleOpenDialog(buses.find((b) => b.id === menuBusId))}>
          <ListItemIcon><Edit fontSize="small" /></ListItemIcon>
          Edit Bus
        </MenuItem>
        <MenuItem onClick={handleDeactivate}>
          <ListItemIcon><Block fontSize="small" sx={{ color: theme.palette.warning.main }} /></ListItemIcon>
          <Typography sx={{ color: theme.palette.warning.main }}>Deactivate</Typography>
        </MenuItem>
        <Divider sx={{ my: 0.5 }} />
        <MenuItem onClick={handleDelete}>
          <ListItemIcon><Delete fontSize="small" sx={{ color: theme.palette.error.main }} /></ListItemIcon>
          <Typography sx={{ color: theme.palette.error.main }}>Delete Bus</Typography>
        </MenuItem>
      </Menu>

      {/* ── Bus Form Dialog ─────────────────────────────────────────────── */}
      <BusFormDialog
        open={dialogOpen}
        onClose={handleCloseDialog}
        onSubmit={handleSubmit}
        initialData={selectedBus}
        existingPlates={buses
          .filter((b) => b.id !== selectedBus?.id)
          .map((b) => b.plateNumber)}
      />

      {/* ── Toast Snackbar ──────────────────────────────────────────────── */}
      <Snackbar
        open={toast.open}
        autoHideDuration={4000}
        onClose={() => setToast((t) => ({ ...t, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert
          onClose={() => setToast((t) => ({ ...t, open: false }))}
          severity={toast.severity}
          variant="filled"
          sx={{ minWidth: 280 }}
        >
          {toast.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};
