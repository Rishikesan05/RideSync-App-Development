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
  Box,
  Switch,
  FormControlLabel
} from '@mui/material';

const busSchema = z.object({
  plateNumber: z.string().min(2, 'Plate number must be at least 2 characters'),
  class: z.enum(['AC', 'NonAC'], {
    errorMap: () => ({ message: 'Please select a valid class (AC or NonAC)' })
  }),
  capacity: z.union([z.literal(35), z.literal(54)], {
    errorMap: () => ({ message: 'Please select a valid seat capacity' })
  }),
  operatorId: z.string().optional(),
  isActive: z.boolean().optional(),
});

export const BusFormDialog = ({ open, onClose, onSubmit, initialData }) => {
  const theme = useTheme();

  const {
    register,
    control,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting }
  } = useForm({
    resolver: zodResolver(busSchema),
    defaultValues: {
      plateNumber: '',
      class: 'NonAC',
      capacity: 54,
      operatorId: '',
      isActive: true,
      }
  });

  useEffect(() => {
    if (open) {
      if (initialData) {
        reset({
          plateNumber: initialData.plateNumber || '',
          class: initialData.class || 'NonAC',
          capacity: initialData.capacity || 54,
          operatorId: initialData.operatorId || '',
          isActive: initialData.isActive ?? true,
        });
      } else {
        reset({
          plateNumber: '',
          class: 'NonAC',
          capacity: 54,
          operatorId: '',
          isActive: true,
        });
      }
    }
  }, [open, initialData, reset]);

  const handleFormSubmit = async (data) => {
    // API expects capacity as a number
    await onSubmit({
      ...data,
      capacity: Number(data.capacity),
    });
    onClose();
  };

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
        {initialData ? 'Edit Bus' : 'Register New Bus'}
      </DialogTitle>
      
      <form onSubmit={handleSubmit(handleFormSubmit)}>
        <DialogContent dividers sx={{ borderColor: 'rgba(255,255,255,0.05)' }}>
          <TextField
            autoFocus
            fullWidth
            label="Plate Number"
            placeholder="e.g., NA-1234"
            variant="outlined"
            margin="normal"
            {...register('plateNumber')}
            error={!!errors.plateNumber}
            helperText={errors.plateNumber?.message}
            sx={{ mb: 2 }}
          />

          <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
            <FormControl fullWidth error={!!errors.class}>
              <InputLabel id="bus-class-label">Class</InputLabel>
              <Controller
                name="class"
                control={control}
                render={({ field }) => (
                  <Select
                    {...field}
                    labelId="bus-class-label"
                    label="Class"
                  >
                    <MenuItem value="NonAC">Normal (Non-A/C)</MenuItem>
                    <MenuItem value="AC">Express (A/C)</MenuItem>
                  </Select>
                )}
              />
              {errors.class && <FormHelperText>{errors.class.message}</FormHelperText>}
            </FormControl>

            <FormControl fullWidth error={!!errors.capacity}>
              <InputLabel id="bus-capacity-label">Seat Capacity</InputLabel>
              <Controller
                name="capacity"
                control={control}
                render={({ field }) => (
                  <Select
                    {...field}
                    labelId="bus-capacity-label"
                    label="Seat Capacity"
                    onChange={(e) => field.onChange(Number(e.target.value))}
                  >
                    <MenuItem value={54}>54 (2-3 Layout)</MenuItem>
                    <MenuItem value={35}>35 (2-2 Layout)</MenuItem>
                  </Select>
                )}
              />
              {errors.capacity && <FormHelperText>{errors.capacity.message}</FormHelperText>}
            </FormControl>
          </Box>

          <TextField
            fullWidth
            label="Assigned Operator ID (Optional)"
            placeholder="Enter User UID"
            variant="outlined"
            margin="normal"
            {...register('operatorId')}
            error={!!errors.operatorId}
            helperText={errors.operatorId?.message}
            sx={{ mb: initialData ? 2 : 0 }}
          />

          {initialData && (
             <Controller
              name="isActive"
              control={control}
              render={({ field }) => (
                <FormControlLabel
                  control={<Switch {...field} checked={field.value} />}
                  label={field.value ? "Status: Active" : "Status: Inactive"}
                  sx={{ mt: 1 }}
                />
              )}
            />
          )}
          
        </DialogContent>
        <DialogActions sx={{ p: 2, pr: 3 }}>
          <Button onClick={onClose} color="inherit">Cancel</Button>
          <Button type="submit" variant="contained" disabled={isSubmitting}>
            {isSubmitting ? 'Saving...' : 'Save Bus'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
