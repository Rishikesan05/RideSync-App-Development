import React, { useEffect, useRef, useState } from 'react';
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
  Button
} from '@mui/material';
import {
  DirectionsBus,
  People,
  Speed,
  Room,
  Timer,
  Navigation,
  CompassCalibration
} from '@mui/icons-material';
import { collection, getDocs, doc, getDoc, query, where } from 'firebase/firestore';
import { db } from '../../api/firebase';

export const LiveMapView = () => {
  const theme = useTheme();
  
  const [loading, setLoading] = useState(true);
  const [schedules, setSchedules] = useState([]);
  const [selectedSchedule, setSelectedSchedule] = useState(null);
  const [selectedRoute, setSelectedRoute] = useState(null);
  
  // Map and simulation state
  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const directionsRenderer = useRef(null);
  const directionsService = useRef(null);
  const busMarker = useRef(null);
  const [busPosition, setBusPosition] = useState(null);
  const [busSpeed, setBusSpeed] = useState(60); // km/h
  const [pathPoints, setPathPoints] = useState([]);
  const [currentIndex, setCurrentIndex] = useState(0);

  // Fetch active schedules
  useEffect(() => {
    const fetchSchedules = async () => {
      try {
        setLoading(true);
        // Get active/scheduled schedules
        const snapshot = await getDocs(collection(db, 'schedules'));
        const list = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        
        // Filter out completed ones, keep scheduled or active
        const activeList = list.filter(s => s.status === 'active' || s.status === 'scheduled');
        setSchedules(activeList);
        
        if (activeList.length > 0) {
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
    if (!selectedSchedule || !selectedSchedule.routeId) return;
    
    const fetchRoute = async () => {
      try {
        const routeDoc = await getDoc(doc(db, 'routes', selectedSchedule.routeId));
        if (routeDoc.exists()) {
          setSelectedRoute(routeDoc.data());
          // Reset simulation
          setPathPoints([]);
          setCurrentIndex(0);
          setBusPosition(null);
        }
      } catch (err) {
        console.error('Error fetching route:', err);
      }
    };
    fetchRoute();
  }, [selectedSchedule]);

  // Initialize Map
  useEffect(() => {
    if (!selectedRoute) return;

    const initMap = () => {
      if (window.google && window.google.maps && mapRef.current) {
        if (!mapInstance.current) {
          mapInstance.current = new window.google.maps.Map(mapRef.current, {
            center: { lat: 7.8731, lng: 80.7718 }, // Center of Sri Lanka
            zoom: 8,
            styles: theme.palette.mode === 'dark' ? [
              { elementType: 'geometry', stylers: [{ color: '#1e293b' }] },
              { elementType: 'labels.text.stroke', stylers: [{ color: '#1e293b' }] },
              { elementType: 'labels.text.fill', stylers: [{ color: '#94a3b8' }] },
              { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#0f172a' }] },
              { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#1e293b' }] },
              { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#020617' }] },
            ] : []
          });

          directionsService.current = new window.google.maps.DirectionsService();
          directionsRenderer.current = new window.google.maps.DirectionsRenderer({
            map: mapInstance.current,
            suppressMarkers: true,
            polylineOptions: {
              strokeColor: theme.palette.primary.main,
              strokeWeight: 5,
              strokeOpacity: 0.8
            }
          });
        }

        // Draw Route & Get coordinates
        const waypoints = (selectedRoute.stops || [])
          .map(stop => ({
            location: `${stop.name}, Sri Lanka`,
            stopover: true
          }));

        directionsService.current.route({
          origin: `${selectedRoute.startPoint}, Sri Lanka`,
          destination: `${selectedRoute.endPoint}, Sri Lanka`,
          waypoints: waypoints,
          travelMode: window.google.maps.TravelMode.DRIVING
        }, (result, status) => {
          if (status === 'OK' && result.routes.length > 0) {
            directionsRenderer.current.setDirections(result);
            
            const points = result.routes[0].overview_path;
            setPathPoints(points);
            
            // Auto fit bounds
            mapInstance.current.fitBounds(result.routes[0].bounds);

            // Add custom start and end markers
            new window.google.maps.Marker({
              position: points[0],
              map: mapInstance.current,
              label: 'A',
              title: selectedRoute.startPoint
            });

            new window.google.maps.Marker({
              position: points[points.length - 1],
              map: mapInstance.current,
              label: 'B',
              title: selectedRoute.endPoint
            });
          }
        });
      }
    };

    const interval = setTimeout(initMap, 500);
    return () => clearTimeout(interval);
  }, [selectedRoute, theme.palette.mode]);

  // Live Bus Position Simulation
  useEffect(() => {
    if (pathPoints.length === 0 || !mapInstance.current) return;

    // Reset previous marker
    if (busMarker.current) {
      busMarker.current.setMap(null);
    }

    const startPos = pathPoints[currentIndex];
    busMarker.current = new window.google.maps.Marker({
      position: startPos,
      map: mapInstance.current,
      icon: {
        url: 'https://cdn-icons-png.flaticon.com/512/3448/3448339.png',
        scaledSize: new window.google.maps.Size(42, 42),
        anchor: new window.google.maps.Point(21, 21)
      },
      title: selectedSchedule?.plateNumber || 'Bus'
    });

    const timer = setInterval(() => {
      setCurrentIndex((prev) => {
        const next = (prev + 1) % pathPoints.length;
        const nextPos = pathPoints[next];
        
        if (busMarker.current) {
          busMarker.current.setPosition(nextPos);
        }
        
        // Randomize speed slightly for realistic look
        setBusSpeed((prevSpeed) => {
          const delta = (Math.random() - 0.5) * 10;
          const newSpeed = prevSpeed + delta;
          return Math.max(40, Math.min(80, newSpeed));
        });
        
        return next;
      });
    }, 3000);

    return () => clearInterval(timer);
  }, [pathPoints]);

  return (
    <Box sx={{ flexGrow: 1, height: 'calc(100vh - 120px)' }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Fleet Live Tracking</Typography>
        <Chip 
          icon={<CompassCalibration />}
          label="REAL-TIME MONITORING" 
          color="success" 
          variant="outlined" 
          sx={{ fontWeight: 'bold', fontSize: '0.8rem' }}
        />
      </Box>

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
                  return (
                    <ListItemButton
                      key={s.id}
                      selected={isSelected}
                      onClick={() => setSelectedSchedule(s)}
                      sx={{
                        borderBottom: '1px solid rgba(255,255,255,0.03)',
                        '&.Mui-selected': {
                          backgroundColor: 'rgba(245, 158, 11, 0.08)',
                          borderLeft: '4px solid',
                          borderColor: theme.palette.primary.main,
                        }
                      }}
                    >
                      <ListItemIcon sx={{ color: isSelected ? 'primary.main' : 'text.secondary' }}>
                        <DirectionsBus />
                      </ListItemIcon>
                      <ListItemText
                        primary={s.plateNumber}
                        secondary={s.routeName}
                        primaryTypographyProps={{ fontWeight: 700 }}
                        secondaryTypographyProps={{ noWrap: true, variant: 'caption' }}
                      />
                      <Chip
                        label={s.status}
                        color={s.status === 'active' ? 'success' : 'warning'}
                        size="small"
                        sx={{ fontSize: '0.65rem', height: 18 }}
                      />
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
                
                {/* Stats overlays */}
                <Box sx={{
                  position: 'absolute',
                  top: 16,
                  left: 16,
                  backgroundColor: 'rgba(15, 23, 42, 0.9)',
                  backdropFilter: 'blur(10px)',
                  border: '1px solid rgba(255,255,255,0.05)',
                  borderRadius: 2,
                  p: 2,
                  maxWidth: 320,
                  zIndex: 10
                }}>
                  <Typography variant="h6" sx={{ fontWeight: 700, color: 'primary.main' }}>
                    {selectedSchedule.plateNumber}
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600, mb: 1.5 }}>
                    {selectedSchedule.routeName}
                  </Typography>
                  <Divider sx={{ borderColor: 'rgba(255,255,255,0.05)', my: 1 }} />
                  
                  <Grid container spacing={2} sx={{ mt: 0.5 }}>
                    <Grid item xs={6}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <People color="primary" sx={{ fontSize: 18 }} />
                        <Box>
                          <Typography variant="caption" color="text.secondary" display="block">Passengers</Typography>
                          <Typography variant="body2" sx={{ fontWeight: 700 }}>24 / {selectedSchedule.capacity || 40}</Typography>
                        </Box>
                      </Box>
                    </Grid>
                    <Grid item xs={6}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Speed color="primary" sx={{ fontSize: 18 }} />
                        <Box>
                          <Typography variant="caption" color="text.secondary" display="block">Speed</Typography>
                          <Typography variant="body2" sx={{ fontWeight: 700 }}>{busSpeed.toFixed(0)} km/h</Typography>
                        </Box>
                      </Box>
                    </Grid>
                  </Grid>
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
