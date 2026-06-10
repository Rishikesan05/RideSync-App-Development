import React, { useEffect } from 'react';
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
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../../api/firebase';
import { useRoutesFirestore } from '../routes/useRoutesFirestore';
import { useBusesList } from '../../api/buses';

// ── Validation Schema ────────────────────────────────────────────────────────
const scheduleSchema = z.object({
  routeId:       z.string().min(1, 'Please select a route'),
  busId:         z.string().min(1, 'Please select a bus'),
  opId:          z.string().min(1, 'Operator ID is required'),
  departureDate: z.string().min(1, 'Departure date is required'),
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

// ── Component ─────────────────────────────────────────────────────────────────
export const ScheduleFormDialog = ({ open, onClose, onSubmit, initialData }) => {
  const theme = useTheme();
  const { routes, loading: isLoadingRoutes } = useRoutesFirestore();
  const { data: busesResponse, isLoading: isLoadingBuses } = useBusesList();

  const busesData = busesResponse?.data || busesResponse?.buses || busesResponse || [];
  const buses     = Array.isArray(busesData) ? busesData : [];

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
          routeId:       initialData.routeId       || '',
          busId:         initialData.busId         || '',
          opId:          initialData.opId          || '',
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
    // Validate opId
    try {
      const opRef = doc(db, 'operator', data.opId);
      const opSnap = await getDoc(opRef);
      if (!opSnap.exists()) {
        setError('opId', { type: 'manual', message: 'Operator ID does not exist' });
        return;
      }
    } catch (err) {
      console.error('Error validating operator ID', err);
      setError('opId', { type: 'manual', message: 'Error validating Operator ID' });
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
                  label="Operator ID (opId)"
                  variant="outlined"
                  margin="dense"
                  error={!!errors.opId}
                  helperText={errors.opId?.message}
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
                      label="Departure Date"
                      type="date"
                      margin="dense"
                      InputLabelProps={{ shrink: true }}
                      inputProps={{ min: new Date().toISOString().slice(0, 10) }}
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
                  render={({ field }) => (
                    <TextField
                      {...field}
                      fullWidth
                      label="Departure Time"
                      type="time"
                      margin="dense"
                      InputLabelProps={{ shrink: true }}
                      error={!!errors.departureTime}
                      helperText={errors.departureTime?.message}
                      disabled={!!initialData}
                    />
                  )}
                />
              </Grid>
            </Grid>

            {/* ── Summary preview ──────────────────────────────────────── */}
            {!initialData && selectedBus && selectedRoute && watch('departureDate') && watch('departureTime') && (
              <Box
                sx={{
                  mt: 2.5,
                  p: 2,
                  borderRadius: 2,
                  backgroundColor: 'rgba(99,102,241,0.08)',
                  border: '1px solid rgba(99,102,241,0.2)',
                }}
              >
                <Typography variant="caption" sx={{ fontWeight: 700, color: 'primary.light', textTransform: 'uppercase', letterSpacing: 0.8 }}>
                  Schedule Preview
                </Typography>
                <Box sx={{ mt: 1, display: 'flex', flexDirection: 'column', gap: 0.5 }}>
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
                  {watch('opId') && (
                    <Typography variant="body2">
                      <strong>Operator ID:</strong> {watch('opId')}
                    </Typography>
                  )}
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
