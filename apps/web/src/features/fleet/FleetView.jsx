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
  Avatar
} from '@mui/material';
import { 
  Add, 
  MoreVert, 
  Edit, 
  Block, 
  DirectionsBus,
  Person
} from '@mui/icons-material';
import { 
  useBusesList, 
  useCreateBus, 
  useUpdateBus, 
  useDeactivateBus 
} from '../../api/buses';
import { BusFormDialog } from './BusFormDialog';

export const FleetView = () => {
  const theme = useTheme();
  const { data: busesResponse, isLoading, error } = useBusesList();
  const createBus = useCreateBus();
  const updateBus = useUpdateBus();
  const deactivateBus = useDeactivateBus();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedBus, setSelectedBus] = useState(null);
  const [anchorEl, setAnchorEl] = useState(null);
  const [menuBusId, setMenuBusId] = useState(null);

  const buses = busesResponse?.data || busesResponse || [];

  const handleOpenMenu = (event, busId) => {
    setAnchorEl(event.currentTarget);
    setMenuBusId(busId);
  };

  const handleCloseMenu = () => {
    setAnchorEl(null);
    setMenuBusId(null);
  };

  const handleOpenDialog = (bus = null) => {
    setSelectedBus(bus);
    setDialogOpen(true);
    handleCloseMenu();
  };

  const handleCloseDialog = () => {
    setSelectedBus(null);
    setDialogOpen(false);
  };

  const handleDeactivate = async () => {
    const busId = menuBusId;
    handleCloseMenu();
    try {
      await deactivateBus.mutateAsync(busId);
    } catch (e) {
      console.error('Failed to deactivate bus', e);
    }
  };

  const handleSubmit = async (formData) => {
    try {
      if (selectedBus) {
        await updateBus.mutateAsync({ id: selectedBus.id, data: formData });
      } else {
        await createBus.mutateAsync(formData);
      }
    } catch (err) {
      console.error('Error saving bus', err);
      throw err;
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Fleet Management</Typography>
        <Button 
          variant="contained" 
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
          sx={{ borderRadius: 2 }}
        >
          Add Bus
        </Button>
      </Box>
      
      {isLoading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
          <CircularProgress />
        </Box>
      )}
      
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Error fetching fleet: {error.message}
        </Alert>
      )}

      {!isLoading && !error && buses.length === 0 && (
        <Card sx={{ p: 5, textAlign: 'center', backgroundColor: 'transparent', border: '1px dashed rgba(255,255,255,0.2)' }}>
          <Typography color="text.secondary" variant="h6">No buses found.</Typography>
          <Typography color="text.secondary" sx={{ mb: 3 }}>Register your first bus to the fleet.</Typography>
          <Button variant="outlined" startIcon={<Add />} onClick={() => handleOpenDialog()}>
            Register Bus
          </Button>
        </Card>
      )}

      <Grid container spacing={3}>
        {buses.map((bus) => (
          <Grid item xs={12} sm={6} lg={4} key={bus.id}>
            <Card sx={{ height: '100%', position: 'relative', overflow: 'visible' }}>
              <Box sx={{ position: 'absolute', top: 16, right: 8 }}>
                <IconButton onClick={(e) => handleOpenMenu(e, bus.id)}>
                  <MoreVert />
                </IconButton>
              </Box>
              
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', alignItems: 'flex-start', mb: 2 }}>
                  <Avatar 
                    sx={{ 
                      bgcolor: bus.class === 'AC' ? theme.palette.info.main : theme.palette.primary.main,
                      width: 50, 
                      height: 50,
                      mr: 2,
                      boxShadow: `0 4px 10px ${bus.class === 'AC' ? theme.palette.info.main : theme.palette.primary.main}40`
                    }}
                  >
                    <DirectionsBus />
                  </Avatar>
                  <Box>
                    <Typography variant="h6" sx={{ fontWeight: 700, letterSpacing: 0.5 }}>
                      {bus.plateNumber}
                    </Typography>
                    <Chip 
                      label={bus.isActive ? 'Active' : 'Inactive'} 
                      color={bus.isActive ? 'success' : 'default'} 
                      size="small" 
                      variant="outlined"
                      sx={{ height: 20, fontSize: '0.7rem', mt: 0.5 }}
                    />
                  </Box>
                </Box>
                
                <Divider sx={{ my: 2, borderColor: 'rgba(255,255,255,0.05)' }} />
                
                <Grid container spacing={2}>
                  <Grid item xs={6}>
                    <Typography variant="caption" color="text.secondary" display="block">Class</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {bus.class === 'AC' ? 'Express (A/C)' : 'Normal (Non-A/C)'}
                    </Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="caption" color="text.secondary" display="block">Capacity</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>{bus.capacity} seats</Typography>
                  </Grid>
                </Grid>

                <Box sx={{ mt: 2, p: 1.5, backgroundColor: 'rgba(0,0,0,0.2)', borderRadius: 2, display: 'flex', alignItems: 'center' }}>
                  <Person sx={{ fontSize: 18, color: theme.palette.text.secondary, mr: 1 }} />
                  <Typography variant="body2" color={bus.operatorId ? "text.primary" : "text.secondary"} noWrap>
                    {bus.operatorId ? `Operator: ${bus.operatorId.substring(0, 8)}...` : 'No Operator Assigned'}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleCloseMenu}
      >
        <MenuItem onClick={() => handleOpenDialog(buses.find(b => b.id === menuBusId))}>
          <ListItemIcon><Edit fontSize="small" /></ListItemIcon>
          Edit Bus
        </MenuItem>
        <MenuItem onClick={handleDeactivate} sx={{ color: theme.palette.error.main }}>
          <ListItemIcon><Block fontSize="small" sx={{ color: 'inherit' }} /></ListItemIcon>
          Deactivate
        </MenuItem>
      </Menu>

      <BusFormDialog
        open={dialogOpen}
        onClose={handleCloseDialog}
        onSubmit={handleSubmit}
        initialData={selectedBus}
      />
    </Box>
  );
};
