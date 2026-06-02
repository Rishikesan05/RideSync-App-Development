import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Chip,
  CircularProgress,
  useTheme,
} from '@mui/material';
import { ReceiptLong } from '@mui/icons-material';
import {
  collection,
  getDocs,
  query,
  orderBy,
  limit,
} from 'firebase/firestore';
import { db } from '../../api/firebase';

// ── helpers ──────────────────────────────────────────────────────────────────

/**
 * Reads a booking document's date regardless of which field name the
 * mobile app used: `timestamp`, `createdAt`, or `bookedAt`.
 */
const getBookingDate = (data) => {
  const raw = data.timestamp ?? data.createdAt ?? data.bookedAt ?? null;
  if (!raw) return null;
  try {
    return typeof raw.toDate === 'function' ? raw.toDate() : new Date(raw);
  } catch {
    return null;
  }
};

const formatDate = (data) => {
  const d = getBookingDate(data);
  if (!d) return '—';
  return d.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const statusColor = (status) => {
  switch ((status || '').toLowerCase()) {
    case 'confirmed': return 'success';
    case 'cancelled': return 'error';
    case 'pending':   return 'warning';
    default:          return 'default';
  }
};

// ── Component ─────────────────────────────────────────────────────────────────

export const RecentBookings = () => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';
  const borderColor = isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.06)';
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading]   = useState(true);

  useEffect(() => {
    const fetch = async () => {
      try {
        // Try ordered query first; fall back to unordered if index is missing
        const snap = await getDocs(
          query(collection(db, 'bookings'), orderBy('timestamp', 'desc'), limit(10)),
        ).catch(() =>
          getDocs(query(collection(db, 'bookings'), limit(10))),
        );

        setBookings(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      } catch (err) {
        console.error('RecentBookings fetch error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetch();
  }, []);

  return (
    <Card>
      <CardContent>
        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <ReceiptLong sx={{ color: '#E68D33' }} />
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            Recent Bookings
          </Typography>
          {!loading && (
            <Chip
              label={`${bookings.length} latest`}
              size="small"
              variant="outlined"
              color="primary"
              sx={{ ml: 'auto', fontWeight: 600 }}
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
        {!loading && bookings.length === 0 && (
          <Typography color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>
            No bookings found yet.
          </Typography>
        )}

        {/* Table */}
        {!loading && bookings.length > 0 && (
          <Box sx={{ overflowX: 'auto' }}>
            <Table>
              <TableHead sx={{ backgroundColor: isDark ? 'rgba(255, 255, 255, 0.015)' : 'rgba(0, 0, 0, 0.01)' }}>
                <TableRow>
                  {['Booking ID', 'Passenger', 'Fare (LKR)', 'Class', 'Date', 'Status'].map(
                    (h) => (
                      <TableCell
                        key={h}
                        sx={{
                          color: theme.palette.text.secondary,
                          fontWeight: 700,
                          fontSize: '0.75rem',
                          textTransform: 'uppercase',
                          letterSpacing: 0.8,
                          borderBottom: `2px solid ${borderColor}`,
                          whiteSpace: 'nowrap',
                          py: 1.8,
                          px: 2
                        }}
                      >
                        {h}
                      </TableCell>
                    ),
                  )}
                </TableRow>
              </TableHead>

              <TableBody>
                {bookings.map((b) => {
                  const cls = (b.busClass || b.class || '—').toUpperCase();
                  return (
                    <TableRow
                      key={b.id}
                      sx={{
                        transition: 'background 0.15s',
                        '&:hover': { backgroundColor: isDark ? 'rgba(255, 255, 255, 0.025)' : 'rgba(0, 0, 0, 0.02)' },
                        '& td': { 
                          borderBottom: `1px solid ${borderColor}`,
                          py: 1.8,
                          px: 2
                        },
                      }}
                    >
                      {/* Booking ID */}
                      <TableCell>
                        <Typography
                          variant="caption"
                          sx={{ fontFamily: 'monospace', color: theme.palette.primary.light }}
                        >
                          #{b.id.substring(0, 8)}
                        </Typography>
                      </TableCell>

                      {/* Passenger */}
                      <TableCell>
                        <Typography variant="body2">
                          {b.passengerName ||
                            (b.passengerId ? `${b.passengerId.substring(0, 10)}…` : '—')}
                        </Typography>
                      </TableCell>

                      {/* Fare */}
                      <TableCell>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {b.totalFare != null ? `LKR ${Number(b.totalFare).toLocaleString()}` : '—'}
                        </Typography>
                      </TableCell>

                      {/* Class */}
                      <TableCell>
                        <Chip
                          label={cls}
                          size="small"
                          color={cls === 'AC' ? 'info' : 'default'}
                          variant="outlined"
                          sx={{ height: 20, fontSize: '0.68rem' }}
                        />
                      </TableCell>

                      {/* Date */}
                      <TableCell>
                        <Typography variant="caption" color="text.secondary" sx={{ whiteSpace: 'nowrap' }}>
                          {formatDate(b)}
                        </Typography>
                      </TableCell>

                      {/* Status */}
                      <TableCell>
                        <Chip
                          label={b.status || 'confirmed'}
                          size="small"
                          color={statusColor(b.status)}
                          variant="filled"
                          sx={{ height: 20, fontSize: '0.68rem', fontWeight: 600 }}
                        />
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};
