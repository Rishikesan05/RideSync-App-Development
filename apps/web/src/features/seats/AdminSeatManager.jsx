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
import { bookSeat, updateSeatMeta, initializeRideSeats, relocateSeat } from './SeatService';
import { useSeatMap } from './useSeatMap';

/**
 * Admin Seat Management Panel
 * Allows blocking seats, marking VIPs, and viewing passenger info
 */
const AdminSeatManager = ({ rideId, layoutType, open, onClose }) => {
  const { seats, loading } = useSeatMap(rideId);
  const [selectedSeat, setSelectedSeat] = useState(null);
  const [initializing, setInitializing] = useState(false);
  const [isRelocating, setIsRelocating] = useState(false);
  const [seatToRelocate, setSeatToRelocate] = useState(null);

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

  const handleSeatClick = async (seat) => {
    if (isRelocating) {
      if (seat.status === 'available' && seat.type !== 'driver') {
        const confirmMove = window.confirm(`Move booking from Seat ${seatToRelocate.seatNumber} to Seat ${seat.seatNumber}?`);
        if (confirmMove) {
          const res = await relocateSeat(rideId, seatToRelocate.seatNumber, seat.seatNumber, seatToRelocate);
          if (res.success) {
            alert(`Successfully relocated booking to Seat ${seat.seatNumber}.`);
          } else {
            alert(`Failed to relocate booking: ${res.error}`);
          }
          setIsRelocating(false);
          setSeatToRelocate(null);
          setSelectedSeat(null);
        }
      } else {
        alert("Please select an available seat to complete the move.");
      }
    } else {
      setSelectedSeat(seat);
    }
  };

  const handleStartRelocate = () => {
    if (!selectedSeat) return;
    setSeatToRelocate(selectedSeat);
    setIsRelocating(true);
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

  const handleClose = () => {
    setIsRelocating(false);
    setSeatToRelocate(null);
    setSelectedSeat(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} fullWidth maxWidth="md">
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
            {isRelocating ? (
              <Box sx={{ p: 3, textAlign: 'center', border: '2px dashed #E68D33', borderRadius: 2, bgcolor: 'rgba(230, 141, 51, 0.05)' }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1, color: '#E68D33' }}>
                  Relocating Seat {seatToRelocate.seatNumber}
                </Typography>
                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 2 }}>
                  Click on an available seat on the map to move this booking.
                </Typography>
                <Button size="small" variant="outlined" color="warning" onClick={() => { setIsRelocating(false); setSeatToRelocate(null); setSelectedSeat(null); }}>
                  Cancel Move
                </Button>
              </Box>
            ) : selectedSeat ? (
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

                {selectedSeat.type === 'blocked' ? (
                  <Button fullWidth variant="contained" color="success" onClick={handleMakeAvailable} sx={{ fontWeight: 600 }}>
                    Unblock Seat (Make Available)
                  </Button>
                ) : selectedSeat.type === 'vip' ? (
                  <Stack spacing={1.5}>
                    <Button fullWidth variant="outlined" color="warning" onClick={handleMakeAvailable} sx={{ fontWeight: 600 }}>
                      Remove VIP Status (Set to Standard)
                    </Button>
                    {selectedSeat.status !== 'booked' && selectedSeat.status !== 'reserved' && (
                      <Button fullWidth variant="contained" color="error" onClick={handleBlockSeat}>
                        Block Seat (Maintenance)
                      </Button>
                    )}
                  </Stack>
                ) : selectedSeat.status === 'booked' || selectedSeat.status === 'reserved' ? (
                  <Stack spacing={1.5}>
                    <Button 
                      fullWidth 
                      variant="contained" 
                      onClick={handleStartRelocate}
                      sx={{ 
                        fontWeight: 600,
                        background: 'linear-gradient(135deg, #E68D33, #c9731a)',
                        color: '#ffffff',
                        '&:hover': {
                          background: 'linear-gradient(135deg, #f09e48, #E68D33)',
                        }
                      }}
                    >
                      Move Booking (Change Seat)
                    </Button>
                    <Button fullWidth variant="outlined" color="error" onClick={handleMakeAvailable} sx={{ fontWeight: 600 }}>
                      Cancel Booking (Make Available)
                    </Button>
                  </Stack>
                ) : (
                  <Stack spacing={1.5}>
                    <Button fullWidth variant="contained" color="error" onClick={handleBlockSeat}>
                      Block Seat (Maintenance)
                    </Button>
                    <Button fullWidth variant="contained" color="warning" onClick={handleMarkVIP}>
                      Set as VIP Seat
                    </Button>
                  </Stack>
                )}
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
        <Button onClick={handleClose}>Close Manager</Button>
      </DialogActions>
    </Dialog>
  );
};

export default AdminSeatManager;
