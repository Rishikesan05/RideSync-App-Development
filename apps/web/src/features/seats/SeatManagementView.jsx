import { useState } from 'react';
import { 
  Box, 
  Typography, 
  Grid, 
  Card, 
  CardContent, 
  Button, 
  Chip, 
  CircularProgress,
  Alert
} from '@mui/material';
import { EventSeat, DirectionsBus, AccessTime } from '@mui/icons-material';
import { useSchedulesList } from '../../api/schedules';
import { useBusesFirestore } from '../fleet/useBusesFirestore';
import AdminSeatManager from './AdminSeatManager';
import { format, isValid } from 'date-fns';

const SeatManagementView = () => {
  const { data: schedulesResponse, isLoading: isLoadingSchedules, error: schedulesError } = useSchedulesList();
  const { buses, loading: isLoadingBuses } = useBusesFirestore();
  const [selectedRide, setSelectedRide] = useState(null);

  const isLoading = isLoadingSchedules || isLoadingBuses;
  const error = schedulesError;

  if (isLoading) return <Box sx={{ display: 'flex', justifyContent: 'center', p: 5 }}><CircularProgress /></Box>;
  if (error) return <Alert severity="error">{error.message}</Alert>;

  const schedulesData = schedulesResponse?.data || schedulesResponse?.schedules || schedulesResponse || [];
  const schedules = Array.isArray(schedulesData) ? schedulesData : [];
  
  const activeSchedules = schedules
    .filter(s => s && (s.status === 'scheduled' || s.status === 'active' || !s.status))
    .map(s => {
      // Find bus capacity if missing from schedule record
      const bus = buses.find(b => b.id === s.busId);
      return {
        ...s,
        capacity: s.capacity || bus?.capacity || 54,
        busPlateNumber: s.busPlateNumber || bus?.plateNumber || 'N/A'
      };
    })
    .sort((a, b) => {
      const dateA = new Date(a.updatedAt || a.createdAt || a.departureTime || 0);
      const dateB = new Date(b.updatedAt || b.createdAt || b.departureTime || 0);
      return dateB - dateA;
    });

  const formatDateTime = (dateValue) => {
    if (!dateValue) return 'N/A';
    try {
      // Handle various Firestore Timestamp formats or ISO string
      let date;
      if (dateValue._seconds) {
        date = new Date(dateValue._seconds * 1000);
      } else if (dateValue.seconds) {
        date = new Date(dateValue.seconds * 1000);
      } else {
        date = new Date(dateValue);
      }
      return isValid(date) ? format(date, 'MMM dd, yyyy - hh:mm a') : 'Invalid Time';
    } catch {
      return 'N/A';
    }
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 800 }}>Seat Management</Typography>
        <Typography variant="body1" color="text.secondary">
          Monitor and manage bus occupancy in real-time
        </Typography>
      </Box>

      {activeSchedules.length === 0 ? (
        <Alert severity="info">No active schedules found to manage seats.</Alert>
      ) : (
        <Grid container spacing={3}>
          {activeSchedules.map((schedule) => (
            <Grid item xs={12} md={6} lg={4} key={schedule.id}>
              <Card sx={(theme) => ({ 
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
                }
              })}>
                <CardContent sx={{ p: 3 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                    <Chip 
                      label={(schedule.status || 'PENDING').toUpperCase()} 
                      size="small" 
                      color={schedule.status === 'active' ? 'success' : 'primary'}
                      sx={{ fontWeight: 700 }}
                    />
                    <Typography variant="caption" color="text.secondary">#{schedule.id?.substring(0, 6)}</Typography>
                  </Box>

                  <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>{schedule.routeName || schedule.routeId || 'Intercity Express'}</Typography>
                  
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                    <DirectionsBus fontSize="small" color="action" />
                    <Typography variant="body2">{schedule.busPlateNumber || 'No Bus Assigned'} (Capacity: {schedule.capacity || '54'})</Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                    <AccessTime fontSize="small" color="action" />
                    <Typography variant="body2">{formatDateTime(schedule.departureTime)}</Typography>
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
                      sx={(theme) => ({
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
                      })} 
                    />
                    
                    {/* Perforation Line */}
                    <Box sx={(theme) => ({ 
                      flex: 1, 
                      borderTop: `1.2px dashed ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)'}`, 
                      height: '1px', 
                      mx: 1.5
                    })} />
                    
                    {/* Right Notch */}
                    <Box 
                      className="ticket-notch"
                      sx={(theme) => ({
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
                      })} 
                    />
                  </Box>

                  <Button 
                    fullWidth 
                    variant="contained" 
                    startIcon={<EventSeat />}
                    onClick={() => setSelectedRide(schedule)}
                    sx={{ 
                      borderRadius: 2, 
                      py: 1.2,
                      fontWeight: 600,
                      background: 'linear-gradient(135deg, #E68D33, #c9731a)',
                      color: '#ffffff',
                      boxShadow: '0 4px 12px rgba(230, 141, 51, 0.2)',
                      '&:hover': {
                        background: 'linear-gradient(135deg, #f09e48, #E68D33)',
                        boxShadow: '0 6px 16px rgba(230, 141, 51, 0.3)',
                      }
                    }}
                  >
                    Manage Seat Map
                  </Button>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {selectedRide && (
        <AdminSeatManager
          rideId={selectedRide.id}
          layoutType={String(selectedRide.capacity || '54')}
          open={!!selectedRide}
          onClose={() => setSelectedRide(null)}
        />
      )}
    </Box>
  );
};

export default SeatManagementView;
