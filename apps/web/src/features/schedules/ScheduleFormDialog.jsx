import { useEffect, useRef } from 'react';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  FormControl,
  InputLabel,
  Select,
  FormHelperText,
  useTheme,
  CircularProgress,
  Box,
  Typography,
  Grid,
  Divider,
  Chip,
} from '@mui/material';
import {
  DirectionsBus,
  Route as RouteIcon,
  CalendarToday,
  AccessTime,
  ConfirmationNumber,
  Person,
} from '@mui/icons-material';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { db } from '../../api/firebase';
import { useBusesFirestore } from '../fleet/useBusesFirestore';
import { useRoutesFirestore } from '../routes/useRoutesFirestore';

// ── Validation Schema ────────────────────────────────────────────────────────
const scheduleSchema = z.object({
  routeId:       z.string().min(1, 'Please select a route'),
  busId:         z.string().min(1, 'Please select a bus'),
  opId:          z.string().min(1, 'Operator ID is required'),
  departureDate: z.string()
    .min(1, 'Departure date is required')
    .refine((val) => {
      const today = new Date();
      const yyyy = today.getFullYear();
      const mm = String(today.getMonth() + 1).padStart(2, '0');
      const dd = String(today.getDate()).padStart(2, '0');
      const todayStr = `${yyyy}-${mm}-${dd}`;
      return val >= todayStr;
    }, { message: 'Date cannot be in the past' }),
  departureTime: z.string().min(1, 'Departure time is required'),
});

// ── Section Header ────────────────────────────────────────────────────────────
const SectionLabel = ({ icon, text }) => (
  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 2.5, mb: 0.5 }}>
    <Box sx={{ color: 'primary.main', display: 'flex' }}>{icon}</Box>
    <Typography variant="caption" sx={{ fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, color: 'text.secondary' }}>
      {text}
    </Typography>
  </Box>
);

// ── Time Scroll Picker Constants & Component ──────────────────────────────────
const HOURS = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
const MINUTES = Array.from({ length: 60 }, (_, i) => String(i).padStart(2, '0'));
const AMPM = ['AM', 'PM'];

const TimeScrollColumn = ({ items, value, onChange, theme, disabled }) => {
  const containerRef = useRef(null);
  const timeoutRef = useRef(null);

  useEffect(() => {
    const idx = items.indexOf(value);
    if (idx !== -1 && containerRef.current) {
      containerRef.current.scrollTo({
        top: idx * 40,
        behavior: 'smooth',
      });
    }
  }, [value, items]);

  const handleScroll = (e) => {
    if (disabled) return;
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    const target = e.target;
    timeoutRef.current = setTimeout(() => {
      const scrollTop = target.scrollTop;
      const index = Math.round(scrollTop / 40);
      if (index >= 0 && index < items.length) {
        const val = items[index];
        if (val !== value) {
          onChange(val);
        }
      }
    }, 150);
  };

  const handleClick = (item) => {
    if (disabled) return;
    onChange(item);
  };

  return (
    <Box
      ref={containerRef}
      onScroll={handleScroll}
      sx={{
        height: 120,
        overflowY: disabled ? 'hidden' : 'auto',
        scrollbarWidth: 'none',
        '&::-webkit-scrollbar': { display: 'none' },
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        scrollSnapType: disabled ? 'none' : 'y mandatory',
        width: 65,
        backgroundColor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)',
        borderRadius: 2.5,
        border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)'}`,
        opacity: disabled ? 0.6 : 1,
        pointerEvents: disabled ? 'none' : 'auto',
      }}
    >
      <Box sx={{ height: 40, flexShrink: 0 }} />
      {items.map((item) => {
        const isSelected = item === value;
        return (
          <Box
            key={item}
            onClick={() => handleClick(item)}
            sx={{
              height: 40,
              flexShrink: 0,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: disabled ? 'default' : 'pointer',
              scrollSnapAlign: 'center',
              fontWeight: isSelected ? 800 : 500,
              color: isSelected ? '#E68D33' : 'text.secondary',
              fontSize: isSelected ? '1.05rem' : '0.85rem',
              transition: 'all 0.15s ease',
              width: '100%',
              userSelect: 'none',
              ...(!disabled && {
                '&:hover': {
                  backgroundColor: 'rgba(230, 141, 51, 0.08)',
                  color: '#E68D33',
                }
              })
            }}
          >
            {item}
          </Box>
        );
      })}
      <Box sx={{ height: 40, flexShrink: 0 }} />
    </Box>
  );
};

// ── Component ─────────────────────────────────────────────────────────────────
export const ScheduleFormDialog = ({ open, onClose, onSubmit, initialData }) => {
  const theme = useTheme();
  const { routes, loading: isLoadingRoutes } = useRoutesFirestore();
  const { buses, loading: isLoadingBuses } = useBusesFirestore();

  const {
    control,
    handleSubmit,
    reset,
    watch,
    setError,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(scheduleSchema),
    defaultValues: {
      routeId:       '',
      busId:         '',
      opId:          '',
      departureDate: '',
      departureTime: '',
    },
  });

  // Watch fields to derive the auto-filled displays and previews
  const watchedBusId    = watch('busId');
  const selectedBus     = buses.find((b) => b.id === watchedBusId);
  const watchedRouteId  = watch('routeId');
  const selectedRoute   = routes.find((r) => r.id === watchedRouteId);

  // Reset form when dialog opens / closes
  useEffect(() => {
    if (open) {
      if (initialData) {
        const dt = initialData.departureTime ? new Date(initialData.departureTime) : null;
        reset({
          routeId:       initialData.routeId                              || '',
          busId:         initialData.busId                                || '',
          // Schedules store the field as 'operatorId'; fall back to legacy 'opId'
          opId:          initialData.operatorId || initialData.opId       || '',
          departureDate: dt ? dt.toISOString().slice(0, 10) : '',
          departureTime: dt ? dt.toTimeString().slice(0, 5)  : '',
        });
      } else {
        reset({ routeId: '', busId: '', opId: '', departureDate: '', departureTime: '' });
      }
    }
  }, [open, initialData, reset]);


  // ── Submit ─────────────────────────────────────────────────────────────────
  const handleFormSubmit = async (data) => {
    // Validate opId against the 'operators' collection using the 'operatorId' field
    try {
      const trimmedOpId = data.opId.trim();
      console.log('[Schedule] Validating operatorId against operators collection:', JSON.stringify(trimmedOpId));

      // Query 'operators' collection by the 'operatorId' FIELD
      const opQuery = query(
        collection(db, 'operators'),
        where('operatorId', '==', trimmedOpId)
      );
      const opSnapshot = await getDocs(opQuery);
      console.log('[Schedule] Matches found in operators collection:', opSnapshot.size);

      if (opSnapshot.empty) {
        console.log('[Schedule] Not found by operatorId field in operators collection.');
        setError('opId', { type: 'manual', message: `Operator ID "${trimmedOpId}" not found. Please enter a valid Operator ID.` });
        return;
      }

      // Ensure the found doc has role === 'operator'
      const opData = opSnapshot.docs[0].data();
      if (opData.role && opData.role !== 'operator') {
        setError('opId', { type: 'manual', message: 'This ID does not belong to an operator account.' });
        return;
      }
    } catch (err) {
      console.error('Error validating operator ID against operators collection', err);
      setError('opId', { type: 'manual', message: err.message || 'Error validating Operator ID' });
      return;
    }

    const combinedDateTime = new Date(`${data.departureDate}T${data.departureTime}:00`).toISOString();
    const now = new Date().toISOString();

    const capacity = selectedBus?.capacity || 54;
    const seatMap = {};
    const seatsPerRow = 4;
    const totalRows = Math.ceil(capacity / seatsPerRow);
    for (let row = 0; row < totalRows; row++) {
      const rowLetter = String.fromCharCode(65 + row);
      for (let seat = 1; seat <= seatsPerRow; seat++) {
        const seatIndex = row * seatsPerRow + seat;
        if (seatIndex <= capacity) {
          seatMap[`${rowLetter}${seat}`] = 'available';
        }
      }
    }

    const formattedData = {
      busId:         data.busId,
      busCapacity:   capacity,
      busPlateNumber:selectedBus?.plateNumber  || 'N/A',
      routeId:       data.routeId,
      routeName:     selectedRoute?.name       || selectedRoute?.routeName || 'Unnamed Route',
      startingPoint: selectedRoute?.startPoint ? selectedRoute.startPoint.split(',')[0] : 'N/A',
      departureTime: combinedDateTime,
      operatorId:    data.opId,
      status:        'scheduled',
      createdAt:     now,
      updatedAt:     now,
      delayMinutes:  0,
      eta:           null,
      seatMap:       seatMap
    };

    await onSubmit(formattedData);
    onClose();
  };

  const isLoadingData = isLoadingRoutes || isLoadingBuses;

  return (
    <Dialog
      open={open}
      onClose={onClose}
      fullWidth
      maxWidth="sm"
      PaperProps={{
        sx: {
          backgroundColor: theme.palette.background.paper,
          backgroundImage: 'none',
          boxShadow: '0 24px 48px rgba(0,0,0,0.5)',
          border: '1px solid rgba(255,255,255,0.1)',
          borderRadius: 3,
        },
      }}
    >
      {/* ── Dialog Title ───────────────────────────────────────────────── */}
      <DialogTitle sx={{ pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box
            sx={{
              backgroundColor: 'primary.main',
              borderRadius: 2,
              p: 0.8,
              display: 'flex',
              color: '#fff',
            }}
          >
            <CalendarToday fontSize="small" />
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2 }}>
              {initialData ? 'View Schedule' : 'Create New Schedule'}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {initialData ? 'Schedule details (read-only)' : 'Fill in the details below to schedule a bus trip'}
            </Typography>
          </Box>
        </Box>
      </DialogTitle>

      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />

      {isLoadingData ? (
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', p: 6, gap: 2 }}>
          <CircularProgress />
          <Typography variant="body2" color="text.secondary">Loading routes and buses…</Typography>
        </Box>
      ) : (
        <form onSubmit={handleSubmit(handleFormSubmit)}>
          <DialogContent sx={{ pt: 1, pb: 2 }}>

            {/* ── ROUTE SECTION ─────────────────────────────────────────── */}
            <SectionLabel icon={<RouteIcon fontSize="small" />} text="Route" />

            <FormControl fullWidth margin="dense" error={!!errors.routeId}>
              <InputLabel id="route-select-label" shrink>Select Route</InputLabel>
              <Controller
                name="routeId"
                control={control}
                render={({ field }) => (
                  <Select
                    {...field}
                    labelId="route-select-label"
                    label="Select Route"
                    notched
                    disabled={!!initialData}
                    displayEmpty
                    renderValue={(val) => {
                      if (!val) return <Typography color="text.disabled">Choose a route…</Typography>;
                      const r = routes.find((r) => r.id === val);
                      if (!r) return val;
                      const name = r.name || r.routeName || `${r.startPoint} - ${r.endPoint}` || 'Unnamed Route';
                      return (
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          {r.routeNumber && (
                            <Chip label={`#${r.routeNumber}`} size="small" color="primary" sx={{ height: 20, fontSize: '0.7rem' }} />
                          )}
                          <Typography variant="body2">{name}</Typography>
                        </Box>
                      );
                    }}
                  >
                    {routes.length === 0 ? (
                      <MenuItem disabled value="">No routes available</MenuItem>
                    ) : (
                      routes.map((r) => {
                        const displayName =
                          r.name || r.routeName || r.displayName ||
                          (r.startPoint && r.endPoint ? `${r.startPoint.split(',')[0]} → ${r.endPoint.split(',')[0]}` : null) ||
                          'Unnamed Route';
                        return (
                          <MenuItem key={r.id} value={r.id}>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, py: 0.3 }}>
                              {r.routeNumber && (
                                <Chip label={`#${r.routeNumber}`} size="small" color="primary" variant="outlined" sx={{ height: 20, fontSize: '0.7rem' }} />
                              )}
                              <Box>
                                <Typography variant="body2" sx={{ fontWeight: 600 }}>{displayName}</Typography>
                                {r.startPoint && r.endPoint && (
                                  <Typography variant="caption" color="text.secondary">
                                    {r.startPoint.split(',')[0]} → {r.endPoint.split(',')[0]}
                                  </Typography>
                                )}
                              </Box>
                            </Box>
                          </MenuItem>
                        );
                      })
                    )}
                  </Select>
                )}
              />
              {errors.routeId && <FormHelperText>{errors.routeId.message}</FormHelperText>}
            </FormControl>

            {/* ── BUS SECTION ──────────────────────────────────────────── */}
            <SectionLabel icon={<DirectionsBus fontSize="small" />} text="Bus" />

            <FormControl fullWidth margin="dense" error={!!errors.busId}>
              <InputLabel id="bus-select-label" shrink>Select Bus</InputLabel>
              <Controller
                name="busId"
                control={control}
                render={({ field }) => (
                  <Select
                    {...field}
                    labelId="bus-select-label"
                    label="Select Bus"
                    notched
                    disabled={!!initialData}
                    displayEmpty
                    renderValue={(val) => {
                      if (!val) return <Typography color="text.disabled">Choose a bus…</Typography>;
                      const b = buses.find((b) => b.id === val);
                      if (!b) return val;
                      return (
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>{b.plateNumber}</Typography>
                          <Typography variant="caption" color="text.secondary">({b.class})</Typography>
                        </Box>
                      );
                    }}
                  >
                    {buses.length === 0 ? (
                      <MenuItem disabled value="">No buses available</MenuItem>
                    ) : (
                      buses.map((b) => (
                        <MenuItem key={b.id} value={b.id}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, py: 0.3 }}>
                            <DirectionsBus fontSize="small" sx={{ color: 'primary.light' }} />
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: 600 }}>{b.plateNumber}</Typography>
                              <Typography variant="caption" color="text.secondary">
                                {b.class} · Capacity: {b.capacity || '—'}
                              </Typography>
                            </Box>
                          </Box>
                        </MenuItem>
                      ))
                    )}
                  </Select>
                )}
              />
              {errors.busId && <FormHelperText>{errors.busId.message}</FormHelperText>}
            </FormControl>

            {/* ── BUS ID (auto-filled read-only) ───────────────────────── */}
            {watchedBusId && (
              <Box sx={{ mt: 1 }}>
                <SectionLabel icon={<ConfirmationNumber fontSize="small" />} text="Bus ID" />
                <TextField
                  fullWidth
                  margin="dense"
                  label="Bus ID (auto-filled)"
                  value={watchedBusId}
                  InputProps={{ readOnly: true }}
                  InputLabelProps={{ shrink: true }}
                  helperText={selectedBus ? `Plate: ${selectedBus.plateNumber} · Class: ${selectedBus.class}` : ''}
                  sx={{
                    '& .MuiInputBase-root': {
                      backgroundColor: 'rgba(255,255,255,0.03)',
                      fontFamily: 'monospace',
                      fontSize: '0.82rem',
                    },
                  }}
                />
              </Box>
            )}

            {/* ── OPERATOR SECTION ──────────────────────────────────────── */}
            <SectionLabel icon={<Person fontSize="small" />} text="Operator" />
            <Controller
              name="opId"
              control={control}
              render={({ field }) => (
                <TextField
                  {...field}
                  fullWidth
                  label="Operator ID"
                  placeholder="Enter the operatorId from the operators collection"
                  variant="outlined"
                  margin="dense"
                  error={!!errors.opId}
                  helperText={errors.opId?.message || 'Must match an operatorId in the operators collection'}
                  disabled={!!initialData}
                  InputLabelProps={{ shrink: true }}
                />
              )}
            />

            {/* ── DATE & TIME SECTION ──────────────────────────────────── */}
            <SectionLabel icon={<AccessTime fontSize="small" />} text="Date & Time" />

            <Grid container spacing={2} sx={{ mt: 0 }}>
              <Grid item xs={12} sm={6}>
                <Controller
                  name="departureDate"
                  control={control}
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      type="date"
                      margin="dense"
                      InputLabelProps={{ shrink: true }}
                      inputProps={{ 
                        min: (() => {
                          const today = new Date();
                          const yyyy = today.getFullYear();
                          const mm = String(today.getMonth() + 1).padStart(2, '0');
                          const dd = String(today.getDate()).padStart(2, '0');
                          return `${yyyy}-${mm}-${dd}`;
                        })()
                      }}
                      error={!!errors.departureDate}
                      helperText={errors.departureDate?.message}
                      disabled={!!initialData}
                    />
                  )}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <Controller
                  name="departureTime"
                  control={control}
                  render={({ field }) => {
                    const timeVal = field.value || "12:00";
                    const [h24, minStr] = timeVal.split(':');
                    const h24Int = parseInt(h24, 10) || 12;
                    const isPM = h24Int >= 12;
                    const h12 = h24Int % 12 === 0 ? 12 : h24Int % 12;
                    const hourStr = String(h12).padStart(2, '0');
                    const ampmStr = isPM ? 'PM' : 'AM';

                    const handleTimeChange = (type, val) => {
                      let newHour = hourStr;
                      let newMin = minStr || "00";
                      let newAmpm = ampmStr;

                      if (type === 'hour') newHour = val;
                      if (type === 'minute') newMin = val;
                      if (type === 'ampm') newAmpm = val;

                      const h12Int = parseInt(newHour, 10);
                      let h24Int = h12Int;
                      if (newAmpm === 'PM' && h12Int !== 12) h24Int = h12Int + 12;
                      if (newAmpm === 'AM' && h12Int === 12) h24Int = 0;

                      const formattedH24 = String(h24Int).padStart(2, '0');
                      const formattedTime = `${formattedH24}:${newMin}`;
                      field.onChange(formattedTime);
                    };

                    return (
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                        <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 700, mb: -0.5 }}>
                          Departure Time
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                          <TimeScrollColumn
                            items={HOURS}
                            value={hourStr}
                            onChange={(val) => handleTimeChange('hour', val)}
                            theme={theme}
                            disabled={!!initialData}
                          />
                          <Typography variant="h6" sx={{ color: 'text.secondary', fontWeight: 'bold' }}>:</Typography>
                          <TimeScrollColumn
                            items={MINUTES}
                            value={minStr || "00"}
                            onChange={(val) => handleTimeChange('minute', val)}
                            theme={theme}
                            disabled={!!initialData}
                          />
                          <Box sx={{ width: 4 }} />
                          <TimeScrollColumn
                            items={AMPM}
                            value={ampmStr}
                            onChange={(val) => handleTimeChange('ampm', val)}
                            theme={theme}
                            disabled={!!initialData}
                          />
                        </Box>
                        {errors.departureTime && (
                          <Typography variant="caption" color="error">
                            {errors.departureTime.message}
                          </Typography>
                        )}
                      </Box>
                    );
                  }}
                />
              </Grid>
            </Grid>

            {/* ── Summary preview ──────────────────────────────────────── */}
            {!initialData && selectedBus && selectedRoute && watch('departureDate') && watch('departureTime') && (
              <Box
                sx={{
                  mt: 2.5,
                  p: 2.5,
                  borderRadius: '12px',
                  border: `1.5px solid ${theme.palette.primary.main}40`,
                  borderTop: `4px solid ${theme.palette.primary.main}`,
                  background: theme.palette.mode === 'dark'
                    ? 'linear-gradient(135deg, rgba(30, 41, 59, 0.4) 0%, rgba(15, 23, 42, 0.45) 100%)'
                    : 'linear-gradient(135deg, rgba(255, 255, 255, 0.7) 0%, rgba(248, 250, 252, 0.6) 100%)',
                  boxShadow: theme.palette.mode === 'dark'
                    ? '0 4px 12px rgba(0, 0, 0, 0.15)'
                    : '0 4px 12px rgba(0, 0, 0, 0.02)',
                  position: 'relative',
                  overflow: 'visible',
                }}
              >
                <Typography variant="caption" sx={{ fontWeight: 700, color: 'primary.light', textTransform: 'uppercase', letterSpacing: 0.8 }}>
                  Schedule Preview
                </Typography>
                <Box sx={{ mt: 1.5, display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                  <Typography variant="body2">
                    <strong>Route:</strong>{' '}
                    {selectedRoute.routeNumber ? `#${selectedRoute.routeNumber} · ` : ''}
                    {selectedRoute.name || selectedRoute.routeName || 'Unnamed Route'}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Bus:</strong> {selectedBus.plateNumber} ({selectedBus.class})
                  </Typography>
                  <Typography variant="body2">
                    <strong>Departs:</strong>{' '}
                    {new Date(`${watch('departureDate')}T${watch('departureTime')}:00`).toLocaleString('en-US', {
                      weekday: 'short', year: 'numeric', month: 'short',
                      day: 'numeric', hour: '2-digit', minute: '2-digit',
                    })}
                  </Typography>

                  {/* Ticket Divider & Cutout Notches */}
                  <Box sx={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between', 
                    mx: -2.5, 
                    my: 1.5,
                    height: '16px',
                    position: 'relative'
                  }}>
                    {/* Left Notch */}
                    <Box 
                      className="ticket-notch"
                      sx={{
                        position: 'absolute',
                        left: '-8px',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        width: '16px',
                        height: '16px',
                        borderRadius: '50%',
                        backgroundColor: theme.palette.background.paper,
                        border: `1.5px solid ${theme.palette.primary.main}40`,
                        borderLeftColor: 'transparent',
                        borderTopColor: 'transparent',
                        borderBottomColor: 'transparent',
                        zIndex: 2,
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
                        right: '-8px',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        width: '16px',
                        height: '16px',
                        borderRadius: '50%',
                        backgroundColor: theme.palette.background.paper,
                        border: `1.5px solid ${theme.palette.primary.main}40`,
                        borderRightColor: 'transparent',
                        borderTopColor: 'transparent',
                        borderBottomColor: 'transparent',
                        zIndex: 2,
                      }} 
                    />
                  </Box>

                  <Typography variant="body2">
                    <strong>Operator ID:</strong> {watch('opId') || 'Unassigned'}
                  </Typography>
                </Box>
              </Box>
            )}

            {/* ── Edit-mode notice ─────────────────────────────────────── */}
            {!!initialData && (
              <Box sx={{ mt: 2, p: 1.5, borderRadius: 2, backgroundColor: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.2)' }}>
                <Typography variant="caption" color="warning.main" sx={{ fontWeight: 600 }}>
                  Core schedule details are locked after creation. Use the card actions to cancel this schedule.
                </Typography>
              </Box>
            )}
          </DialogContent>

          {/* ── Actions ────────────────────────────────────────────────── */}
          <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />
          <DialogActions sx={{ p: 2, px: 3, gap: 1 }}>
            <Button onClick={onClose} color="inherit" variant="outlined">
              Cancel
            </Button>
            {!initialData && (
              <Button
                type="submit"
                variant="contained"
                disabled={isSubmitting}
                startIcon={isSubmitting ? <CircularProgress size={16} color="inherit" /> : <CalendarToday fontSize="small" />}
                sx={{ px: 3 }}
              >
                {isSubmitting ? 'Creating…' : 'Create Schedule'}
              </Button>
            )}
          </DialogActions>
        </form>
      )}
    </Dialog>
  );
};
