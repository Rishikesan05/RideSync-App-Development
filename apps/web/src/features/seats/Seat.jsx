import React from 'react';
import { Box, Typography, Tooltip } from '@mui/material';
import { styled } from '@mui/material/styles';
import { motion } from 'framer-motion';

/**
 * Atomic Seat Component
 * Handles visual states: Available, Selected, Reserved/Booked
 */

const SeatContainer = styled(motion.div)(({ theme, status, type }) => ({
  width: '100%',
  aspectRatio: '1/1',
  borderRadius: '8px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  cursor: status === 'available' ? 'pointer' : 'not-allowed',
  border: '2px solid',
  transition: 'all 0.2s ease',
  
  // Dynamic Backgrounds based on status
  backgroundColor: 
    status === 'selected' ? '#22C55E' : 
    ['reserved', 'booked', 'occupied', 'sold'].includes(status) ? '#94A3B8' : 
    '#FFFFFF',
    
  // Dynamic Borders
  borderColor: 
    status === 'selected' ? '#16a34a' : 
    ['reserved', 'booked', 'occupied', 'sold'].includes(status) ? '#64748b' : 
    '#E2E8F0',

  // Text Color
  color: status === 'available' ? '#1E293B' : '#FFFFFF',

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
    boxShadow: status === 'available' ? '0 4px 12px rgba(0,0,0,0.1)' : 'none'
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

  return (
    <Tooltip title={`Seat ${seat.seatNumber} - ${seat.type || 'Standard'}`} arrow>
      <SeatContainer
        status={displayStatus}
        type={seat.type}
        whileTap={{ scale: 0.95 }}
        onClick={() => seat.status === 'available' && onSelect(seat)}
      >
        <Typography variant="caption" sx={{ fontWeight: 700, fontSize: '0.75rem' }}>
          {seat.seatNumber}
        </Typography>
      </SeatContainer>
    </Tooltip>
  );
};

export default React.memo(Seat);
