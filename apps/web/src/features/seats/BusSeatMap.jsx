import { Box, Paper, Typography, CircularProgress } from '@mui/material';
import { RadioButtonChecked } from '@mui/icons-material';
import Seat from './Seat';
import { useSeatMap } from './useSeatMap';
import { getBusGridTemplate, generateBusLayout } from './SeatLayouts';

/**
 * Main Bus Seat Map Component
 * Renders the dynamic grid based on layout type
 */
const BusSeatMap = ({ rideId, layoutType, selectedSeats, onSeatSelect, routeStops }) => {
  const { seats, loading, error } = useSeatMap(rideId);

  if (loading) return (
    <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
      <CircularProgress />
    </Box>
  );

  if (error) return (
    <Box sx={{ p: 2, textAlign: 'center' }}>
      <Typography color="error" variant="body2" sx={{ mb: 1 }}>Failed to load seat layout</Typography>
      <Typography variant="caption" sx={{ opacity: 0.7 }}>{error.message || String(error)}</Typography>
    </Box>
  );

  const fullLayout = generateBusLayout(layoutType);
  
  // Merge live status from Firestore onto the blueprint layout
  const gridTemplate = getBusGridTemplate(layoutType);
  const displaySeats = fullLayout.map(blueprintSeat => {
    // If it's a structural element (aisle/spacer), return as is
    if (blueprintSeat.isAisle || blueprintSeat.isSpacer) return blueprintSeat;
    
    // If it's a seat, find the live status from Firestore
    const liveData = seats.find(s => String(s.seatNumber) === String(blueprintSeat.seatNumber));
    
    let partialRatio = 0;
    let computedStatus = liveData ? liveData.status : 'available';
    let isFullySold = false;
    
    if (liveData && ['reserved', 'booked', 'occupied', 'sold'].includes(liveData.status)) {
        const origin = liveData.origin || liveData.pickup;
        const destination = liveData.destination || liveData.dropoff;
        
        if (origin && destination && routeStops && routeStops.length > 1) {
            const oIdx = routeStops.indexOf(origin);
            const dIdx = routeStops.indexOf(destination);
            
            if (oIdx !== -1 && dIdx !== -1) {
                const bookedSegments = Math.abs(dIdx - oIdx);
                const totalSegments = routeStops.length - 1;
                partialRatio = bookedSegments / totalSegments;
                
                if (partialRatio >= 1 || computedStatus === 'sold') {
                    isFullySold = true;
                    computedStatus = 'booked';
                } else {
                    computedStatus = 'partial';
                }
            } else if (computedStatus === 'sold') {
                isFullySold = true;
                computedStatus = 'booked';
            }
        } else if (computedStatus === 'sold' || computedStatus === 'booked') {
            isFullySold = true;
            computedStatus = 'booked';
        }
    }

    return { ...blueprintSeat, ...liveData, partialRatio, status: computedStatus, isFullySold, isFareBreakdown: Array.isArray(liveData?.segments) && liveData.segments.length > 1 };
  });

  return (
    <Box sx={{ maxWidth: layoutType === '54' ? 280 : 240, mx: 'auto', p: 1 }}>
      {/* Bus Front Section with Steering Wheel on Top Right */}

      <Box sx={{ 
        display: 'grid', 
        gridTemplateColumns: gridTemplate, 
        mb: 1.5,
        px: 1.5
      }}>
        <Box sx={{ gridColumnStart: layoutType === '54' ? 6 : 5, display: 'flex', justifyContent: 'center' }}>
          <Box sx={{ 
            width: 32, 
            height: 32, 
            borderRadius: '50%', 
            backgroundColor: '#CBD5E1', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            border: '2px solid #94A3B8'
          }}>
             <RadioButtonChecked sx={{ fontSize: 18, color: '#1E293B' }} />
          </Box>
        </Box>
      </Box>

      {/* Main Seat Grid */}
      <Paper elevation={0} sx={{ 
        p: 2, 
        borderRadius: 2, 
        border: '2px solid #E2E8F0',
        backgroundColor: '#FFFFFF',
        position: 'relative'
      }}>
        <Box sx={{ 
          display: 'grid', 
          gridTemplateColumns: gridTemplate, 
          gap: 1.0,
          justifyItems: 'center'
        }}>
          {displaySeats.map((seat, index) => (
            <Seat 
              key={seat.id || `blueprint_${index}`} 
              seat={seat} 
              isSelected={selectedSeats.includes(seat.seatNumber)}
              onSelect={onSeatSelect} 
            />
          ))}
        </Box>
      </Paper>

      {/* Legend */}
      <Box sx={{ mt: 2, display: 'flex', justifyContent: 'space-around', flexWrap: 'wrap', gap: 1 }}>
         <LegendItem color="#FFFFFF" label="Avail." border="#E2E8F0" />
         <LegendItem color="#22C55E" label="Selected" border="#16a34a" />
         <LegendItem color="#94A3B8" label="Booked" border="#64748b" />
         <LegendItem color="rgba(99,102,241,0.55)" label="Fare Breakdown" border="#6366F1" fareBreakdown />
      </Box>
    </Box>
  );
};

const LegendItem = ({ color, label, border, fareBreakdown }) => (
  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.8 }}>
    <Box sx={{ position: 'relative', width: 16, height: 16, flexShrink: 0 }}>
      <Box sx={{ 
        width: 16, 
        height: 16, 
        borderRadius: '4px', 
        backgroundColor: color, 
        border: `1px solid ${border}` 
      }} />
      {fareBreakdown && (
        <Box sx={{
          position: 'absolute',
          top: -3,
          right: -3,
          width: 8,
          height: 8,
          borderRadius: '50%',
          bgcolor: '#6366F1',
          border: '1px solid #fff',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 5,
          color: '#fff',
          fontWeight: 900,
        }}>
          &#8644;
        </Box>
      )}
    </Box>
    <Typography variant="caption" color="text.secondary">{label}</Typography>
  </Box>
);

export default BusSeatMap;
