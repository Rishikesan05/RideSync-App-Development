import { useState } from 'react';
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
  Block, 
  DirectionsBus,
  Schedule as ScheduleIcon,
  CheckCircle,
  Delete
} from '@mui/icons-material';
// Removed unused REST hooks
import { useSchedulesFirestore } from './useSchedulesFirestore';
import { ScheduleFormDialog } from './ScheduleFormDialog';
import { format, isValid } from 'date-fns';
import { collection, addDoc, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../../api/firebase';

export const SchedulesView = () => {
  const theme = useTheme();
  // Real-time Firestore listener — replaces React Query polling
  const { schedules, loading: isLoading, error } = useSchedulesFirestore();


  const [dialogOpen, setDialogOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);
  const [menuScheduleId, setMenuScheduleId] = useState(null);

  const formatDateTime = (timeStr) => {
    try {
      const date = new Date(timeStr);
      return isValid(date) ? format(date, 'MMM dd, yyyy - hh:mm a') : 'Invalid Date';
    } catch {
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
      const scheduleRef = doc(db, 'schedules', scheduleId);
      await updateDoc(scheduleRef, { status: 'cancelled' });
    } catch (e) {
      console.error('Failed to cancel schedule', e);
    }
  };

  const handleActivateSchedule = async () => {
    const scheduleId = menuScheduleId;
    handleCloseMenu();
    try {
      const scheduleRef = doc(db, 'schedules', scheduleId);
      await updateDoc(scheduleRef, { status: 'active' });
    } catch (e) {
      console.error('Failed to activate schedule', e);
    }
  };

  const handleDeleteSchedule = async () => {
    const scheduleId = menuScheduleId;
    handleCloseMenu();
    try {
      const scheduleRef = doc(db, 'schedules', scheduleId);
      await deleteDoc(scheduleRef);
    } catch (e) {
      console.error('Failed to delete schedule', e);
    }
  };

  const handleSubmit = async (formData) => {
    try {
      const schedulesRef = collection(db, 'schedules');
      await addDoc(schedulesRef, formData);
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

  const selectedMenuSchedule = schedules.find(s => s.id === menuScheduleId);
  const menuScheduleStatus = selectedMenuSchedule?.status || '';

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
          const statusColor = getStatusColor(status);
          const colorMain = theme.palette[statusColor]?.main || theme.palette.primary.main;
          
          return (
            <Grid item xs={12} md={6} lg={4} key={schedule.id}>
              <Card sx={{ 
                height: '100%', 
                borderRadius: '16px',
                border: `1.5px solid ${colorMain}40`,
                borderTop: `4px solid ${colorMain}`,
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
                opacity: status === 'cancelled' ? 0.6 : 1,
                '&:hover': {
                  transform: 'translateY(-6px)',
                  boxShadow: theme.palette.mode === 'dark'
                    ? `0 16px 28px -10px ${colorMain}40, 0 8px 30px rgba(0,0,0,0.4)`
                    : `0 16px 24px -10px ${colorMain}2e, 0 6px 20px rgba(0,0,0,0.06)`,
                  borderColor: colorMain,
                  '& .ticket-notch': {
                    borderColor: colorMain,
                  }
                }
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
                      variant={status === 'cancelled' ? 'outlined' : 'filled'}
                      sx={{ fontWeight: 600 }}
                    />
                    <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 'bold' }}>
                      {schedule.routeName || `Route: ${schedule.routeId?.substring(0, 8)}`}
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
                      Plate: {schedule.busPlateNumber || 'N/A'}
                    </Typography>
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
                        border: `1.5px solid ${colorMain}40`,
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
                        border: `1.5px solid ${colorMain}40`,
                        borderRightColor: 'transparent',
                        borderTopColor: 'transparent',
                        borderBottomColor: 'transparent',
                        zIndex: 2,
                        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                      }} 
                    />
                  </Box>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="body2" color="text.secondary">
                      Operator:
                    </Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600, color: theme.palette.primary.light }}>
                      {schedule.operatorId || schedule.opId || 'Unassigned'}
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
        {menuScheduleStatus !== 'active' && (
          <MenuItem onClick={handleActivateSchedule} sx={{ color: theme.palette.success.main }}>
            <ListItemIcon><CheckCircle fontSize="small" sx={{ color: 'inherit' }} /></ListItemIcon>
            Activate Schedule
          </MenuItem>
        )}
        {menuScheduleStatus !== 'cancelled' && (
          <MenuItem onClick={handleCancelSchedule} sx={{ color: theme.palette.warning.main }}>
            <ListItemIcon><Block fontSize="small" sx={{ color: 'inherit' }} /></ListItemIcon>
            Cancel Schedule
          </MenuItem>
        )}
        <MenuItem onClick={handleDeleteSchedule} sx={{ color: theme.palette.error.main }}>
          <ListItemIcon><Delete fontSize="small" sx={{ color: 'inherit' }} /></ListItemIcon>
          Delete Schedule
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
