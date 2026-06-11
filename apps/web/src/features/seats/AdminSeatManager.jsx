import React, { useState, useEffect } from 'react';
import { 
  Dialog, 
  DialogTitle, 
  DialogContent, 
  DialogActions, 
  Button, 
  Box, 
  Typography,
  Chip,
  Stack,
  Divider,
  Paper
} from '@mui/material';
import BusSeatMap from './BusSeatMap';
import { bookSeat, updateSeatMeta, initializeRideSeats } from './SeatService';
import { useSeatMap } from './useSeatMap';

/**
 * Admin Seat Management Panel
 * Allows blocking seats, marking VIPs, and viewing passenger info
 */
const AdminSeatManager = ({ rideId, layoutType, open, onClose }) => {
  const { seats, loading } = useSeatMap(rideId);
  const [selectedSeat, setSelectedSeat] = useState(null);
  const [initializing, setInitializing] = useState(false);

  // Automatically initialize seats if they don't exist
  useEffect(() => {
    if (open && !loading && seats.length === 0 && !initializing) {
      const init = async () => {
        setInitializing(true);
        try {
          await initializeRideSeats(rideId, layoutType);
        } catch (err) {
          console.error("Failed to auto-init seats:", err);
        } finally {
          setInitializing(false);
        }
      };
      init();
    }
  }, [open, loading, seats.length, rideId, layoutType, initializing]);

  const handleSeatClick = (seat) => {
    setSelectedSeat(seat);
  };

  const handleBlockSeat = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { status: 'booked', type: 'blocked' });
    setSelectedSeat(null);
  };

  const handleMarkVIP = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { type: 'vip' });
    setSelectedSeat(null);
  };

  const handleMakeAvailable = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { status: 'available', type: 'standard' });
    setSelectedSeat(null);
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle sx={{ fontWeight: 800 }}>
        Admin: Seat Management
      </DialogTitle>
      <DialogContent dividers>
        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 4 }}>
          {/* Left: Live Map */}
          <Box sx={{ flex: 1 }}>
             <BusSeatMap 
               rideId={rideId} 
               layoutType={layoutType} 
               selectedSeats={selectedSeat ? [selectedSeat.seatNumber] : []}
               onSeatSelect={handleSeatClick}
             />
          </Box>

          {/* Right: Actions */}
          <Box sx={{ flex: 1, p: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>Seat Actions</Typography>
            {selectedSeat ? (
              <Stack spacing={2}>
                <Box sx={(theme) => ({
                  p: 2,
                  borderRadius: '12px',
                  border: '1.5px solid rgba(230, 141, 51, 0.25)',
                  borderLeft: '4px solid #E68D33',
                  background: theme.palette.mode === 'dark' ? 'rgba(30, 41, 59, 0.4)' : 'rgba(255, 255, 255, 0.5)',
                  position: 'relative',
                  overflow: 'visible'
                })}>
                  {/* Top: Seat Number & Status */}
                  <Box>
                    <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>Selected Seat: {selectedSeat.seatNumber}</Typography>
                    <Typography variant="caption" color="text.secondary">Current Status: {selectedSeat.status}</Typography>
                  </Box>
                  
                  {/* Ticket Divider & Cutout Notches */}
                  <Box sx={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between', 
                    mx: -2, 
                    my: 1.5,
                    height: '16px',
                    position: 'relative'
                  }}>
                    {/* Left Notch */}
                    <Box 
                      className="ticket-notch"
                      sx={(theme) => ({
                        position: 'absolute',
                        left: '-8px',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        width: '16px',
                        height: '16px',
                        borderRadius: '50%',
                        backgroundColor: theme.palette.background.paper,
                        border: '1.5px solid rgba(230, 141, 51, 0.25)',
                        borderLeftColor: 'transparent',
                        borderTopColor: 'transparent',
                        borderBottomColor: 'transparent',
                        zIndex: 2,
                      })} 
                    />
                    
                    {/* Perforation Line */}
                    <Box sx={(theme) => ({ 
                      flex: 1, 
                      borderTop: `1px dashed ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)'}`, 
                      height: '1px', 
                      mx: 1 
                    })} />
                    
                    {/* Right Notch */}
                    <Box 
                      className="ticket-notch"
                      sx={(theme) => ({
                        position: 'absolute',
                        right: '-8px',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        width: '16px',
                        height: '16px',
                        borderRadius: '50%',
                        backgroundColor: theme.palette.background.paper,
                        border: '1.5px solid rgba(230, 141, 51, 0.25)',
                        borderRightColor: 'transparent',
                        borderTopColor: 'transparent',
                        borderBottomColor: 'transparent',
                        zIndex: 2,
                      })} 
                    />
                  </Box>

                  {/* Bottom: Seat Type Tag */}
                  <Box>
                    <Chip 
                      label={(selectedSeat.type || 'Standard').toUpperCase()} 
                      size="small" 
                      sx={{ 
                        fontWeight: 600, 
                        fontSize: '0.7rem',
                        bgcolor: 'rgba(230, 141, 51, 0.12)', 
                        color: '#E68D33', 
                        border: '1px solid rgba(230, 141, 51, 0.25)' 
                      }} 
                    />
                  </Box>
                </Box>

                <Button fullWidth variant="contained" color="error" onClick={handleBlockSeat}>
                  Block Seat (Maintenance)
                </Button>
                <Button fullWidth variant="contained" color="warning" onClick={handleMarkVIP}>
                  Set as VIP Seat
                </Button>
                <Button fullWidth variant="outlined" onClick={handleMakeAvailable}>
                  Reset to Available
                </Button>
              </Stack>
            ) : (
              <Box sx={{ p: 4, textAlign: 'center', border: '2px dashed #E2E8F0', borderRadius: 2 }}>
                 <Typography color="text.secondary">Select a seat on the map to manage</Typography>
              </Box>
            )}

            <Divider sx={{ my: 3 }} />
            
            <Typography variant="subtitle2" sx={{ mb: 1 }}>Bus Info</Typography>
            <Stack spacing={2}>
              <Stack direction="row" spacing={1}>
                 <Chip label={`Layout: ${layoutType}`} />
                 <Chip label={`Ride ID: ${rideId.substring(0, 8)}...`} />
              </Stack>
              
              <Button 
                variant="outlined" 
                color="secondary" 
                size="small"
                onClick={async () => {
                  if(window.confirm("Reset entire layout to standard? All bookings for this ride will be lost!")) {
                    await initializeRideSeats(rideId, layoutType);
                  }
                }}
              >
                Reset to Standard Layout
              </Button>
            </Stack>
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Close Manager</Button>
      </DialogActions>
    </Dialog>
  );
};

export default AdminSeatManager;
