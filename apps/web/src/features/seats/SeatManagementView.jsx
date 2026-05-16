import React, { useState } from 'react';
import { 
  Box, 
  Typography, 
  Grid, 
  Card, 
  CardContent, 
  Button, 
  Chip, 
  Divider,
  CircularProgress,
  Alert
} from '@mui/material';
import { EventSeat, DirectionsBus, AccessTime } from '@mui/icons-material';
import { useSchedulesList } from '../../api/schedules';
import { useBusesList } from '../../api/buses';
import AdminSeatManager from './AdminSeatManager';
import { format, isValid } from 'date-fns';

const SeatManagementView = () => {
  const { data: schedulesResponse, isLoading: isLoadingSchedules, error: schedulesError } = useSchedulesList();
  const { data: busesResponse, isLoading: isLoadingBuses } = useBusesList();
  const [selectedRide, setSelectedRide] = useState(null);

  const isLoading = isLoadingSchedules || isLoadingBuses;
  const error = schedulesError;

  if (isLoading) return <Box sx={{ display: 'flex', justifyContent: 'center', p: 5 }}><CircularProgress /></Box>;
  if (error) return <Alert severity="error">{error.message}</Alert>;

  const schedulesData = schedulesResponse?.data || schedulesResponse?.schedules || schedulesResponse || [];
  const schedules = Array.isArray(schedulesData) ? schedulesData : [];
  
  const busesData = busesResponse?.data || busesResponse?.buses || busesResponse || [];
  const buses = Array.isArray(busesData) ? busesData : [];
  
  const activeSchedules = schedules.filter(s => s && (s.status === 'scheduled' || s.status === 'active' || !s.status)).map(s => {
    // Find bus capacity if missing from schedule record
    const bus = buses.find(b => b.id === s.busId);
    return {
      ...s,
      capacity: s.capacity || bus?.capacity || 54
    };
  });

  const formatTime = (dateValue) => {
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
      return isValid(date) ? format(date, 'hh:mm a') : 'Invalid Time';
    } catch (e) {
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
              <Card sx={{ 
                borderRadius: 3, 
                border: '1px solid rgba(255,255,255,0.05)',
                transition: 'transform 0.2s',
                '&:hover': { transform: 'translateY(-4px)' }
              }}>
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
                    <Typography variant="body2">{schedule.busId || 'No Bus Assigned'} (Capacity: {schedule.capacity || '54'})</Typography>
                  </Box>

                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
                    <AccessTime fontSize="small" color="action" />
                    <Typography variant="body2">{formatTime(schedule.departureTime)}</Typography>
                  </Box>

                  <Divider sx={{ my: 2 }} />

                  <Button 
                    fullWidth 
                    variant="contained" 
                    startIcon={<EventSeat />}
                    onClick={() => setSelectedRide(schedule)}
                    sx={{ borderRadius: 2, py: 1.2 }}
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
