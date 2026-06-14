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
import { format, isValid } from 'date-fns';

/**
 * Admin Seat Management Panel
 * Allows blocking seats, marking VIPs, and viewing passenger info
 */
const AdminSeatManager = ({ rideId, layoutType, open, onClose }) => {
  const { seats, loading } = useSeatMap(rideId);
  const [selectedSeat, setSelectedSeat] = useState(null);
  const [initializing, setInitializing] = useState(false);

  // Relocation Mode States
  const [relocatingSeat, setRelocatingSeat] = useState(null);
  const [relocatingStatus, setRelocatingStatus] = useState('idle'); // idle | error
  const [relocationErrorMsg, setRelocationErrorMsg] = useState('');

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
    if (relocatingSeat) {
      if (seat.status !== 'available' || seat.type === 'driver') {
        setRelocatingStatus('error');
        setRelocationErrorMsg(`Seat ${seat.seatNumber} is not available. Please choose an available seat.`);
        return;
      }
      try {
        const res = await relocateSeat(rideId, relocatingSeat.seatNumber, seat.seatNumber, relocatingSeat);
        if (res.success) {
          setRelocatingSeat(null);
          setRelocatingStatus('idle');
          setRelocationErrorMsg('');
          setSelectedSeat(null);
        } else {
          setRelocatingStatus('error');
          setRelocationErrorMsg(res.error || 'Failed to move seat.');
        }
      } catch (err) {
        setRelocatingStatus('error');
        setRelocationErrorMsg(err.message || 'An error occurred.');
      }
    } else {
      setSelectedSeat(seat);
    }
  };

  const handleBlockSeat = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { status: 'booked', type: 'blocked' });
    setSelectedSeat(null);
  };

  const handleUnblockSeat = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { status: 'available', type: 'standard' });
    setSelectedSeat(null);
  };

  const handleMarkVIP = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { type: 'vip' });
    setSelectedSeat(null);
  };

  const handleRemoveVIP = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { type: 'standard' });
    setSelectedSeat(null);
  };

  const handleMakeAvailable = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { status: 'available', type: 'standard' });
    setSelectedSeat(null);
  };

  const isBlocked = selectedSeat && selectedSeat.status === 'booked' && selectedSeat.type === 'blocked';
  const isVip = selectedSeat && selectedSeat.type === 'vip';
  const isBooked = selectedSeat && ['reserved', 'booked', 'occupied', 'sold'].includes(selectedSeat.status) && selectedSeat.type !== 'blocked';

  const formatDateTime = (dateValue) => {
    if (!dateValue) return 'N/A';
    try {
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
               selectedSeats={relocatingSeat ? [relocatingSeat.seatNumber] : (selectedSeat ? [selectedSeat.seatNumber] : [])}
               onSeatSelect={handleSeatClick}
             />
          </Box>

          {/* Right: Actions */}
          <Box sx={{ flex: 1, p: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>Seat Actions</Typography>
            
            {relocatingSeat ? (
              // Relocation mode UI
              <Stack spacing={2}>
                <Box sx={(theme) => ({
                  p: 2.5,
                  borderRadius: '12px',
                  border: '1.5px solid rgba(230, 141, 51, 0.45)',
                  borderLeft: '4px solid #E68D33',
                  background: theme.palette.mode === 'dark' ? 'rgba(30, 41, 59, 0.4)' : 'rgba(230, 141, 51, 0.06)',
                  position: 'relative',
                })}>
                  <Typography variant="subtitle2" sx={{ fontWeight: 700, color: '#E68D33' }}>
                    Relocating Mode Active
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    Moving booking from **Seat {relocatingSeat.seatNumber}**.
                  </Typography>
                  <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
                    Please click on any available seat on the map to place the booking there.
                  </Typography>
                </Box>
                
                {relocatingStatus === 'error' && (
                  <Box sx={{ p: 2, bgcolor: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.3)', borderRadius: 2 }}>
                    <Typography variant="caption" color="error">{relocationErrorMsg}</Typography>
                  </Box>
                )}

                <Button 
                  fullWidth 
                  variant="outlined" 
                  onClick={() => {
                    setRelocatingSeat(null);
                    setRelocatingStatus('idle');
                    setRelocationErrorMsg('');
                  }}
                >
                  Cancel Move
                </Button>
              </Stack>
            ) : selectedSeat ? (
              // Regular seat actions UI
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
                    {isBooked && (
                      <Box sx={{ mt: 1.5, p: 1.5, bgcolor: 'rgba(230, 141, 51, 0.08)', borderRadius: 2, border: '1px solid rgba(230, 141, 51, 0.2)' }}>
                        <Typography variant="caption" display="block">
                          <strong>Booked By:</strong> {selectedSeat.passengerId || 'Unknown'}
                        </Typography>
                        <Typography variant="caption" display="block">
                          <strong>Booked At:</strong> {formatDateTime(selectedSeat.bookedAt)}
                        </Typography>
                      </Box>
                    )}
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

                {/* Conditional Actions depending on Seat State */}
                {isBlocked && (
                  <Button fullWidth variant="contained" color="success" onClick={handleUnblockSeat}>
                    Undo Block (Make Available)
                  </Button>
                )}

                {isVip && (
                  <Button fullWidth variant="contained" color="success" onClick={handleRemoveVIP}>
                    Undo VIP (Set to Standard)
                  </Button>
                )}

                {isBooked && (
                  <>
                    <Button 
                      fullWidth 
                      variant="contained" 
                      color="primary"
                      onClick={() => setRelocatingSeat(selectedSeat)}
                      sx={{ 
                        background: 'linear-gradient(135deg, #E68D33, #c9731a)',
                        color: '#ffffff',
                        '&:hover': {
                          background: 'linear-gradient(135deg, #f09e48, #E68D33)',
                        }
                      }}
                    >
                      Change Booked Seat (Move)
                    </Button>
                    <Button fullWidth variant="outlined" color="error" onClick={handleMakeAvailable}>
                      Cancel Booking (Make Available)
                    </Button>
                  </>
                )}

                {!isBlocked && !isVip && !isBooked && (
                  <>
                    <Button fullWidth variant="contained" color="error" onClick={handleBlockSeat}>
                      Block Seat (Maintenance)
                    </Button>
                    <Button fullWidth variant="contained" color="warning" onClick={handleMarkVIP}>
                      Set as VIP Seat
                    </Button>
                  </>
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
        <Button onClick={onClose}>Close Manager</Button>
      </DialogActions>
    </Dialog>
  );
};

export default AdminSeatManager;
