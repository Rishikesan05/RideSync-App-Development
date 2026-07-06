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
  InputLabel,
} from '@mui/material';
import {
  CallSplit as CallSplitIcon,
  CheckCircleOutlined as CheckCircleOutlineIcon,
  ConfirmationNumber as ConfirmationNumberIcon,
  Person as PersonIcon,
  TripOrigin as TripOriginIcon,
  LocationOn as LocationOnIcon,
  ArrowForward as ArrowForwardIcon,
  AccessTime as AccessTimeIcon,
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
 *
 * Fare-breakdown seats (shared by multiple passengers on different journey legs)
 * display stacked journey cards — one card per segment — with NO dropdowns.
 * Normal single-booking seats show one card plus admin stop-override dropdowns.
 */
const AdminSeatManager = ({ rideId, layoutType, open, onClose }) => {
  const { seats, loading } = useSeatMap(rideId);
  const [selectedSeat, setSelectedSeat] = useState(null);
  const [initializing, setInitializing] = useState(false);

  // Relocation Mode States
  const [relocatingSeat, setRelocatingSeat] = useState(null);
  const [relocatingStatus, setRelocatingStatus] = useState('idle');
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
                  if (s.name) stops.push(s.name.split(',')[0].trim());
                });
              }
              if (routeData.destination) stops.push(routeData.destination.split(',')[0].trim());
              else if (routeData.endPoint) stops.push(routeData.endPoint.split(',')[0].trim());
              setRouteStops([...new Set(stops)]);
            }
          }
        }
      } catch (e) {
        console.error('Failed to fetch route stops', e);
      }
    };
    fetchRouteStops();
  }, [rideId]);

  // Auto-init seats when none exist
  useEffect(() => {
    if (open && !loading && seats.length === 0 && !initializing) {
      const init = async () => {
        setInitializing(true);
        try {
          await initializeRideSeats(rideId, layoutType);
        } catch (err) {
          console.error('Failed to auto-init seats:', err);
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
        setRelocationErrorMsg(`Seat ${seat.seatNumber} is not available. Choose an available seat.`);
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
  const isBooked =
    selectedSeat &&
    ['reserved', 'booked', 'occupied', 'sold'].includes(selectedSeat.status) &&
    selectedSeat.type !== 'blocked';

  // ── Fare-breakdown detection ───────────────────────────────────────────────
  const rawSegments = selectedSeat?.segments;
  const isFareBreakdown = Array.isArray(rawSegments) && rawSegments.length > 1;

  // Build normalised segment list
  const segments = isFareBreakdown
    ? rawSegments.map(s => ({
        origin: s.origin || s.pickup || 'Unknown',
        destination: s.destination || s.dropoff || 'Unknown',
        passengerId: s.passengerId || 'Unknown',
        ticketCode: s.ticketCode || null,
        stopPrice: s.stopPrice ?? null,
        endPrice: s.endPrice ?? null,
      }))
    : selectedSeat
      ? [{
          origin: selectedSeat.origin || selectedSeat.pickup || 'Unknown',
          destination: selectedSeat.destination || selectedSeat.dropoff || 'Unknown',
          passengerId: selectedSeat.passengerId || 'Unknown',
          ticketCode: selectedSeat.ticketCode || null,
          stopPrice: selectedSeat.stopPrice ?? null,
          endPrice: selectedSeat.endPrice ?? null,
        }]
      : [];

  const accentColor = isFareBreakdown ? '#6366F1' : '#E68D33';
  const accentAlpha = a => isFareBreakdown ? `rgba(99,102,241,${a})` : `rgba(230,141,51,${a})`;

  const formatDateTime = (dateValue) => {
    if (!dateValue) return 'N/A';
    try {
      let date;
      if (dateValue._seconds) date = new Date(dateValue._seconds * 1000);
      else if (dateValue.seconds) date = new Date(dateValue.seconds * 1000);
      else date = new Date(dateValue);
      return isValid(date) ? format(date, 'MMM dd, yyyy - hh:mm a') : 'Invalid Time';
    } catch {
      return 'N/A';
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle sx={{ fontWeight: 800 }}>Admin: Seat Management</DialogTitle>

      <DialogContent dividers>
        <Box sx={{ display: 'flex', flexDirection: { xs: 'column', md: 'row' }, gap: 4 }}>

          {/* ── Left: Live Seat Map ── */}
          <Box sx={{ flex: 1 }}>
            <BusSeatMap
              rideId={rideId}
              layoutType={layoutType}
              selectedSeats={
                relocatingSeat
                  ? [relocatingSeat.seatNumber]
                  : selectedSeat
                    ? [selectedSeat.seatNumber]
                    : []
              }
              onSeatSelect={handleSeatClick}
              routeStops={routeStops}
            />
          </Box>

          {/* ── Right: Seat Detail Panel ── */}
          <Box sx={{ flex: 1, p: 2, overflowY: 'auto', maxHeight: 520 }}>
            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>Seat Actions</Typography>

            {/* ── Relocation mode ── */}
            {relocatingSeat ? (
              <Stack spacing={2}>
                <Box sx={(theme) => ({
                  p: 2.5,
                  borderRadius: '12px',
                  border: '1.5px solid rgba(230,141,51,0.45)',
                  borderLeft: '4px solid #E68D33',
                  background: theme.palette.mode === 'dark'
                    ? 'rgba(30,41,59,0.4)'
                    : 'rgba(230,141,51,0.06)',
                })}>
                  <Typography variant="subtitle2" sx={{ fontWeight: 700, color: '#E68D33' }}>
                    Relocating Mode Active
                  </Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    Moving booking from Seat {relocatingSeat.seatNumber}.
                  </Typography>
                  <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
                    Click on any available seat on the map.
                  </Typography>
                </Box>

                {relocatingStatus === 'error' && (
                  <Box sx={{ p: 2, bgcolor: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 2 }}>
                    <Typography variant="caption" color="error">{relocationErrorMsg}</Typography>
                  </Box>
                )}

                <Button fullWidth variant="outlined" onClick={() => {
                  setRelocatingSeat(null);
                  setRelocatingStatus('idle');
                  setRelocationErrorMsg('');
                }}>
                  Cancel Move
                </Button>
              </Stack>

            ) : selectedSeat ? (
              <Stack spacing={2}>

                {/* ── Seat header ── */}
                <Box sx={(theme) => ({
                  p: 2,
                  borderRadius: '14px',
                  border: `1.5px solid ${accentAlpha(0.3)}`,
                  borderLeft: `4px solid ${accentColor}`,
                  background: theme.palette.mode === 'dark'
                    ? 'rgba(30,41,59,0.5)'
                    : `rgba(${isFareBreakdown ? '99,102,241' : '230,141,51'},0.04)`,
                })}>
                  {/* Seat number + booking type chip */}
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5, flexWrap: 'wrap' }}>
                    <Typography variant="subtitle1" sx={{ fontWeight: 800, fontSize: '1.05rem' }}>
                      Seat {selectedSeat.seatNumber}
                    </Typography>
                    <Chip
                      icon={isFareBreakdown
                        ? <CallSplitIcon sx={{ fontSize: '13px !important' }} />
                        : <CheckCircleOutlineIcon sx={{ fontSize: '13px !important' }} />}
                      label={isFareBreakdown ? 'FARE BREAKDOWN' : 'NORMAL BOOKING'}
                      size="small"
                      sx={{
                        fontWeight: 800,
                        fontSize: '0.62rem',
                        letterSpacing: 0.4,
                        bgcolor: isFareBreakdown ? 'rgba(99,102,241,0.12)' : 'rgba(20,184,166,0.12)',
                        color: isFareBreakdown ? '#6366F1' : '#0d9488',
                        border: `1px solid ${isFareBreakdown ? 'rgba(99,102,241,0.4)' : 'rgba(20,184,166,0.35)'}`,
                        '& .MuiChip-icon': { color: 'inherit' },
                      }}
                    />
                    {/* Status chip */}
                    <Chip
                      label={(selectedSeat.status || 'unknown').toUpperCase()}
                      size="small"
                      sx={{
                        fontWeight: 700,
                        fontSize: '0.62rem',
                        bgcolor:
                          selectedSeat.status === 'boarded' ? 'rgba(34,197,94,0.12)'
                          : selectedSeat.status === 'reserved' ? 'rgba(230,141,51,0.12)'
                          : 'rgba(99,102,241,0.08)',
                        color:
                          selectedSeat.status === 'boarded' ? '#16a34a'
                          : selectedSeat.status === 'reserved' ? '#E68D33'
                          : '#64748b',
                      }}
                    />
                  </Box>

                  {/* Subtitle for fare-breakdown */}
                  {isFareBreakdown && (
                    <Typography variant="caption" sx={{ color: '#6366F1', fontStyle: 'italic', display: 'block', mb: 0.5 }}>
                      {segments.length} passengers share this seat across different journey legs
                    </Typography>
                  )}

                  <Typography variant="caption" color="text.secondary">
                    Last updated: {formatDateTime(selectedSeat.updatedAt || selectedSeat.bookedAt)}
                  </Typography>
                </Box>

                {/* ── Journey cards (one per segment) ── */}
                {isBooked && (
                  <Box>
                    {segments.map((seg, idx) => (
                      <JourneyCard
                        key={idx}
                        index={idx}
                        total={segments.length}
                        segment={seg}
                        isFareBreakdown={isFareBreakdown}
                        accentColor={accentColor}
                        accentAlpha={accentAlpha}
                        selectedSeat={selectedSeat}
                      />
                    ))}

                    {/* ── Admin override dropdowns — ONLY for normal (single) bookings ── */}
                    {!isFareBreakdown && (
                      <Box sx={{ mt: 2 }}>
                        <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', mb: 1, display: 'block' }}>
                          Admin Override — Stop Correction
                        </Typography>
                        <FormControl fullWidth size="small" sx={{ mb: 1.5 }}>
                          <InputLabel sx={{ fontSize: '0.8rem' }}>Boarding Point</InputLabel>
                          <Select
                            value={selectedSeat.origin || selectedSeat.pickup || ''}
                            label="Boarding Point"
                            onChange={(e) => handleStopChange('origin', e.target.value)}
                            sx={{ fontSize: '0.8rem' }}
                          >
                            <MenuItem value=""><em>Unknown</em></MenuItem>
                            {routeStops.map((stop, i) => (
                              <MenuItem key={`orig-${i}`} value={stop}>{stop}</MenuItem>
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
                            {routeStops.map((stop, i) => (
                              <MenuItem key={`dest-${i}`} value={stop}>{stop}</MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      </Box>
                    )}
                  </Box>
                )}

                {/* ── Ticket perforated divider ── */}
                <Box sx={{ display: 'flex', alignItems: 'center', mx: -2, height: '16px', position: 'relative' }}>
                  <Box sx={(theme) => ({
                    position: 'absolute', left: '-8px', top: '50%', transform: 'translateY(-50%)',
                    width: 16, height: 16, borderRadius: '50%',
                    backgroundColor: theme.palette.background.paper,
                    border: `1.5px solid ${accentAlpha(0.25)}`,
                    borderLeftColor: 'transparent', borderTopColor: 'transparent', borderBottomColor: 'transparent',
                    zIndex: 2,
                  })} />
                  <Box sx={(theme) => ({
                    flex: 1, height: '1px', mx: 1,
                    borderTop: `1px dashed ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.12)'}`,
                  })} />
                  <Box sx={(theme) => ({
                    position: 'absolute', right: '-8px', top: '50%', transform: 'translateY(-50%)',
                    width: 16, height: 16, borderRadius: '50%',
                    backgroundColor: theme.palette.background.paper,
                    border: `1.5px solid ${accentAlpha(0.25)}`,
                    borderRightColor: 'transparent', borderTopColor: 'transparent', borderBottomColor: 'transparent',
                    zIndex: 2,
                  })} />
                </Box>

                {/* Seat type chip */}
                <Chip
                  label={(selectedSeat.type || 'Standard').toUpperCase()}
                  size="small"
                  sx={{
                    fontWeight: 600, fontSize: '0.7rem', alignSelf: 'flex-start',
                    bgcolor: accentAlpha(0.12), color: accentColor,
                    border: `1px solid ${accentAlpha(0.25)}`,
                  }}
                />

                {/* ── Seat action buttons ── */}
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
                      onClick={() => setRelocatingSeat(selectedSeat)}
                      sx={{
                        background: `linear-gradient(135deg, ${accentColor}, ${isFareBreakdown ? '#4f46e5' : '#c9731a'})`,
                        color: '#fff',
                        '&:hover': {
                          background: `linear-gradient(135deg, ${isFareBreakdown ? '#818cf8' : '#f09e48'}, ${accentColor})`,
                        },
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
                  <Button fullWidth variant="contained" color="error" onClick={handleBlockSeat}>
                    Block Seat (Maintenance)
                  </Button>
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
                  if (window.confirm('Reset entire layout to standard? All bookings for this ride will be lost!')) {
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

/* ─────────────────────────────────────────────────────────────────────────────
 * JourneyCard
 * Displays the detail of a single journey segment.
 * For fare-breakdown seats this is rendered once per segment, stacked.
 * ──────────────────────────────────────────────────────────────────────────── */
const JourneyCard = ({ index, total, segment, isFareBreakdown, accentColor, accentAlpha, selectedSeat }) => {
  const origin = segment.origin || 'Unknown';
  const destination = segment.destination || 'Unknown';
  const passengerId = segment.passengerId || 'Unknown';
  const ticketCode = segment.ticketCode;
  // Fare fields: prefer segment-level, fall back to top-level seat document
  const stopPrice = segment.stopPrice ?? selectedSeat?.stopPrice ?? null;
  const endPrice = segment.endPrice ?? selectedSeat?.endPrice ?? null;
  const hasFare = stopPrice !== null || endPrice !== null;

  return (
    <Box
      sx={(theme) => ({
        mb: 1.5,
        borderRadius: '12px',
        border: `1.5px solid ${accentAlpha(isFareBreakdown ? 0.4 : 0.22)}`,
        overflow: 'hidden',
        background: theme.palette.mode === 'dark' ? 'rgba(15,23,42,0.55)' : '#fff',
        boxShadow: `0 2px 10px ${accentAlpha(0.07)}`,
      })}
    >
      {/* Card header bar */}
      <Box
        sx={{
          px: 2,
          py: 1,
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          bgcolor: accentAlpha(0.09),
          borderBottom: `1px solid ${accentAlpha(0.15)}`,
        }}
      >
        {isFareBreakdown
          ? <CallSplitIcon sx={{ fontSize: 15, color: accentColor }} />
          : <ConfirmationNumberIcon sx={{ fontSize: 15, color: accentColor }} />}
        <Typography variant="caption" sx={{ fontWeight: 800, color: accentColor, letterSpacing: 0.3 }}>
          {isFareBreakdown
            ? `Journey ${index + 1} of ${total}`
            : 'Booking Details'}
        </Typography>
      </Box>

      {/* Card body */}
      <Box sx={{ px: 2, py: 1.5 }}>
        {/* Passenger row */}
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1.2, mb: 1.1 }}>
          <PersonIcon sx={{ fontSize: 16, color: 'text.secondary', mt: 0.15 }} />
          <Box>
            <Typography variant="caption" color="text.secondary" display="block" sx={{ lineHeight: 1.2 }}>
              Passenger
            </Typography>
            <Typography variant="body2" sx={{ fontWeight: 600, wordBreak: 'break-all', fontSize: '0.82rem' }}>
              {passengerId}
            </Typography>
          </Box>
        </Box>

        {/* Ticket row */}
        {ticketCode && (
          <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1.2, mb: 1.1 }}>
            <ConfirmationNumberIcon sx={{ fontSize: 16, color: accentColor, mt: 0.15 }} />
            <Box>
              <Typography variant="caption" color="text.secondary" display="block" sx={{ lineHeight: 1.2 }}>
                Ticket Code
              </Typography>
              <Typography variant="body2" sx={{ fontWeight: 800, color: accentColor, fontSize: '0.82rem', letterSpacing: 0.4 }}>
                {ticketCode}
              </Typography>
            </Box>
          </Box>
        )}

        {/* Route row — Boarding → Drop-off */}
        <Box
          sx={{
            mt: 1.2,
            p: 1.2,
            borderRadius: '8px',
            bgcolor: accentAlpha(0.06),
            border: `1px solid ${accentAlpha(0.15)}`,
            display: 'flex',
            alignItems: 'center',
            gap: 0.8,
          }}
        >
          {/* Origin */}
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.2 }}>
              <TripOriginIcon sx={{ fontSize: 12, color: accentColor }} />
              <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.67rem' }}>Boarding</Typography>
            </Box>
            <Typography
              variant="body2"
              sx={{ fontWeight: 700, fontSize: '0.82rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
            >
              {origin}
            </Typography>
          </Box>

          {/* Arrow */}
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
            <ArrowForwardIcon sx={{ fontSize: 16, color: accentColor }} />
          </Box>

          {/* Destination */}
          <Box sx={{ flex: 1, minWidth: 0, textAlign: 'right' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.5, mb: 0.2 }}>
              <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.67rem' }}>Drop-off</Typography>
              <LocationOnIcon sx={{ fontSize: 12, color: accentColor }} />
            </Box>
            <Typography
              variant="body2"
              sx={{ fontWeight: 700, fontSize: '0.82rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
            >
              {destination}
            </Typography>
          </Box>
        </Box>

        {/* ── Fare row (admin/operator view) ── */}
        {hasFare && (
          <Box
            sx={{
              mt: 1.2,
              p: 1.2,
              borderRadius: '8px',
              bgcolor: accentAlpha(0.04),
              border: `1px solid ${accentAlpha(0.12)}`,
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'flex-start',
              gap: 1,
            }}
          >
            <Box>
              <Typography variant="caption" color="text.secondary" display="block" sx={{ lineHeight: 1.2 }}>
                Leg Fare (this stop)
              </Typography>
              <Typography variant="body2" sx={{ fontWeight: 800, fontSize: '0.85rem', color: accentColor }}>
                {stopPrice !== null ? `LKR ${Number(stopPrice).toLocaleString()}` : '—'}
              </Typography>
            </Box>
            <Box sx={{ textAlign: 'right' }}>
              <Typography variant="caption" color="text.secondary" display="block" sx={{ lineHeight: 1.2 }}>
                Ticket Face Value
              </Typography>
              <Typography variant="body2" sx={{ fontWeight: 800, fontSize: '0.85rem', color: 'text.primary' }}>
                {endPrice !== null ? `LKR ${Number(endPrice).toLocaleString()}` : '—'}
              </Typography>
            </Box>
          </Box>
        )}
      </Box>
    </Box>
  );
};

export default AdminSeatManager;
