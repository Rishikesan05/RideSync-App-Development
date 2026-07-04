import { useState, useEffect } from 'react';
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
  Select,
  MenuItem,
  FormControl,
  InputLabel
} from '@mui/material';
import {
  CallSplit as CallSplitIcon,
  CheckCircleOutline as CheckCircleOutlineIcon,
  ConfirmationNumber as ConfirmationNumberIcon,
  Person as PersonIcon,
  TripOrigin as TripOriginIcon,
  ArrowForward as ArrowForwardIcon,
} from '@mui/icons-material';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../../api/firebase';
import BusSeatMap from './BusSeatMap';
import { updateSeatMeta, initializeRideSeats, relocateSeat } from './SeatService';
import { useSeatMap } from './useSeatMap';
import { format, isValid } from 'date-fns';

/**
 * Admin Seat Management Panel
 * Allows blocking seats, marking VIPs, and viewing passenger info.
 * Supports fare-breakdown seats: seats shared by multiple passengers on different journey legs.
 */
const AdminSeatManager = ({ rideId, layoutType, open, onClose }) => {
  const { seats, loading } = useSeatMap(rideId);
  const [selectedSeat, setSelectedSeat] = useState(null);
  const [initializing, setInitializing] = useState(false);

  // Relocation Mode States
  const [relocatingSeat, setRelocatingSeat] = useState(null);
  const [relocatingStatus, setRelocatingStatus] = useState('idle'); // idle | error
  const [relocationErrorMsg, setRelocationErrorMsg] = useState('');
  const [routeStops, setRouteStops] = useState([]);

  useEffect(() => {
    if (!rideId) return;
    const fetchRouteStops = async () => {
      try {
        const scheduleRef = doc(db, 'schedules', rideId);
        const scheduleSnap = await getDoc(scheduleRef);
        if (scheduleSnap.exists()) {
          const routeId = scheduleSnap.data().routeId;
          if (routeId) {
            const routeRef = doc(db, 'routes', routeId);
            const routeSnap = await getDoc(routeRef);
            if (routeSnap.exists()) {
              const routeData = routeSnap.data();
              let stops = [];
              if (routeData.origin) stops.push(routeData.origin.split(',')[0].trim());
              else if (routeData.startPoint) stops.push(routeData.startPoint.split(',')[0].trim());
              
              if (routeData.stops && Array.isArray(routeData.stops)) {
                routeData.stops.forEach(s => {
                  if(s.name) stops.push(s.name.split(',')[0].trim());
                });
              }
              
              if (routeData.destination) stops.push(routeData.destination.split(',')[0].trim());
              else if (routeData.endPoint) stops.push(routeData.endPoint.split(',')[0].trim());
              
              setRouteStops([...new Set(stops)]);
            }
          }
        }
      } catch(e) {
        console.error("Failed to fetch route stops", e);
      }
    };
    fetchRouteStops();
  }, [rideId]);

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

  const handleStopChange = async (field, value) => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { [field]: value });
    setSelectedSeat(prev => ({ ...prev, [field]: value }));
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

  const handleMakeAvailable = async () => {
    if (!selectedSeat) return;
    await updateSeatMeta(rideId, selectedSeat.seatNumber, { status: 'available', type: 'standard' });
    setSelectedSeat(null);
  };

  const isBlocked = selectedSeat && selectedSeat.status === 'booked' && selectedSeat.type === 'blocked';
  const isBooked = selectedSeat && ['reserved', 'booked', 'occupied', 'sold'].includes(selectedSeat.status) && selectedSeat.type !== 'blocked';

  // Detect fare-breakdown: seat stored with multiple segments
  const rawSegments = selectedSeat?.segments;
  const segments = Array.isArray(rawSegments) && rawSegments.length > 0
    ? rawSegments
    : selectedSeat
      ? [{
          origin: selectedSeat.origin || selectedSeat.pickup || 'Unknown',
          destination: selectedSeat.destination || selectedSeat.dropoff || 'Unknown',
          passengerId: selectedSeat.passengerId || 'Unknown',
          ticketCode: selectedSeat.ticketCode || null,
        }]
      : [];
  const isFareBreakdown = Array.isArray(rawSegments) && rawSegments.length > 1;

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

  // Accent colours for fare-breakdown vs normal
  const accentColor = isFareBreakdown ? '#6366F1' : '#E68D33';
  const accentAlpha = (a) => isFareBreakdown ? `rgba(99,102,241,${a})` : `rgba(230,141,51,${a})`;

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
               routeStops={routeStops}
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
                {/* ── Seat header card ── */}
                <Box sx={(theme) => ({
                  p: 2,
                  borderRadius: '12px',
                  border: `1.5px solid ${accentAlpha(0.25)}`,
                  borderLeft: `4px solid ${accentColor}`,
                  background: theme.palette.mode === 'dark' ? 'rgba(30, 41, 59, 0.4)' : 'rgba(255, 255, 255, 0.5)',
                  position: 'relative',
                  overflow: 'visible'
                })}>
                  {/* Top: Seat Number & booking type */}
                  <Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5, flexWrap: 'wrap' }}>
                      <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
                        Selected Seat: {selectedSeat.seatNumber}
                      </Typography>
                      {/* Booking type chip */}
                      <Chip
                        icon={isFareBreakdown
                          ? <CallSplitIcon sx={{ fontSize: '13px !important' }} />
                          : <CheckCircleOutlineIcon sx={{ fontSize: '13px !important' }} />}
                        label={isFareBreakdown ? 'FARE BREAKDOWN' : 'NORMAL BOOKING'}
                        size="small"
                        sx={{
                          fontWeight: 800,
                          fontSize: '0.65rem',
                          letterSpacing: 0.3,
                          bgcolor: isFareBreakdown ? 'rgba(99,102,241,0.12)' : 'rgba(20,184,166,0.12)',
                          color: isFareBreakdown ? '#6366F1' : '#0d9488',
                          border: `1px solid ${isFareBreakdown ? 'rgba(99,102,241,0.35)' : 'rgba(20,184,166,0.35)'}`,
                          '& .MuiChip-icon': { color: 'inherit' },
                        }}
                      />
                    </Box>
                    <Typography variant="caption" color="text.secondary">
                      Current Status: {selectedSeat.status}
                    </Typography>

                    {isFareBreakdown && (
                      <Typography variant="caption" display="block" sx={{ mt: 0.5, fontStyle: 'italic', color: '#6366F1' }}>
                        {segments.length} journeys share this seat
                      </Typography>
                    )}
                  </Box>

                  {isBooked && (
                    <Box sx={{ mt: 1.5 }}>
                      {/* ── Journey segment cards ── */}
                      {segments.map((seg, idx) => (
                        <JourneySegmentCard
                          key={idx}
                          index={idx}
                          total={segments.length}
                          segment={seg}
                          isFareBreakdown={isFareBreakdown}
                          accentColor={accentColor}
                          accentAlpha={accentAlpha}
                        />
                      ))}

                      {/* Last booked timestamp */}
                      <Typography variant="caption" display="block" sx={{ mt: 1, mb: 1.5, color: 'text.secondary' }}>
                        <strong>Last Updated:</strong> {formatDateTime(selectedSeat.updatedAt || selectedSeat.bookedAt)}
                      </Typography>

                      {/* Stop pickers (admin override) */}
                      <FormControl fullWidth size="small" sx={{ mb: 1.5 }}>
                        <InputLabel sx={{ fontSize: '0.8rem' }}>Boarding Point</InputLabel>
                        <Select
                          value={selectedSeat.origin || selectedSeat.pickup || ''}
                          label="Boarding Point"
                          onChange={(e) => handleStopChange('origin', e.target.value)}
                          sx={{ fontSize: '0.8rem' }}
                        >
                          <MenuItem value=""><em>Unknown</em></MenuItem>
                          {routeStops.map((stop, idx) => (
                            <MenuItem key={`orig-${idx}`} value={stop}>{stop}</MenuItem>
                          ))}
                        </Select>
                      </FormControl>

                      <FormControl fullWidth size="small">
                        <InputLabel sx={{ fontSize: '0.8rem' }}>Drop-off Point</InputLabel>
                        <Select
                          value={selectedSeat.destination || selectedSeat.dropoff || ''}
                          label="Drop-off Point"
                          onChange={(e) => handleStopChange('destination', e.target.value)}
                          sx={{ fontSize: '0.8rem' }}
                        >
                          <MenuItem value=""><em>Unknown</em></MenuItem>
                          {routeStops.map((stop, idx) => (
                            <MenuItem key={`dest-${idx}`} value={stop}>{stop}</MenuItem>
                          ))}
                        </Select>
                      </FormControl>
                    </Box>
                  )}
                  
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
                        border: `1.5px solid ${accentAlpha(0.25)}`,
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
                        border: `1.5px solid ${accentAlpha(0.25)}`,
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
                        bgcolor: accentAlpha(0.12), 
                        color: accentColor, 
                        border: `1px solid ${accentAlpha(0.25)}` 
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

                {isBooked && (
                  <>
                    <Button 
                      fullWidth 
                      variant="contained" 
                      color="primary"
                      onClick={() => setRelocatingSeat(selectedSeat)}
                      sx={{ 
                        background: `linear-gradient(135deg, ${accentColor}, ${isFareBreakdown ? '#4f46e5' : '#c9731a'})`,
                        color: '#ffffff',
                        '&:hover': {
                          background: `linear-gradient(135deg, ${isFareBreakdown ? '#818cf8' : '#f09e48'}, ${accentColor})`,
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

                {!isBlocked && !isBooked && (
                  <>
                    <Button fullWidth variant="contained" color="error" onClick={handleBlockSeat}>
                      Block Seat (Maintenance)
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

/**
 * A single journey segment card shown inside the seat detail panel.
 * For fare-breakdown seats, multiple of these are stacked vertically.
 */
const JourneySegmentCard = ({ index, total, segment, isFareBreakdown, accentColor, accentAlpha }) => {
  const origin = segment.origin || segment.pickup || 'Unknown';
  const destination = segment.destination || segment.dropoff || 'Unknown';
  const passengerId = segment.passengerId || 'Unknown';
  const ticketCode = segment.ticketCode || null;

  return (
    <Box
      sx={(theme) => ({
        mb: 1.5,
        borderRadius: '10px',
        border: `1.5px solid ${accentAlpha(isFareBreakdown ? 0.4 : 0.2)}`,
        overflow: 'hidden',
        background: theme.palette.mode === 'dark' ? 'rgba(15,23,42,0.5)' : '#fff',
      })}
    >
      {/* Card header */}
      <Box
        sx={{
          px: 1.5,
          py: 0.8,
          display: 'flex',
          alignItems: 'center',
          gap: 0.8,
          bgcolor: accentAlpha(0.08),
          borderBottom: `1px solid ${accentAlpha(0.15)}`,
        }}
      >
        {isFareBreakdown
          ? <CallSplitIcon sx={{ fontSize: 14, color: accentColor }} />
          : <ConfirmationNumberIcon sx={{ fontSize: 14, color: accentColor }} />}
        <Typography variant="caption" sx={{ fontWeight: 700, color: accentColor }}>
          {isFareBreakdown ? `Journey ${index + 1} of ${total}` : 'Booking Details'}
        </Typography>
      </Box>

      {/* Card body */}
      <Box sx={{ px: 1.5, py: 1.2 }}>
        {/* Passenger */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.8, mb: 0.8 }}>
          <PersonIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
          <Typography variant="caption" color="text.secondary" sx={{ minWidth: 64 }}>Passenger</Typography>
          <Typography variant="caption" sx={{ fontWeight: 600, wordBreak: 'break-all' }}>{passengerId}</Typography>
        </Box>

        {/* Ticket */}
        {ticketCode && (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.8, mb: 0.8 }}>
            <ConfirmationNumberIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
            <Typography variant="caption" color="text.secondary" sx={{ minWidth: 64 }}>Ticket</Typography>
            <Typography variant="caption" sx={{ fontWeight: 700, color: accentColor, letterSpacing: 0.5 }}>{ticketCode}</Typography>
          </Box>
        )}

        {/* Route */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.8 }}>
          <TripOriginIcon sx={{ fontSize: 14, color: accentColor }} />
          <Typography variant="caption" color="text.secondary" sx={{ minWidth: 64 }}>Route</Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, flex: 1, minWidth: 0 }}>
            <Typography variant="caption" sx={{ fontWeight: 700, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{origin}</Typography>
            <ArrowForwardIcon sx={{ fontSize: 12, color: accentColor, flexShrink: 0 }} />
            <Typography variant="caption" sx={{ fontWeight: 700, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{destination}</Typography>
          </Box>
        </Box>
      </Box>
    </Box>
  );
};

export default AdminSeatManager;
