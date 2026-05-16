import { Box, Paper, Typography, CircularProgress } from '@mui/material';
import { RadioButtonChecked } from '@mui/icons-material';
import Seat from './Seat';
import { useSeatMap } from './useSeatMap';
import { getBusGridTemplate, generateBusLayout } from './SeatLayouts';

/**
 * Main Bus Seat Map Component
 * Renders the dynamic grid based on layout type
 */
const BusSeatMap = ({ rideId, layoutType, selectedSeats, onSeatSelect }) => {
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
    return { ...blueprintSeat, ...liveData };
  });

  return (
    <Box sx={{ maxWidth: 400, mx: 'auto', p: 2 }}>
      {/* Bus Front Section with Steering Wheel on Top Right */}

      <Box sx={{ 
        display: 'grid', 
        gridTemplateColumns: gridTemplate, 
        mb: 2,
        px: 3
      }}>
        <Box sx={{ gridColumnStart: layoutType === '54' ? 6 : 5, display: 'flex', justifyContent: 'center' }}>
          <Box sx={{ 
            width: 40, 
            height: 40, 
            borderRadius: '50%', 
            backgroundColor: '#CBD5E1', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            border: '2px solid #94A3B8'
          }}>
             <RadioButtonChecked sx={{ fontSize: 24, color: '#1E293B' }} />
          </Box>
        </Box>
      </Box>

      {/* Main Seat Grid */}
      <Paper elevation={0} sx={{ 
        p: 3, 
        borderRadius: 2, 
        border: '2px solid #E2E8F0',
        backgroundColor: '#FFFFFF',
        position: 'relative'
      }}>
        <Box sx={{ 
          display: 'grid', 
          gridTemplateColumns: gridTemplate,
          gap: 1.5,
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
      <Box sx={{ mt: 4, display: 'flex', justifyContent: 'space-around' }}>
         <LegendItem color="#FFFFFF" label="Avail." border="#E2E8F0" />
         <LegendItem color="#22C55E" label="Selected" border="#16a34a" />
         <LegendItem color="#94A3B8" label="Booked" border="#64748b" />
      </Box>
    </Box>
  );
};

const LegendItem = ({ color, label, border }) => (
  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
    <Box sx={{ 
      width: 16, 
      height: 16, 
      borderRadius: '4px', 
      backgroundColor: color, 
      border: `1px solid ${border}` 
    }} />
    <Typography variant="caption" color="text.secondary">{label}</Typography>
  </Box>
);

export default BusSeatMap;
