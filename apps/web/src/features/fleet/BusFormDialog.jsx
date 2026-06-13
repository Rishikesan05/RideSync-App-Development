import { useEffect } from 'react';
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
  FormControlLabel,
  Typography,
  Divider,
  Chip,
} from '@mui/material';
import { DirectionsBus, AcUnit, AirlineSeatReclineNormal } from '@mui/icons-material';

/**
 * BusFormDialog — create / edit a bus in Firestore.
 *
 * Props:
 *   open          boolean   — controls dialog visibility
 *   onClose       function  — called when dialog should close
 *   onSubmit      function  — async (formData) => void; called on valid submit
 *   initialData   object    — if provided, dialog is in "edit" mode
 *   existingPlates string[] — plate numbers already registered (for dupe check)
 */

const buildSchema = (existingPlates = []) =>
  z.object({
    plateNumber: z
      .string()
      .min(2, 'Plate number must be at least 2 characters')
      .refine(
        (val) => !existingPlates.includes(val.toUpperCase().trim()),
        { message: 'This plate number is already registered' }
      ),
    class: z.enum(['AC', 'NonAC'], {
      errorMap: () => ({ message: 'Please select a valid class' }),
    }),
    capacity: z.union([z.literal(35), z.literal(54)], {
      errorMap: () => ({ message: 'Please select a valid seat capacity' }),
    }),
    model: z.string().optional(),
    year: z
      .string()
      .optional()
      .refine(
        (val) => !val || (/^\d{4}$/.test(val) && +val >= 1990 && +val <= new Date().getFullYear()),
        { message: 'Enter a valid 4-digit year (1990 – present)' }
      ),
    operatorId: z.string().optional(),
    isActive: z.boolean().optional(),
  });

export const BusFormDialog = ({ open, onClose, onSubmit, initialData, existingPlates = [] }) => {
  const theme = useTheme();
  const isEdit = Boolean(initialData);

  const schema = buildSchema(existingPlates);

  const {
    register,
    control,
    handleSubmit,
    reset,
    watch,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: {
      plateNumber: '',
      class: 'NonAC',
      capacity: 54,
      model: '',
      year: '',
      operatorId: '',
      isActive: true,
    },
  });

  const watchedClass = watch('class');

  useEffect(() => {
    if (open) {
      if (initialData) {
        reset({
          plateNumber: initialData.plateNumber || '',
          class:       initialData.class       || 'NonAC',
          capacity:    initialData.capacity    || 54,
          model:       initialData.model       || '',
          year:        initialData.year        || '',
          operatorId:  initialData.operatorId  || '',
          isActive:    initialData.isActive    ?? true,
        });
      } else {
        reset({
          plateNumber: '',
          class: 'NonAC',
          capacity: 54,
          model: '',
          year: '',
          operatorId: '',
          isActive: true,
        });
      }
    }
  }, [open, initialData, reset]);

  const handleFormSubmit = async (data) => {
    await onSubmit({
      ...data,
      plateNumber: data.plateNumber.toUpperCase().trim(),
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
          boxShadow: '0 24px 48px rgba(0,0,0,0.4)',
          border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'}`,
          borderRadius: 3,
        },
      }}
    >
      {/* ── Title ────────────────────────────────────────────────────── */}
      <DialogTitle sx={{ pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box
            sx={{
              p: 1,
              borderRadius: 2,
              bgcolor: 'rgba(230,141,51,0.12)',
              color: '#E68D33',
              display: 'flex',
            }}
          >
            <DirectionsBus />
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1 }}>
              {isEdit ? 'Edit Bus' : 'Register New Bus'}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {isEdit ? 'Update bus details in Firestore' : 'Add a new bus to your fleet'}
            </Typography>
          </Box>
          {watchedClass === 'AC' && (
            <Chip
              icon={<AcUnit sx={{ fontSize: 14 }} />}
              label="A/C"
              color="info"
              size="small"
              sx={{ ml: 'auto' }}
            />
          )}
        </Box>
      </DialogTitle>

      <form onSubmit={handleSubmit(handleFormSubmit)}>
        <DialogContent
          dividers
          sx={{ borderColor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.06)' }}
        >
          {/* ── Plate Number ───────────────────────────────────────────── */}
          <TextField
            autoFocus
            fullWidth
            label="Plate Number"
            placeholder="e.g. NA-1234"
            variant="outlined"
            margin="normal"
            {...register('plateNumber')}
            error={!!errors.plateNumber}
            helperText={errors.plateNumber?.message}
            sx={{ mb: 2 }}
            inputProps={{ style: { textTransform: 'uppercase' } }}
          />

          {/* ── Class + Capacity ───────────────────────────────────────── */}
          <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
            <FormControl fullWidth error={!!errors.class}>
              <InputLabel id="bus-class-label">Bus Class</InputLabel>
              <Controller
                name="class"
                control={control}
                render={({ field }) => (
                  <Select {...field} labelId="bus-class-label" label="Bus Class">
                    <MenuItem value="NonAC">Normal (Non-A/C)</MenuItem>
                    <MenuItem value="AC">Express (A/C)</MenuItem>
                  </Select>
                )}
              />
              {errors.class && <FormHelperText>{errors.class.message}</FormHelperText>}
            </FormControl>

            <FormControl fullWidth error={!!errors.capacity}>
              <InputLabel id="bus-capacity-label">
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                  <AirlineSeatReclineNormal sx={{ fontSize: 16 }} />
                  Seat Capacity
                </Box>
              </InputLabel>
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
                    <MenuItem value={54}>54 seats — 2-3 Layout</MenuItem>
                    <MenuItem value={35}>35 seats — 2-2 Layout</MenuItem>
                  </Select>
                )}
              />
              {errors.capacity && <FormHelperText>{errors.capacity.message}</FormHelperText>}
            </FormControl>
          </Box>

          {/* ── Model + Year ───────────────────────────────────────────── */}
          <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
            <TextField
              fullWidth
              label="Bus Model (Optional)"
              placeholder="e.g. Ashok Leyland Viking"
              variant="outlined"
              {...register('model')}
              error={!!errors.model}
              helperText={errors.model?.message}
            />
            <TextField
              fullWidth
              label="Year (Optional)"
              placeholder="e.g. 2020"
              variant="outlined"
              {...register('year')}
              error={!!errors.year}
              helperText={errors.year?.message}
              sx={{ maxWidth: 130 }}
            />
          </Box>

          {/* ── Operator ID ───────────────────────────────────────────── */}
          <TextField
            fullWidth
            label="Assigned Operator UID (Optional)"
            placeholder="Firebase User UID"
            variant="outlined"
            margin="normal"
            {...register('operatorId')}
            error={!!errors.operatorId}
            helperText={errors.operatorId?.message || "Copy the operator's UID from the Users section"}
            sx={{ mb: isEdit ? 2 : 0 }}
          />

          {/* ── Active toggle (edit mode only) ─────────────────────────── */}
          {isEdit && (
            <>
              <Divider sx={{ my: 2, borderColor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.06)' }} />
              <Controller
                name="isActive"
                control={control}
                render={({ field }) => (
                  <FormControlLabel
                    control={<Switch {...field} checked={field.value} color="success" />}
                    label={
                      <Typography variant="body2">
                        Status:{' '}
                        <strong style={{ color: field.value ? theme.palette.success.main : theme.palette.text.secondary }}>
                          {field.value ? 'Active' : 'Inactive'}
                        </strong>
                      </Typography>
                    }
                  />
                )}
              />
            </>
          )}
        </DialogContent>

        {/* ── Actions ───────────────────────────────────────────────── */}
        <DialogActions sx={{ p: 2, pr: 3, gap: 1 }}>
          <Button onClick={onClose} color="inherit" variant="outlined" sx={{ borderRadius: 2 }}>
            Cancel
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={isSubmitting}
            sx={{ borderRadius: 2, px: 3 }}
          >
            {isSubmitting ? 'Saving...' : isEdit ? 'Update Bus' : 'Register Bus'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
