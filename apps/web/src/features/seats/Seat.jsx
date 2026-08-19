import React from 'react';
import { Box, Typography, Tooltip } from '@mui/material';
import { styled } from '@mui/material/styles';
import { motion } from 'framer-motion';
import { CallSplit as CallSplitIcon } from '@mui/icons-material';

/**
 * Atomic Seat Component
 * Handles visual states: Available, Selected, Reserved/Booked, Fare Breakdown.
 * Fare-breakdown seats (shared by multiple passengers on different journey legs)
 * are rendered with a purple tint and a small split-icon badge on the corner.
 */

const SeatContainer = styled(motion.div)(({ status, type, partialRatio, isfareBdown }) => ({
  width: '100%',
  aspectRatio: '1/1',
  borderRadius: '6px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  cursor: type === 'driver' ? 'default' : 'pointer',
  border: '1.5px solid',
  transition: 'all 0.2s ease',
  position: 'relative',
  
  // Dynamic Backgrounds based on status
  background: 
    status === 'selected' ? '#22C55E' : 
    isfareBdown === 'true'
      ? 'rgba(99,102,241,0.55)'
      : ['booked', 'sold'].includes(status) ? '#22C55E' :
        status === 'partial' ? `linear-gradient(to top, #22C55E ${(partialRatio || 0) * 100}%, #FFFFFF ${(partialRatio || 0) * 100}%)` :
        ['reserved', 'occupied'].includes(status) ? '#94A3B8' : 
        '#FFFFFF',
    
  // Dynamic Borders
  borderColor: 
    status === 'selected' ? '#16a34a' : 
    isfareBdown === 'true' ? '#6366F1' :
    ['reserved', 'booked', 'occupied', 'sold'].includes(status) ? '#64748b' : 
    '#E2E8F0',

  // Text Color
  color: (status === 'available' && isfareBdown !== 'true') ? '#1E293B' : '#FFFFFF',

  // VIP / Special Types
  ...(type === 'vip' && {
    borderColor: '#F59E0B',
    boxShadow: '0 0 10px rgba(245, 158, 11, 0.3)'
  }),
  
  ...(type === 'driver' && {
     backgroundColor: '#1E293B',
     borderColor: '#0F172A',
     cursor: 'default'
  }),

  '&:hover': {
    transform: status === 'available' ? 'scale(1.05)' : 'none',
    boxShadow: (status === 'available' && isfareBdown !== 'true')
      ? '0 4px 12px rgba(0,0,0,0.1)'
      : isfareBdown === 'true'
        ? '0 4px 12px rgba(99,102,241,0.35)'
        : 'none',
  }
}));

const Seat = ({ seat, onSelect, isSelected }) => {
  if (seat.isAisle) {
    return <Box sx={{ width: '100%', aspectRatio: '1/1', visibility: 'hidden', pointerEvents: 'none' }} />;
  }

  if (seat.isSpacer) {
    return <Box sx={{ width: '100%', aspectRatio: '1/1', pointerEvents: 'none' }} />;
  }

  const displayStatus = isSelected ? 'selected' : seat.status;
  const isFareBreakdown = seat.isFareBreakdown === true;

  const tooltipLabel = isFareBreakdown
    ? `Seat ${seat.seatNumber} – Fare Breakdown (${seat.segments?.length ?? '?'} journeys)`
    : `Seat ${seat.seatNumber} - ${seat.type || 'Standard'}`;

  return (
    <Tooltip title={tooltipLabel} arrow>
      {/* Wrap in Box so the fare-breakdown badge can be positioned absolutely */}
      <Box sx={{ position: 'relative', width: '100%', aspectRatio: '1/1' }}>
        <SeatContainer
          status={displayStatus}
          type={seat.type}
          partialRatio={seat.partialRatio}
          isfareBdown={isFareBreakdown ? 'true' : 'false'}
          whileTap={{ scale: 0.95 }}
          onClick={() => seat.type !== 'driver' && onSelect(seat)}
          style={{ width: '100%', height: '100%' }}
        >
          <Typography variant="caption" sx={{ fontWeight: 700, fontSize: '0.68rem' }}>
            {seat.seatNumber}
          </Typography>
        </SeatContainer>

        {/* Fare-breakdown corner badge */}
        {isFareBreakdown && !isSelected && (
          <Box
            sx={{
              position: 'absolute',
              top: -4,
              right: -4,
              width: 13,
              height: 13,
              borderRadius: '50%',
              bgcolor: '#6366F1',
              border: '1.5px solid #fff',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              pointerEvents: 'none',
              zIndex: 2,
            }}
          >
            <CallSplitIcon sx={{ fontSize: 7, color: '#fff' }} />
          </Box>
        )}
      </Box>
    </Tooltip>
  );
};

export default React.memo(Seat);
