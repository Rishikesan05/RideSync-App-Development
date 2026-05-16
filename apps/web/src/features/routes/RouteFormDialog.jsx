import React, { useEffect, useRef, useState, useCallback } from 'react';
import { useForm, useFieldArray, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  IconButton,
  Divider,
  useTheme,
  InputAdornment,
  CircularProgress,
  Paper,
  Grid
} from '@mui/material';
import { 
  Add, 
  Delete, 
  LocationOn, 
  Route as RouteIcon, 
  Straighten, 
  ArrowUpward, 
  ArrowDownward,
  Timer,
  Navigation
} from '@mui/icons-material';

// Zod schema for route validation
const routeSchema = z.object({
  routeNumber: z.string().min(1, 'Route number is required'),
  name: z.string().min(3, 'Name must be at least 3 characters'),
  startPoint: z.string().min(1, 'Start point is required'),
  endPoint: z.string().min(1, 'End point is required'),
  totalDistanceKm: z.number().min(0),
  totalDurationMin: z.number().optional(),
  stops: z.array(z.object({
    name: z.string().min(1, 'Stop name is required'),
    distFromStartKm: z.number().min(0, 'Distance must be 0 or greater')
  })),
});

/**
 * A custom component that wraps a TextField with Google Places Autocomplete
 */
const LocationAutocomplete = ({ label, placeholder, onSelect, error, helperText, defaultValue, ...props }) => {
  const inputRef = useRef(null);
  const [inputValue, setInputValue] = useState(defaultValue || '');

  useEffect(() => {
    if (!window.google || !inputRef.current) return;

    const autocomplete = new window.google.maps.places.Autocomplete(inputRef.current, {
      componentRestrictions: { country: "lk" }, // Restricted to Sri Lanka
      fields: ["formatted_address", "geometry", "name"],
      types: ["geocode", "establishment"]
    });

    autocomplete.addListener("place_changed", () => {
      const place = autocomplete.getPlace();
      if (place.name || place.formatted_address) {
        const value = place.name || place.formatted_address;
        setInputValue(value);
        onSelect(value, place);
      }
    });
  }, [onSelect]);

  useEffect(() => {
    if (defaultValue !== undefined) setInputValue(defaultValue);
  }, [defaultValue]);

  return (
    <TextField
      {...props}
      inputRef={inputRef}
      label={label}
      placeholder={placeholder}
      value={inputValue}
      onChange={(e) => setInputValue(e.target.value)}
      error={error}
      helperText={helperText}
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">
            <LocationOn fontSize="small" color="primary" />
          </InputAdornment>
        ),
        ...props.InputProps
      }}
    />
  );
};

export const RouteFormDialog = ({ open, onClose, onSubmit, initialData }) => {
  const theme = useTheme();
  const [calculating, setCalculating] = useState(false);
  const [durationText, setDurationText] = useState('');
  const [apiError, setApiError] = useState(null);
  
  // Map-related refs
  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const directionsRenderer = useRef(null);
  const directionsService = useRef(null);
  
  const {
    register,
    control,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors, isSubmitting }
  } = useForm({
    resolver: zodResolver(routeSchema),
    defaultValues: {
      routeNumber: '',
      name: '',
      startPoint: '',
      endPoint: '',
      totalDistanceKm: 0,
      totalDurationMin: 0,
      stops: []
    }
  });

  const { fields, append, remove, move } = useFieldArray({
    control,
    name: "stops"
  });

  const startPoint = watch('startPoint');
  const endPoint = watch('endPoint');
  const stops = watch('stops');
  const totalDistanceKm = watch('totalDistanceKm');

  // Initialize Map
  useEffect(() => {
    if (open && mapRef.current && !mapInstance.current && window.google) {
      try {
        mapInstance.current = new window.google.maps.Map(mapRef.current, {
          center: { lat: 7.8731, lng: 80.7718 }, // Center of Sri Lanka
          zoom: 7,
          disableDefaultUI: true,
          zoomControl: true
        });

        directionsService.current = new window.google.maps.DirectionsService();
        directionsRenderer.current = new window.google.maps.DirectionsRenderer({
          map: mapInstance.current,
          suppressMarkers: false,
          polylineOptions: {
            strokeColor: theme.palette.primary.main,
            strokeWeight: 5,
            strokeOpacity: 0.8
          }
        });

        // Trigger resize after a short delay to ensure Dialog is ready
        setTimeout(() => {
          if (mapInstance.current) {
            window.google.maps.event.trigger(mapInstance.current, "resize");
            mapInstance.current.setCenter({ lat: 7.8731, lng: 80.7718 });
          }
        }, 1000);

        setApiError(null);
      } catch (e) {
        console.error("Map init error:", e);
        setApiError("Failed to initialize map. Ensure 'Maps JavaScript API' is enabled.");
      }
    }
    // Cleanup removed to prevent destroying refs on every render
  }, [open, theme.palette.primary.main]);

  // Auto-generate name from start and end points
  useEffect(() => {
    if (startPoint && endPoint) {
      const start = startPoint.split(',')[0];
      const end = endPoint.split(',')[0];
      setValue('name', `${start} - ${end}`);
    }
  }, [startPoint, endPoint, setValue]);

  // Reset form when dialog opens/closes or initialData changes
  useEffect(() => {
    if (open) {
      if (initialData) {
        reset({
          routeNumber: initialData.routeNumber || '',
          name: initialData.name || '',
          startPoint: initialData.startPoint || '',
          endPoint: initialData.endPoint || '',
          totalDistanceKm: initialData.totalDistanceKm || 0,
          totalDurationMin: initialData.totalDurationMin || 0,
          stops: (initialData.stops || []).map(s => ({ ...s }))
        });
      } else {
        reset({
          routeNumber: '',
          name: '',
          startPoint: '',
          endPoint: '',
          totalDistanceKm: 0,
          totalDurationMin: 0,
          stops: []
        });
      }
    }
  }, [open, initialData, reset]);

  const lastCalculationRef = useRef("");

  /**
   * Sequential route calculation and map preview update
   */
  const recalculateRoute = useCallback(async () => {
    if (!startPoint || !endPoint || !window.google || !directionsService.current) return;

    // Create a signature of the current inputs to prevent redundant calls
    const waypointsNames = stops.map(s => s.name).filter(n => !!n);
    const currentSignature = JSON.stringify({ startPoint, endPoint, waypointsNames });
    
    if (currentSignature === lastCalculationRef.current) return;

    setCalculating(true);
    setApiError(null);

    const waypoints = waypointsNames.map(name => ({
      location: name,
      stopover: true
    }));

    try {
      const result = await directionsService.current.route({
        origin: startPoint,
        destination: endPoint,
        waypoints: waypoints,
        travelMode: window.google.maps.TravelMode.DRIVING,
        optimizeWaypoints: false
      });

      if (result && result.routes && result.routes[0]) {
        const route = result.routes[0];
        lastCalculationRef.current = currentSignature; // Mark this signature as calculated
        
        directionsRenderer.current.setDirections(result);
        if (mapInstance.current) {
          mapInstance.current.fitBounds(route.bounds);
        }

        let cumulativeDistance = 0;
        let totalTimeSec = 0;
        const updatedStops = [...stops];
        let hasChanges = false;

        route.legs.forEach((leg, index) => {
          totalTimeSec += leg.duration.value;
          if (index < route.legs.length - 1) {
            cumulativeDistance += leg.distance.value;
            const newDist = Math.round(cumulativeDistance / 1000);
            if (updatedStops[index] && updatedStops[index].distFromStartKm !== newDist) {
              updatedStops[index].distFromStartKm = newDist;
              hasChanges = true;
            }
          } else {
            cumulativeDistance += leg.distance.value;
          }
        });

        const totalDistance = Math.round(cumulativeDistance / 1000);
        const totalMinutes = Math.round(totalTimeSec / 60);

        if (totalDistance !== watch('totalDistanceKm')) hasChanges = true;

        if (hasChanges) {
          setValue('stops', updatedStops, { shouldValidate: true });
          setValue('totalDistanceKm', totalDistance, { shouldValidate: true });
          setValue('totalDurationMin', totalMinutes, { shouldValidate: true });
        }

        setDurationText(totalTimeSec >= 3600 
          ? `${Math.floor(totalMinutes / 60)}h ${totalMinutes % 60}m` 
          : `${totalMinutes}m`);
      } else {
        setApiError("No route found. Check your locations.");
      }
    } catch (error) {
      console.error("Directions error:", error);
      const errorMsg = error?.code || error?.message || "Check API activation.";
      setApiError(`Calculation failed: ${errorMsg}`);
    } finally {
      setCalculating(false);
    }
  }, [startPoint, endPoint, stops, setValue, watch]);

  // Trigger recalculation when points change (Debounced)
  const stopsNames = JSON.stringify(stops.map(s => s.name));
  useEffect(() => {
    if (!startPoint || !endPoint) return;
    
    const timer = setTimeout(() => {
      recalculateRoute();
    }, 1500);
    return () => clearTimeout(timer);
  }, [startPoint, endPoint, stopsNames, recalculateRoute]);

  const handleFormSubmit = async (data) => {
    await onSubmit(data);
    onClose();
  };

  return (
    <Dialog 
      open={open} 
      onClose={onClose}
      fullWidth
      maxWidth="lg"
      keepMounted
      PaperProps={{
        sx: {
          backgroundColor: theme.palette.background.paper,
          backgroundImage: 'none',
          boxShadow: '0 24px 48px rgba(0,0,0,0.5)',
          border: '1px solid rgba(255,255,255,0.1)',
          borderRadius: 3,
          overflow: 'hidden'
        }
      }}
    >
      <DialogTitle sx={{ 
        fontWeight: 700, 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'space-between',
        p: 3,
        backgroundColor: 'rgba(255,255,255,0.02)',
        borderBottom: '1px solid rgba(255,255,255,0.05)'
      }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{ 
            p: 1, 
            borderRadius: 1.5, 
            backgroundColor: 'primary.main', 
            display: 'flex',
            boxShadow: `0 0 20px ${theme.palette.primary.main}44`
          }}>
            <RouteIcon sx={{ color: '#fff' }} />
          </Box>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              {initialData ? 'Edit Route' : 'Route Builder'}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Plan and optimize bus routes with real-time mapping
            </Typography>
          </Box>
        </Box>
      </DialogTitle>
      
      <form onSubmit={handleSubmit(handleFormSubmit)}>
        <DialogContent sx={{ 
          p: 0, 
          height: '75vh', 
          minHeight: '600px',
          overflow: 'hidden' 
        }}>
          <Grid container sx={{ height: '100%' }}>
            {/* Left Column: Form Controls */}
            <Grid item xs={12} md={5.5} sx={{ 
              p: 3, 
              overflowY: 'auto', 
              borderRight: '1px solid rgba(255,255,255,0.05)',
              display: 'flex',
              flexDirection: 'column',
              gap: 3
            }}>
              <Box sx={{ display: 'flex', gap: 2 }}>
                <TextField
                  size="small"
                  sx={{ width: '100px' }}
                  label="Number"
                  placeholder="e.g., 48"
                  {...register('routeNumber')}
                  error={!!errors.routeNumber}
                  InputLabelProps={{ shrink: true }}
                />
                <TextField
                  size="small"
                  sx={{ flex: 1 }}
                  label="Route Name"
                  placeholder="Automatically generated..."
                  {...register('name')}
                  error={!!errors.name}
                  InputLabelProps={{ shrink: true }}
                />
              </Box>

              <Box>
                <Typography variant="subtitle2" color="primary" sx={{ mb: 2, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, fontSize: '0.7rem' }}>
                  Main Journey Points
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <Controller
                    name="startPoint"
                    control={control}
                    render={({ field }) => (
                      <LocationAutocomplete
                        fullWidth
                        size="small"
                        label="Start Location (Origin)"
                        placeholder="e.g., Colombo Fort"
                        defaultValue={field.value}
                        onSelect={(val) => field.onChange(val)}
                        error={!!errors.startPoint}
                        InputLabelProps={{ shrink: true }}
                      />
                    )}
                  />
                  <Controller
                    name="endPoint"
                    control={control}
                    render={({ field }) => (
                      <LocationAutocomplete
                        fullWidth
                        size="small"
                        label="End Location (Destination)"
                        placeholder="e.g., Kalmunai Station"
                        defaultValue={field.value}
                        onSelect={(val) => field.onChange(val)}
                        error={!!errors.endPoint}
                        InputLabelProps={{ shrink: true }}
                      />
                    )}
                  />
                </Box>
              </Box>

              <Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="subtitle2" color="primary" sx={{ fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, fontSize: '0.7rem' }}>
                    Stops & Waypoints
                  </Typography>
                  <Button 
                    variant="text"
                    startIcon={<Add />} 
                    size="small" 
                    onClick={() => append({ name: '', distFromStartKm: 0 })}
                  >
                    Add Stop
                  </Button>
                </Box>
                
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                  {fields.map((field, index) => (
                    <Box key={field.id} sx={{ 
                      display: 'flex', 
                      gap: 1, 
                      alignItems: 'flex-start',
                      p: 1.5,
                      borderRadius: 2,
                      backgroundColor: 'rgba(255,255,255,0.02)',
                      border: '1px solid rgba(255,255,255,0.05)',
                      transition: '0.2s',
                      '&:hover': { backgroundColor: 'rgba(255,255,255,0.04)' }
                    }}>
                      <Box sx={{ display: 'flex', flexDirection: 'column', mt: 0.5 }}>
                        <IconButton size="small" onClick={() => move(index, index - 1)} disabled={index === 0} sx={{ p: 0 }}>
                          <ArrowUpward sx={{ fontSize: 16 }} />
                        </IconButton>
                        <IconButton size="small" onClick={() => move(index, index + 1)} disabled={index === fields.length - 1} sx={{ p: 0 }}>
                          <ArrowDownward sx={{ fontSize: 16 }} />
                        </IconButton>
                      </Box>

                      <Box sx={{ flex: 3 }}>
                        <Controller
                          name={`stops.${index}.name`}
                          control={control}
                          render={({ field: stopField }) => (
                            <LocationAutocomplete
                              fullWidth
                              size="small"
                              label={`Stop ${index + 1}`}
                              defaultValue={stopField.value}
                              onSelect={(val) => stopField.onChange(val)}
                              error={!!errors.stops?.[index]?.name}
                              InputLabelProps={{ shrink: true }}
                            />
                          )}
                        />
                      </Box>
                      
                      <Box sx={{ flex: 1.2 }}>
                        <TextField
                          {...register(`stops.${index}.distFromStartKm`, { valueAsNumber: true })}
                          fullWidth
                          size="small"
                          label="Km"
                          InputLabelProps={{ shrink: true }}
                          InputProps={{
                            readOnly: true,
                            sx: { fontSize: '0.8rem' },
                            startAdornment: <Straighten sx={{ fontSize: 14, mr: 0.5, opacity: 0.5 }} />
                          }}
                        />
                      </Box>

                      <IconButton color="error" size="small" onClick={() => remove(index)} sx={{ mt: 0.5 }}>
                        <Delete sx={{ fontSize: 18 }} />
                      </IconButton>
                    </Box>
                  ))}
                  {fields.length === 0 && (
                    <Typography variant="body2" color="text.secondary" sx={{ textAlign: 'center', py: 2, fontStyle: 'italic' }}>
                      No intermediate stops added
                    </Typography>
                  )}
                </Box>
              </Box>
            </Grid>

            {/* Right Column: Map Preview */}
            <Grid 
              item 
              xs={12} 
              md={6.5} 
              sx={{ 
                backgroundColor: '#111', 
                position: 'relative', 
                overflow: 'hidden',
                minHeight: '500px',
                height: '100%'
              }}
            >
              <Box 
                ref={mapRef} 
                sx={{ 
                  width: '100%', 
                  height: '100%',
                  minHeight: '500px',
                  backgroundColor: '#222'
                }} 
              />
              
              {!window.google && (
                <Box sx={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#1a1a1a', p: 4, textAlign: 'center' }}>
                  <Typography color="error" variant="body2">Google Maps Script failed to load. Check your internet or API key.</Typography>
                </Box>
              )}

              {calculating && (
                <Box sx={{ 
                  position: 'absolute', 
                  top: '50%', 
                  left: '50%', 
                  transform: 'translate(-50%, -50%)',
                  backgroundColor: 'rgba(0,0,0,0.85)',
                  px: 3,
                  py: 2,
                  borderRadius: 2,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 2,
                  backdropFilter: 'blur(10px)',
                  border: '1px solid rgba(255,152,0,0.3)',
                  boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
                  zIndex: 10
                }}>
                  <CircularProgress size={20} thickness={5} sx={{ color: '#ff9800' }} />
                  <Typography variant="button" sx={{ color: '#ff9800', fontWeight: 800, letterSpacing: 1.5 }}>Recalculating...</Typography>
                </Box>
              )}

              {apiError && (
                <Paper sx={{ 
                  position: 'absolute', 
                  top: 24, 
                  left: 24, 
                  right: 24, 
                  p: 2.5, 
                  backgroundColor: 'rgba(211, 47, 47, 0.95)', 
                  color: '#fff',
                  borderRadius: 2,
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 1,
                  boxShadow: '0 12px 48px rgba(0,0,0,0.6)',
                  border: '1px solid rgba(255,255,255,0.3)',
                  zIndex: 20
                }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <LocationOn sx={{ color: '#fff' }} />
                    <Typography variant="subtitle2" sx={{ fontWeight: 800, textTransform: 'uppercase' }}>API Connection Warning</Typography>
                  </Box>
                  <Typography variant="caption" sx={{ opacity: 0.9, lineHeight: 1.4 }}>
                    {apiError}
                    <br />
                    <span style={{ fontWeight: 700, marginTop: '8px', display: 'block' }}>
                      Required: Maps JavaScript API & Directions API
                    </span>
                  </Typography>
                </Paper>
              )}
            </Grid>
          </Grid>
        </DialogContent>
        
        <DialogActions sx={{ 
          p: 2, 
          px: 3,
          backgroundColor: '#000',
          borderTop: '1px solid rgba(255,255,255,0.05)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          {/* Stats Bar in Bottom Left */}
          <Box sx={{ display: 'flex', gap: 1.5 }}>
            <Box sx={{ 
              height: 44, 
              backgroundColor: '#111', 
              border: '1px solid rgba(255,255,255,0.1)', 
              borderRadius: 1.5, 
              px: 2, 
              display: 'flex', 
              alignItems: 'center', 
              gap: 1 
            }}>
              <Navigation sx={{ color: '#ff9800', fontSize: 18 }} />
              <Typography sx={{ color: '#ff9800', fontWeight: 800, fontSize: '0.9rem' }}>
                {totalDistanceKm || 0} <span style={{ opacity: 0.6, fontSize: '0.7rem' }}>KM</span>
              </Typography>
            </Box>

            <Box sx={{ 
              height: 44, 
              backgroundColor: '#111', 
              border: '1px solid rgba(255,255,255,0.1)', 
              borderRadius: 1.5, 
              px: 2, 
              display: 'flex', 
              alignItems: 'center', 
              gap: 1 
            }}>
              <Timer sx={{ color: '#ff9800', fontSize: 18 }} />
              <Typography sx={{ color: '#ff9800', fontWeight: 800, fontSize: '0.9rem' }}>
                {durationText || '--'}
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', gap: 1.5 }}>
            <Button onClick={onClose} color="inherit" sx={{ fontWeight: 600, color: 'rgba(255,255,255,0.4)' }}>Cancel</Button>
            <Button 
              type="submit" 
              variant="contained" 
              disabled={isSubmitting || calculating}
              size="large"
              startIcon={<RouteIcon />}
              sx={{ 
                height: 44,
                px: 5, 
                borderRadius: 1.5,
                fontWeight: 800,
                backgroundColor: '#ff9800',
                color: '#000',
                '&:hover': { backgroundColor: '#e68a00' },
                boxShadow: '0 8px 24px rgba(255, 152, 0, 0.2)'
              }}
            >
              {isSubmitting ? 'Saving...' : 'Save Bus Route'}
            </Button>
          </Box>
        </DialogActions>
      </form>
    </Dialog>
  );
};
