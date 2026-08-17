import React, { useEffect, useRef, useState, useMemo } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  CircularProgress,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  useTheme,
  Divider,
  Button,
  Alert,
} from '@mui/material';
import {
  DirectionsBus,
  People,
  Speed,
  Room,
  Timer,
  Navigation,
  CompassCalibration,
  FiberManualRecord,
  GpsFixed,
  GpsOff,
  Refresh,
  Schedule,
  Warning,
} from '@mui/icons-material';
import { collection, getDocs, query, where, doc, getDoc } from 'firebase/firestore';
import { db } from '../../api/firebase';
import { useLiveFleet } from '../../hooks/useLiveFleet';
import { useTripStatus, formatEta } from '../../hooks/useTripStatus';

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Returns a human-readable signal status based on the RTDB timestamp age. */
function getSignalStatus(timestamp) {
  if (!timestamp) return { label: 'No Signal', color: '#6b7280', dotColor: '#9ca3af', severity: 'offline' };
  const ageMs = Date.now() - timestamp;
  if (ageMs < 15_000) return { label: 'Live', color: '#22c55e', dotColor: '#4ade80', severity: 'live' };
  if (ageMs < 60_000) return { label: 'Delayed', color: '#eab308', dotColor: '#facc15', severity: 'delayed' };
  return { label: 'Offline', color: '#ef4444', dotColor: '#f87171', severity: 'offline' };
}

/** Formats heading degrees into compass direction text. */
function headingToCompass(deg) {
  if (deg == null) return '—';
  const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  return dirs[Math.round(deg / 45) % 8];
}

/** Resilient helper to match a schedule against live fleet RTDB keys */
function findBusLocation(fleet, schedule) {
  if (!fleet || !schedule) return null;
  if (schedule.busId && fleet[schedule.busId]) return fleet[schedule.busId];
  if (schedule.busPlateNumber && fleet[schedule.busPlateNumber]) return fleet[schedule.busPlateNumber];
  if (schedule.plateNumber && fleet[schedule.plateNumber]) return fleet[schedule.plateNumber];
  if (schedule.id && fleet[schedule.id]) return fleet[schedule.id];
  // Match case-insensitively or trimmed if direct match was not found
  for (const [key, val] of Object.entries(fleet)) {
    if (schedule.busId && key.toLowerCase() === schedule.busId.toLowerCase()) return val;
    if (schedule.busPlateNumber && key.toLowerCase() === schedule.busPlateNumber.toLowerCase()) return val;
    if (schedule.plateNumber && key.toLowerCase() === schedule.plateNumber.toLowerCase()) return val;
    if (schedule.id && key.toLowerCase() === schedule.id.toLowerCase()) return val;
  }
  return null;
}

/** Smoothly interpolates Google Maps Marker position via requestAnimationFrame */
function animateMarkerTo(marker, targetLat, targetLng, duration = 1200) {
  if (!marker || !window.google?.maps) return;
  const startPos = marker.getPosition();
  if (!startPos) {
    marker.setPosition(new window.google.maps.LatLng(targetLat, targetLng));
    return;
  }
  const startLat = startPos.lat();
  const startLng = startPos.lng();
  if (Math.abs(startLat - targetLat) < 0.000005 && Math.abs(startLng - targetLng) < 0.000005) {
    return;
  }

  if (marker._animFrameId) {
    cancelAnimationFrame(marker._animFrameId);
  }

  const startTime = performance.now();
  const step = (now) => {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    // Smooth quadratic easeInOut
    const easeProgress = progress < 0.5
      ? 2 * progress * progress
      : -1 + (4 - 2 * progress) * progress;

    const curLat = startLat + (targetLat - startLat) * easeProgress;
    const curLng = startLng + (targetLng - startLng) * easeProgress;
    marker.setPosition(new window.google.maps.LatLng(curLat, curLng));

    if (progress < 1) {
      marker._animFrameId = requestAnimationFrame(step);
    } else {
      marker._animFrameId = null;
    }
  };
  marker._animFrameId = requestAnimationFrame(step);
}

// Dark map styles for Google Maps
const DARK_MAP_STYLES = [
  { elementType: 'geometry', stylers: [{ color: '#1e293b' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#1e293b' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#94a3b8' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#0f172a' }] },
  { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#1e293b' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#020617' }] },
];

export const LiveMapView = () => {
  const theme = useTheme();

  const [loading, setLoading] = useState(true);
  const [schedules, setSchedules] = useState([]);
  const [selectedSchedule, setSelectedSchedule] = useState(null);
  const [selectedRoute, setSelectedRoute] = useState(null);

  // Real-time GPS data from RTDB
  const { fleet, isLoading: fleetLoading, error: fleetError } = useLiveFleet();

  // Gap 7: Real-time trip status (ETA, currentStop, delay) for selected schedule
  const { tripStatus } = useTripStatus(selectedSchedule?.id);

  // Map refs
  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const directionsRenderer = useRef(null);
  const directionsService = useRef(null);
  const busMarkerRef = useRef(null);
  const allBusMarkers = useRef({});

  // Fetch active schedules
  useEffect(() => {
    const fetchSchedules = async () => {
      try {
        setLoading(true);
        const snapshot = await getDocs(collection(db, 'schedules'));
        const list = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
        const activeList = list.filter(
          s => s.status === 'active' || s.status === 'in-transit' || s.status === 'scheduled'
        );
        setSchedules(activeList);
        if (activeList.length > 0 && !selectedSchedule) {
          setSelectedSchedule(activeList[0]);
        }
      } catch (err) {
        console.error('Error fetching schedules:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchSchedules();
  }, []);

  // Fetch Route data when schedule changes
  useEffect(() => {
    if (!selectedSchedule?.routeId) return;
    const fetchRoute = async () => {
      try {
        const routeDoc = await getDoc(doc(db, 'routes', selectedSchedule.routeId));
        if (routeDoc.exists()) {
          setSelectedRoute(routeDoc.data());
        }
      } catch (err) {
        console.error('Error fetching route:', err);
      }
    };
    fetchRoute();
  }, [selectedSchedule]);

  // Initialize Map & draw route
  useEffect(() => {
    if (!selectedRoute) return;
    const initMap = () => {
      if (window.google?.maps && mapRef.current) {
        if (!mapInstance.current) {
          mapInstance.current = new window.google.maps.Map(mapRef.current, {
            center: { lat: 7.8731, lng: 80.7718 },
            zoom: 8,
            styles: theme.palette.mode === 'dark' ? DARK_MAP_STYLES : [],
          });
          directionsService.current = new window.google.maps.DirectionsService();
          directionsRenderer.current = new window.google.maps.DirectionsRenderer({
            map: mapInstance.current,
            suppressMarkers: true,
            polylineOptions: {
              strokeColor: theme.palette.primary.main,
              strokeWeight: 5,
              strokeOpacity: 0.8,
            },
          });
        }

        // Draw route between start/end with intermediate stops
        const waypoints = (selectedRoute.stops || []).map(stop => ({
          location: `${stop.name}, Sri Lanka`,
          stopover: true,
        }));

        directionsService.current.route(
          {
            origin: `${selectedRoute.startPoint}, Sri Lanka`,
            destination: `${selectedRoute.endPoint}, Sri Lanka`,
            waypoints,
            travelMode: window.google.maps.TravelMode.DRIVING,
          },
          (result, status) => {
            if (status === 'OK' && result.routes.length > 0) {
              directionsRenderer.current.setDirections(result);
              mapInstance.current.fitBounds(result.routes[0].bounds);

              // Start and end markers
              const points = result.routes[0].overview_path;
              new window.google.maps.Marker({
                position: points[0],
                map: mapInstance.current,
                label: 'A',
                title: selectedRoute.startPoint,
              });
              new window.google.maps.Marker({
                position: points[points.length - 1],
                map: mapInstance.current,
                label: 'B',
                title: selectedRoute.endPoint,
              });
            }
          }
        );
      }
    };
    const timer = setTimeout(initMap, 500);
    return () => clearTimeout(timer);
  }, [selectedRoute, theme.palette.mode]);

  // ── Gap 7: Render ALL active broadcasting buses on the map simultaneously ──
  useEffect(() => {
    if (!mapInstance.current) return;

    // 1. Update or create a marker for every bus currently in the fleet
    Object.entries(fleet).forEach(([busId, loc]) => {
      if (!loc || loc.lat == null || loc.lng == null) return;
      const ageMs = Date.now() - (loc.timestamp ?? 0);
      const isStale = ageMs > 60_000;

      const position = new window.google.maps.LatLng(loc.lat, loc.lng);
      const isSelected = selectedSchedule && (
        selectedSchedule.busId === busId ||
        selectedSchedule.plateNumber === busId ||
        selectedSchedule.id === busId
      );

      if (allBusMarkers.current[busId]) {
        // Smoothly interpolate position via requestAnimationFrame
        animateMarkerTo(allBusMarkers.current[busId], loc.lat, loc.lng, 1200);
        allBusMarkers.current[busId].setOpacity(isStale ? 0.4 : 1.0);
      } else {
        // Create new marker for this bus
        allBusMarkers.current[busId] = new window.google.maps.Marker({
          position,
          map: mapInstance.current,
          icon: {
            url: 'https://cdn-icons-png.flaticon.com/512/3448/3448339.png',
            scaledSize: new window.google.maps.Size(isSelected ? 52 : 38, isSelected ? 52 : 38),
            anchor: new window.google.maps.Point(isSelected ? 26 : 19, isSelected ? 26 : 19),
          },
          title: busId,
          opacity: isStale ? 0.4 : 1.0,
        });

        // Click a fleet bus to select its schedule
        allBusMarkers.current[busId].addListener('click', () => {
          const matchedSchedule = schedules.find(s =>
            (s.busId && s.busId.toLowerCase() === busId.toLowerCase()) ||
            (s.plateNumber && s.plateNumber.toLowerCase() === busId.toLowerCase()) ||
            (s.id && s.id.toLowerCase() === busId.toLowerCase())
          );
          if (matchedSchedule) {
            setSelectedSchedule(matchedSchedule);
            mapInstance.current.panTo(position);
            mapInstance.current.setZoom(14);
          }
        });
      }
    });

    // 2. Remove markers for buses that have left the fleet
    Object.keys(allBusMarkers.current).forEach((busId) => {
      if (!fleet[busId]) {
        if (allBusMarkers.current[busId]._animFrameId) {
          cancelAnimationFrame(allBusMarkers.current[busId]._animFrameId);
        }
        allBusMarkers.current[busId].setMap(null);
        delete allBusMarkers.current[busId];
      }
    });

    // 3. Pan to selected bus if it exists
    if (selectedSchedule) {
      const loc = findBusLocation(fleet, selectedSchedule);
      if (loc && loc.lat != null && loc.lng != null) {
        mapInstance.current.panTo(new window.google.maps.LatLng(loc.lat, loc.lng));
      }
    }
  }, [fleet, selectedSchedule, schedules]);

  // ── Derive live telemetry for selected bus ────────────────────────────────
  const liveBusData = useMemo(() => {
    if (!selectedSchedule) return null;
    return findBusLocation(fleet, selectedSchedule);
  }, [fleet, selectedSchedule]);

  const signalStatus = useMemo(() => getSignalStatus(liveBusData?.timestamp), [liveBusData?.timestamp]);

  // ── Count how many buses are actively broadcasting ────────────────────────
  const activeBusCount = useMemo(() => {
    return Object.values(fleet).filter(loc => {
      const age = Date.now() - (loc.timestamp ?? 0);
      return age < 60_000;
    }).length;
  }, [fleet]);

  return (
    <Box sx={{ flexGrow: 1, height: 'calc(100vh - 120px)' }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Fleet Live Tracking</Typography>
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center' }}>
          <Chip
            icon={<GpsFixed />}
            label={`${activeBusCount} BUS${activeBusCount !== 1 ? 'ES' : ''} LIVE`}
            color="success"
            variant="outlined"
            sx={{ fontWeight: 'bold', fontSize: '0.8rem' }}
          />
          <Chip
            icon={<CompassCalibration />}
            label="REAL-TIME MONITORING"
            color="success"
            variant="outlined"
            sx={{ fontWeight: 'bold', fontSize: '0.8rem' }}
          />
        </Box>
      </Box>

      {fleetError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {fleetError} — Live tracking data may be unavailable.
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60%' }}>
          <CircularProgress color="primary" />
        </Box>
      ) : (
        <Grid container spacing={3} sx={{ height: '85%' }}>
          {/* Active Buses list */}
          <Grid item xs={12} md={3} sx={{ height: '100%', overflowY: 'auto' }}>
            <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <Box sx={{ p: 2, borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>Active Fleet</Typography>
                <Typography variant="caption" color="text.secondary">Select an active bus to track</Typography>
              </Box>
              <List sx={{ p: 0, flex: 1, overflowY: 'auto' }}>
                {schedules.map((s) => {
                  const isSelected = selectedSchedule?.id === s.id;
                  const busLoc = findBusLocation(fleet, s);
                  const busSignal = getSignalStatus(busLoc?.timestamp);

                  return (
                    <ListItemButton
                      key={s.id}
                      selected={isSelected}
                      onClick={() => {
                        setSelectedSchedule(s);
                        // Clear previous marker
                        if (busMarkerRef.current) {
                          busMarkerRef.current.setMap(null);
                          busMarkerRef.current = null;
                        }
                      }}
                      sx={{
                        borderBottom: '1px solid rgba(255,255,255,0.03)',
                        '&.Mui-selected': {
                          backgroundColor: 'rgba(245, 158, 11, 0.08)',
                          borderLeft: '4px solid',
                          borderColor: theme.palette.primary.main,
                        },
                      }}
                    >
                      <ListItemIcon sx={{ color: isSelected ? 'primary.main' : 'text.secondary', minWidth: 36 }}>
                        <DirectionsBus />
                      </ListItemIcon>
                      <ListItemText
                        primary={s.busPlateNumber || s.plateNumber || s.busId}
                        secondary={s.routeName}
                        primaryTypographyProps={{ fontWeight: 700 }}
                        secondaryTypographyProps={{ noWrap: true, variant: 'caption' }}
                      />
                      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 0.5 }}>
                        <Chip
                          label={s.status}
                          color={s.status === 'in-transit' ? 'success' : s.status === 'active' ? 'success' : 'warning'}
                          size="small"
                          sx={{ fontSize: '0.6rem', height: 18 }}
                        />
                        {/* Live signal indicator */}
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.4 }}>
                          <FiberManualRecord sx={{ fontSize: 8, color: busSignal.dotColor }} />
                          <Typography variant="caption" sx={{ fontSize: '0.55rem', color: busSignal.color, fontWeight: 600 }}>
                            {busSignal.label}
                          </Typography>
                        </Box>
                      </Box>
                    </ListItemButton>
                  );
                })}
                {schedules.length === 0 && (
                  <Box sx={{ p: 3, textAlign: 'center' }}>
                    <Typography color="text.secondary">No active schedules right now</Typography>
                  </Box>
                )}
              </List>
            </Card>
          </Grid>

          {/* Map Preview */}
          <Grid item xs={12} md={9} sx={{ height: '100%', position: 'relative' }}>
            {selectedSchedule ? (
              <Box sx={{ height: '100%', width: '100%', position: 'relative', borderRadius: 3, overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' }}>
                <Box ref={mapRef} sx={{ height: '100%', width: '100%', backgroundColor: '#222' }} />

                {/* Stats overlay — now with REAL data */}
                <Box sx={{
                  position: 'absolute',
                  top: 16,
                  left: 16,
                  backgroundColor: 'rgba(15, 23, 42, 0.92)',
                  backdropFilter: 'blur(12px)',
                  border: '1px solid rgba(255,255,255,0.08)',
                  borderRadius: 2,
                  p: 2,
                  maxWidth: 340,
                  zIndex: 10,
                }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 0.5 }}>
                    <Typography variant="h6" sx={{ fontWeight: 700, color: 'primary.main' }}>
                      {selectedSchedule.busPlateNumber || selectedSchedule.plateNumber || selectedSchedule.busId}
                    </Typography>
                    {/* Live signal badge */}
                    <Box sx={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 0.5,
                      px: 1.2,
                      py: 0.3,
                      borderRadius: '12px',
                      backgroundColor: `${signalStatus.color}22`,
                      border: `1px solid ${signalStatus.color}44`,
                    }}>
                      <FiberManualRecord sx={{
                        fontSize: 10,
                        color: signalStatus.dotColor,
                        animation: signalStatus.severity === 'live' ? 'pulse 1.5s infinite' : 'none',
                        '@keyframes pulse': {
                          '0%, 100%': { opacity: 1 },
                          '50%': { opacity: 0.4 },
                        },
                      }} />
                      <Typography variant="caption" sx={{ fontWeight: 700, color: signalStatus.color, fontSize: '0.65rem' }}>
                        {signalStatus.label}
                      </Typography>
                    </Box>
                  </Box>

                  <Typography variant="body2" sx={{ fontWeight: 600, mb: 1.5, color: 'text.primary' }}>
                    {selectedSchedule.routeName}
                  </Typography>

                  <Divider sx={{ borderColor: 'rgba(255,255,255,0.08)', my: 1 }} />

                  {liveBusData ? (
                    <Grid container spacing={2} sx={{ mt: 0.5 }}>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Speed color="primary" sx={{ fontSize: 18 }} />
                          <Box>
                            <Typography variant="caption" color="text.secondary" display="block">Speed</Typography>
                            <Typography variant="body2" sx={{ fontWeight: 700, color: 'text.primary' }}>
                              {(liveBusData.speed ?? 0).toFixed(0)} km/h
                            </Typography>
                          </Box>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Navigation color="primary" sx={{ fontSize: 18 }} />
                          <Box>
                            <Typography variant="caption" color="text.secondary" display="block">Heading</Typography>
                            <Typography variant="body2" sx={{ fontWeight: 700, color: 'text.primary' }}>
                              {headingToCompass(liveBusData.heading)} {(liveBusData.heading ?? 0).toFixed(0)}°
                            </Typography>
                          </Box>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Room color="primary" sx={{ fontSize: 18 }} />
                          <Box>
                            <Typography variant="caption" color="text.secondary" display="block">Coordinates</Typography>
                            <Typography variant="body2" sx={{ fontWeight: 700, color: 'text.primary', fontSize: '0.72rem' }}>
                              {(liveBusData.lat ?? 0).toFixed(4)}, {(liveBusData.lng ?? 0).toFixed(4)}
                            </Typography>
                          </Box>
                        </Box>
                      </Grid>
                      <Grid item xs={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <Timer color="primary" sx={{ fontSize: 18 }} />
                          <Box>
                            <Typography variant="caption" color="text.secondary" display="block">Last Update</Typography>
                            <Typography variant="body2" sx={{ fontWeight: 700, color: 'text.primary', fontSize: '0.72rem' }}>
                              {liveBusData.timestamp
                                ? `${Math.round((Date.now() - liveBusData.timestamp) / 1000)}s ago`
                                : '—'}
                            </Typography>
                          </Box>
                        </Box>
                      </Grid>

                      {/* Gap 7 — ETA & trip status from useTripStatus hook */}
                      {tripStatus && (
                        <>
                          <Grid item xs={6}>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Schedule color="success" sx={{ fontSize: 18 }} />
                              <Box>
                                <Typography variant="caption" color="text.secondary" display="block">ETA</Typography>
                                <Typography variant="body2" sx={{ fontWeight: 700, color: 'success.main' }}>
                                  {formatEta(tripStatus.eta)}
                                </Typography>
                              </Box>
                            </Box>
                          </Grid>
                          <Grid item xs={6}>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Room color="warning" sx={{ fontSize: 18 }} />
                              <Box>
                                <Typography variant="caption" color="text.secondary" display="block">Current Stop</Typography>
                                <Typography variant="body2" sx={{ fontWeight: 700, color: 'text.primary', fontSize: '0.72rem' }}>
                                  {tripStatus.currentStop ?? '—'}
                                </Typography>
                              </Box>
                            </Box>
                          </Grid>
                          {tripStatus.delayMinutes > 0 && (
                            <Grid item xs={12}>
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, bgcolor: 'warning.dark', borderRadius: 1, px: 1.5, py: 0.5 }}>
                                <Warning sx={{ fontSize: 16, color: 'warning.contrastText' }} />
                                <Typography variant="caption" sx={{ color: 'warning.contrastText', fontWeight: 700 }}>
                                  Delayed by {tripStatus.delayMinutes} min
                                </Typography>
                              </Box>
                            </Grid>
                          )}
                        </>
                      )}
                    </Grid>
                  ) : (
                    <Box sx={{ py: 2, textAlign: 'center' }}>
                      <GpsOff sx={{ fontSize: 32, color: 'text.disabled', mb: 1 }} />
                      <Typography variant="body2" color="text.secondary">
                        No GPS signal from this bus
                      </Typography>
                      <Typography variant="caption" color="text.disabled">
                        The operator has not started broadcasting yet
                      </Typography>
                    </Box>
                  )}
                </Box>
              </Box>
            ) : (
              <Card sx={{ height: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <Typography color="text.secondary">Select a schedule from the sidebar to start live tracking</Typography>
              </Card>
            )}
          </Grid>
        </Grid>
      )}
    </Box>
  );
};
