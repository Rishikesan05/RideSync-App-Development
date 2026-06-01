import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  Divider,
  Chip,
  useTheme,
} from '@mui/material';
import { DirectionsBus, Schedule as ScheduleIcon } from '@mui/icons-material';
import {
  collection,
  getDocs,
  query,
  where,
  Timestamp,
} from 'firebase/firestore';
import { db } from '../../api/firebase';

// ── helpers ──────────────────────────────────────────────────────────────────

/**
 * Formats a Firestore Timestamp or ISO string to "hh:mm AM/PM".
 */
const formatTime = (val) => {
  if (!val) return '—';
  try {
    const date =
      typeof val?.toDate === 'function' ? val.toDate() : new Date(val);
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return '—';
  }
};

const statusColor = (status) => {
  switch ((status || '').toLowerCase()) {
    case 'active':    return 'success';
    case 'cancelled': return 'error';
    case 'completed': return 'default';
    default:          return 'primary';   // 'scheduled'
  }
};

// ── Component ─────────────────────────────────────────────────────────────────

/**
 * TodaySchedules
 * Fetches all schedules whose departureTime falls within today (midnight → midnight)
 * and renders them as a compact scrollable list.
 */
export const TodaySchedules = () => {
  const theme = useTheme();

  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading]     = useState(true);

  useEffect(() => {
    const fetch = async () => {
      try {
        // Build today's date range
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);
        const todayEnd = new Date(todayStart);
        todayEnd.setDate(todayEnd.getDate() + 1);

        const snap = await getDocs(
          query(
            collection(db, 'schedules'),
            where('departureTime', '>=', Timestamp.fromDate(todayStart)),
            where('departureTime', '<',  Timestamp.fromDate(todayEnd)),
          ),
        );

        setSchedules(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      } catch (err) {
        console.error('TodaySchedules fetch error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetch();
  }, []);

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 3 }}>

        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <ScheduleIcon sx={{ color: theme.palette.warning.main }} />
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            Today's Schedules
          </Typography>
          {!loading && (
            <Chip
              label={schedules.length}
              size="small"
              color="warning"
              variant="outlined"
              sx={{ ml: 'auto', fontWeight: 700, minWidth: 32 }}
            />
          )}
        </Box>

        {/* Loading */}
        {loading && (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress size={28} />
          </Box>
        )}

        {/* Empty state */}
        {!loading && schedules.length === 0 && (
          <Typography
            color="text.secondary"
            sx={{ py: 3, textAlign: 'center' }}
          >
            No departures scheduled for today.
          </Typography>
        )}

        {/* Scrollable list */}
        {!loading && schedules.length > 0 && (
          <Box
            sx={{
              maxHeight: 320,
              overflowY: 'auto',
              pr: 0.5,
              /* thin custom scrollbar */
              '&::-webkit-scrollbar': { width: 4 },
              '&::-webkit-scrollbar-track': { background: 'transparent' },
              '&::-webkit-scrollbar-thumb': {
                background: 'rgba(255,255,255,0.1)',
                borderRadius: 2,
              },
            }}
          >
            {schedules.map((s, idx) => (
              <React.Fragment key={s.id}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    py: 1.5,
                  }}
                >
                  {/* Left: bus icon + departure time + bus ID */}
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <Box
                      sx={{
                        backgroundColor: 'rgba(99,102,241,0.1)',
                        color: theme.palette.primary.main,
                        borderRadius: 1.5,
                        p: 0.8,
                        display: 'flex',
                        flexShrink: 0,
                      }}
                    >
                      <DirectionsBus fontSize="small" />
                    </Box>
                    <Box>
                      <Typography variant="body2" sx={{ fontWeight: 700 }}>
                        {formatTime(s.departureTime)}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {s.busId
                          ? `Bus: ${String(s.busId).substring(0, 10)}…`
                          : 'Bus N/A'}
                      </Typography>
                    </Box>
                  </Box>

                  {/* Right: status chip + current stop */}
                  <Box sx={{ textAlign: 'right' }}>
                    <Chip
                      label={(s.status || 'Scheduled').toUpperCase()}
                      size="small"
                      color={statusColor(s.status)}
                      variant="filled"
                      sx={{
                        height: 20,
                        fontSize: '0.65rem',
                        fontWeight: 700,
                        mb: 0.5,
                        display: 'block',
                      }}
                    />
                    <Typography
                      variant="caption"
                      color="text.secondary"
                      sx={{ fontSize: '0.68rem' }}
                    >
                      {s.currentStop || 'Not started'}
                    </Typography>
                  </Box>
                </Box>

                {idx < schedules.length - 1 && (
                  <Divider sx={{ borderColor: 'rgba(255,255,255,0.05)' }} />
                )}
              </React.Fragment>
            ))}
          </Box>
        )}
      </CardContent>
    </Card>
  );
};
