import React, { useEffect, useState } from 'react';
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
  InputAdornment
} from '@mui/material';
import { CheckCircle, Error as ErrorIcon } from '@mui/icons-material';
import { useRoutesList } from '../../api/routes';
import { useBusesList } from '../../api/buses';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../../api/firebase';

const scheduleSchema = z.object({
  routeId: z.string().min(1, 'Route is required'),
  busId: z.string().min(1, 'Bus is required'),
  operatorId: z.string().min(1, 'Operator ID is required'),
  departureTime: z.string().min(1, 'Departure time is required'),
});

export const ScheduleFormDialog = ({ open, onClose, onSubmit, initialData }) => {
  const theme = useTheme();
  const { data: routesResponse, isLoading: isLoadingRoutes } = useRoutesList();
  const { data: busesResponse, isLoading: isLoadingBuses } = useBusesList();

  const [operatorStatus, setOperatorStatus] = useState({ loading: false, valid: false, name: '', error: '' });

  const routesData = routesResponse?.data || routesResponse?.routes || routesResponse || [];
  const routes = Array.isArray(routesData) ? routesData : [];

  const busesData = busesResponse?.data || busesResponse?.buses || busesResponse || [];
  const buses = Array.isArray(busesData) ? busesData : [];

  const {
    control,
    handleSubmit,
    reset,
    watch,
    setError,
    clearErrors,
    formState: { errors, isSubmitting }
  } = useForm({
    resolver: zodResolver(scheduleSchema),
    defaultValues: {
      routeId: '',
      busId: '',
      operatorId: '',
      departureTime: '',
    }
  });

  const operatorId = watch('operatorId');

  // Validate Operator ID from Firestore
  useEffect(() => {
    if (operatorId && operatorId.length > 5) { // Threshold for UID
      const validateOperator = async () => {
        setOperatorStatus({ loading: true, valid: false, name: '', error: '' });
        try {
          const userSnap = await getDoc(doc(db, "users", operatorId));
          if (userSnap.exists()) {
            const userData = userSnap.data();
            if (userData.role === 'operator') {
              setOperatorStatus({ loading: false, valid: true, name: userData.name || userData.displayName || 'Unknown Operator', error: '' });
              clearErrors('operatorId');
            } else {
              setOperatorStatus({ loading: false, valid: false, name: '', error: 'User is not an operator' });
              setError('operatorId', { type: 'manual', message: 'User exists but is not an operator' });
            }
          } else {
            setOperatorStatus({ loading: false, valid: false, name: '', error: 'Operator ID not found' });
            setError('operatorId', { type: 'manual', message: 'Operator ID not found in database' });
          }
        } catch (err) {
          console.error("Valitation error:", err);
          setOperatorStatus({ loading: false, valid: false, name: '', error: 'Validation failed' });
        }
      };

      const timer = setTimeout(validateOperator, 800);
      return () => clearTimeout(timer);
    } else {
      setOperatorStatus({ loading: false, valid: false, name: '', error: '' });
    }
  }, [operatorId, setError, clearErrors]);

  useEffect(() => {
    if (open) {
      if (initialData) {
        const dateString = initialData.departureTime ? new Date(initialData.departureTime).toISOString().slice(0, 16) : '';
        reset({
          routeId: initialData.routeId || '',
          busId: initialData.busId || '',
          operatorId: initialData.operatorId || '',
          departureTime: dateString,
        });
      } else {
        reset({
          routeId: '',
          busId: '',
          operatorId: '',
          departureTime: '',
        });
      }
    }
  }, [open, initialData, reset]);

  const handleFormSubmit = async (data) => {
    if (!operatorStatus.valid && !initialData) {
       setError('operatorId', { type: 'manual', message: 'Please enter a valid operator ID' });
       return;
    }

    // Find the selected bus and route to denormalize data
    const selectedBus = buses.find(b => b.id === data.busId);
    const selectedRoute = routes.find(r => r.id === data.routeId);
    
    const formattedData = {
      ...data,
      departureTime: new Date(data.departureTime).toISOString(),
      capacity: selectedBus?.capacity || 54,
      plateNumber: selectedBus?.plateNumber || 'N/A',
      routeName: selectedRoute?.name || selectedRoute?.routeName || 'Intercity Express',
      status: 'scheduled'
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
        }
      }}
    >
      <DialogTitle sx={{ fontWeight: 700 }}>
        {initialData ? 'Edit Schedule (Status Only)' : 'Create New Schedule'}
      </DialogTitle>
      
      {isLoadingData ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <form onSubmit={handleSubmit(handleFormSubmit)}>
          <DialogContent dividers sx={{ borderColor: 'rgba(255,255,255,0.05)' }}>
            
            <FormControl fullWidth margin="normal" error={!!errors.routeId}>
              <InputLabel id="route-select-label" shrink>Route</InputLabel>
              <Controller
                name="routeId"
                control={control}
                render={({ field }) => (
                  <Select
                    {...field}
                    labelId="route-select-label"
                    label="Route"
                    notched
                    disabled={!!initialData}
                  >
                    {routes.length === 0 ? (
                      <MenuItem disabled value="">No routes available</MenuItem>
                    ) : (
                      routes.map((r) => {
                        // Advanced name extraction to prevent 'Unnamed Route'
                        const displayName = r.name || r.routeName || r.displayName || 
                                          (r.startPoint && r.endPoint ? `${r.startPoint.split(',')[0]} - ${r.endPoint.split(',')[0]}` : null) ||
                                          'Unnamed Route';
                        return (
                          <MenuItem key={r.id} value={r.id}>
                            <Typography variant="body2" sx={{ fontWeight: 600 }}>
                              {r.routeNumber ? `${r.routeNumber} - ` : ''}{displayName}
                            </Typography>
                          </MenuItem>
                        );
                      })
                    )}
                  </Select>
                )}
              />
              {errors.routeId && <FormHelperText>{errors.routeId.message}</FormHelperText>}
            </FormControl>

            <FormControl fullWidth margin="normal" error={!!errors.busId}>
              <InputLabel id="bus-select-label" shrink>Bus</InputLabel>
              <Controller
                name="busId"
                control={control}
                render={({ field }) => (
                  <Select
                    {...field}
                    labelId="bus-select-label"
                    label="Bus"
                    notched
                    disabled={!!initialData}
                  >
                    {buses.length === 0 ? (
                      <MenuItem disabled value="">No buses available</MenuItem>
                    ) : (
                      buses.map((b) => (
                        <MenuItem key={b.id} value={b.id}>{b.plateNumber} ({b.class})</MenuItem>
                      ))
                    )}
                  </Select>
                )}
              />
              {errors.busId && <FormHelperText>{errors.busId.message}</FormHelperText>}
            </FormControl>

            <Controller
              name="operatorId"
              control={control}
              render={({ field }) => (
                <TextField
                  {...field}
                  fullWidth
                  label="Operator ID (User UID)"
                  variant="outlined"
                  margin="normal"
                  error={!!errors.operatorId}
                  helperText={errors.operatorId?.message || (operatorStatus.valid ? `Operator: ${operatorStatus.name}` : '')}
                  disabled={!!initialData}
                  InputLabelProps={{ shrink: true }}
                  InputProps={{
                    endAdornment: (
                      <InputAdornment position="end">
                        {operatorStatus.loading && <CircularProgress size={20} />}
                        {operatorStatus.valid && <CheckCircle color="success" size={20} />}
                        {operatorStatus.error && <ErrorIcon color="error" size={20} />}
                      </InputAdornment>
                    )
                  }}
                />
              )}
            />

            <Controller
              name="departureTime"
              control={control}
              render={({ field }) => (
                <TextField
                  {...field}
                  fullWidth
                  label="Departure Time"
                  type="datetime-local"
                  variant="outlined"
                  margin="normal"
                  InputLabelProps={{ shrink: true }}
                  error={!!errors.departureTime}
                  helperText={errors.departureTime?.message}
                  disabled={!!initialData}
                />
              )}
            />
            
            {!!initialData && (
              <Box sx={{ mt: 2 }}>
                <p style={{ color: theme.palette.warning.main, fontSize: '0.875rem' }}>
                  Note: Editing an existing schedule's core details is restricted once created. You can only cancel or update its status via the dashboard actions.
                </p>
              </Box>
            )}

          </DialogContent>
          <DialogActions sx={{ p: 2, pr: 3 }}>
            <Button onClick={onClose} color="inherit">Cancel</Button>
            {!initialData && (
              <Button 
                type="submit" 
                variant="contained" 
                disabled={isSubmitting || operatorStatus.loading || (operatorId && !operatorStatus.valid)}
              >
                {isSubmitting ? 'Creating...' : 'Create Schedule'}
              </Button>
            )}
          </DialogActions>
        </form>
      )}
    </Dialog>
  );
};
