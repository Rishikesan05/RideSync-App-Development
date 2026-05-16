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
  Divider
} from '@mui/material';
import { 
  Add, 
  MoreVert, 
  Block, 
  DirectionsBus,
  Schedule as ScheduleIcon
} from '@mui/icons-material';
import { 
  useSchedulesList, 
  useCreateSchedule, 
  useCancelSchedule 
} from '../../api/schedules';
import { ScheduleFormDialog } from './ScheduleFormDialog';
import { format, isValid } from 'date-fns';

export const SchedulesView = () => {
  const theme = useTheme();
  const { data: schedulesResponse, isLoading, error } = useSchedulesList();
  const createSchedule = useCreateSchedule();
  const cancelSchedule = useCancelSchedule();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);
  const [menuScheduleId, setMenuScheduleId] = useState(null);

  const schedulesData = schedulesResponse?.data || schedulesResponse?.schedules || schedulesResponse || [];
  const schedules = Array.isArray(schedulesData) ? schedulesData : [];

  const formatDateTime = (timeStr) => {
    try {
      const date = new Date(timeStr);
      return isValid(date) ? format(date, 'MMM dd, yyyy - hh:mm a') : 'Invalid Date';
    } catch (e) {
      return 'N/A';
    }
  };

  const handleOpenMenu = (event, scheduleId) => {
    setAnchorEl(event.currentTarget);
    setMenuScheduleId(scheduleId);
  };

  const handleCloseMenu = () => {
    setAnchorEl(null);
    setMenuScheduleId(null);
  };

  const handleOpenDialog = () => {
    setDialogOpen(true);
    handleCloseMenu();
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
  };

  const handleCancelSchedule = async () => {
    const scheduleId = menuScheduleId;
    handleCloseMenu();
    try {
      await cancelSchedule.mutateAsync(scheduleId);
    } catch (e) {
      console.error('Failed to cancel schedule', e);
    }
  };

  const handleSubmit = async (formData) => {
    try {
      await createSchedule.mutateAsync(formData);
    } catch (err) {
      console.error('Error creating schedule', err);
      throw err; 
    }
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'scheduled': return 'primary';
      case 'active': return 'success';
      case 'completed': return 'default';
      case 'cancelled': return 'error';
      default: return 'default';
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Schedules Management</Typography>
        <Button 
          variant="contained" 
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
          sx={{ borderRadius: 2 }}
        >
          Create Schedule
        </Button>
      </Box>
      
      {isLoading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
          <CircularProgress />
        </Box>
      )}
      
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          Error fetching schedules: {error.message}
        </Alert>
      )}

      {!isLoading && !error && schedules.length === 0 && (
        <Card sx={{ p: 5, textAlign: 'center', backgroundColor: 'transparent', border: '1px dashed rgba(255,255,255,0.2)' }}>
          <Typography color="text.secondary" variant="h6">No schedules found.</Typography>
          <Typography color="text.secondary" sx={{ mb: 3 }}>Create your first schedule to get started.</Typography>
          <Button variant="outlined" startIcon={<Add />} onClick={() => handleOpenDialog()}>
            Create Schedule
          </Button>
        </Card>
      )}

      <Grid container spacing={3}>
        {schedules.map((schedule) => {
          if (!schedule || !schedule.id) return null;
          
          const status = schedule.status || 'scheduled';
          const busId = schedule.busId || 'N/A';
          const statusColor = getStatusColor(status);
          const colorMain = theme.palette[statusColor]?.main || theme.palette.primary.main;
          
          return (
            <Grid item xs={12} md={6} lg={4} key={schedule.id}>
              <Card sx={{ 
                height: '100%', 
                position: 'relative', 
                borderTop: `4px solid ${colorMain}`,
                transition: 'transform 0.2s',
                '&:hover': { transform: 'translateY(-4px)' }
              }}>
                <Box sx={{ position: 'absolute', top: 8, right: 8 }}>
                  <IconButton onClick={(e) => handleOpenMenu(e, schedule.id)}>
                    <MoreVert />
                  </IconButton>
                </Box>
                <CardContent sx={{ p: 3 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2, pr: 4 }}>
                    <Chip 
                      label={status.toUpperCase()} 
                      color={statusColor} 
                      size="small" 
                      variant="filled"
                      sx={{ fontWeight: 600 }}
                    />
                    <Typography variant="caption" color="text.secondary">
                      {schedule.id.substring(0, 8)}...
                    </Typography>
                  </Box>
                  
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 1.5 }}>
                    <ScheduleIcon color="action" fontSize="small" />
                    <Typography variant="body1" sx={{ fontWeight: 600 }}>
                      {formatDateTime(schedule.departureTime)}
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 2 }}>
                    <DirectionsBus color="action" fontSize="small" />
                    <Typography variant="body2">
                      Bus ID: {busId.substring(0, 8)}...
                    </Typography>
                  </Box>

                  <Divider sx={{ my: 1.5, borderColor: 'rgba(255,255,255,0.05)' }} />

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="body2" color="text.secondary">
                      Current Stop:
                    </Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600, color: theme.palette.primary.light }}>
                      {schedule.currentStop || 'Ready to Start'}
                    </Typography>
                  </Box>
                  
                </CardContent>
              </Card>
            </Grid>
          );
        })}
      </Grid>

      {/* Action Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleCloseMenu}
      >
        <MenuItem onClick={handleCancelSchedule} sx={{ color: theme.palette.error.main }}>
          <ListItemIcon><Block fontSize="small" sx={{ color: 'inherit' }} /></ListItemIcon>
          Cancel Schedule
        </MenuItem>
      </Menu>

      {/* Form Dialog */}
      <ScheduleFormDialog
        open={dialogOpen}
        onClose={handleCloseDialog}
        onSubmit={handleSubmit}
      />
    </Box>
  );
};
