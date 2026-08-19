import React, { useState } from 'react';
import { 
  Box, 
  Button, 
  FormControl, 
  InputLabel, 
  Select, 
  MenuItem, 
  Typography,
  Paper,
  Alert
} from '@mui/material';
import { initializeRideSeats } from './SeatService';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../api/firebase';

/**
 * RideSync Integration Example
 * Demonstrates how to select a bus layout during ride creation
 * and initialize the seats in Firestore.
 */
const RideCreationWithSeats = () => {
  const [layout, setLayout] = useState('54');
  const [creating, setCreating] = useState(false);
  const [rideId, setRideId] = useState(null);

  const handleCreateRide = async () => {
    setCreating(true);
    try {
      // 1. Create the ride document
      const rideRef = await addDoc(collection(db, "rides"), {
        busLayout: layout,
        createdAt: serverTimestamp(),
        status: 'pending',
        capacity: parseInt(layout)
      });

      // 2. Initialize the seat subcollection
      await initializeRideSeats(rideRef.id, layout);

      setRideId(rideRef.id);
      alert("Ride and Seat Layout created successfully!");
    } catch (error) {
      console.error("Ride creation failed:", error);
    } finally {
      setCreating(false);
    }
  };

  return (
    <Box sx={{ maxWidth: 600, p: 3 }}>
      <Paper sx={{ p: 4, borderRadius: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 800, mb: 3 }}>
          Create New Ride
        </Typography>

        <FormControl fullWidth sx={{ mb: 4 }}>
          <InputLabel>Select Bus Configuration</InputLabel>
          <Select
            value={layout}
            label="Select Bus Configuration"
            onChange={(e) => setLayout(e.target.value)}
          >
            <MenuItem value="35">35 Seat (2-2 Standard)</MenuItem>
            <MenuItem value="54">54 Seat (2-3 Semi-Luxury)</MenuItem>
          </Select>
        </FormControl>

        <Alert severity="info" sx={{ mb: 4 }}>
          This will automatically generate {layout} seat documents in Firestore for real-time booking.
        </Alert>

        <Button 
          fullWidth 
          variant="contained" 
          size="large"
          disabled={creating}
          onClick={handleCreateRide}
          sx={{ py: 2, fontWeight: 700 }}
        >
          {creating ? "Generating Seat Layout..." : "Initialize Ride & Seats"}
        </Button>

        {rideId && (
          <Box sx={{ mt: 2 }}>
            <Typography variant="caption">Created Ride ID: {rideId}</Typography>
          </Box>
        )}
      </Paper>
    </Box>
  );
};

export default RideCreationWithSeats;
