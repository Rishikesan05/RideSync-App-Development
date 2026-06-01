import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  Divider,
  LinearProgress,
  Chip,
  useTheme,
} from '@mui/material';
import {
  DirectionsBus,
  AcUnit,
  CheckCircleOutlined,
  HighlightOff,
} from '@mui/icons-material';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../../api/firebase';

// ── Component ─────────────────────────────────────────────────────────────────

/**
 * FleetStats
 * Reads the `buses` Firestore collection and shows:
 *  - Total fleet size
 *  - Active vs inactive count with a progress bar
 *  - AC vs Non-AC breakdown
 */
export const FleetStats = () => {
  const theme = useTheme();

  const [loading, setLoading] = useState(true);
  const [fleet, setFleet] = useState({
    total:    0,
    active:   0,
    inactive: 0,
    ac:       0,
    nonAc:    0,
  });

  useEffect(() => {
    const fetchFleet = async () => {
      try {
        const snap = await getDocs(collection(db, 'buses'));

        let active = 0, inactive = 0, ac = 0, nonAc = 0;

        snap.forEach((doc) => {
          const d = doc.data();

          // Active / inactive
          if (d.isActive === true) active++;
          else inactive++;

          // AC / Non-AC — support both field names used by mobile app
          const cls = (d.busClass || d.class || d.type || '').toUpperCase();
          if (cls.includes('AC') || cls === 'AIR_CONDITIONED') ac++;
          else nonAc++;
        });

        setFleet({ total: snap.size, active, inactive, ac, nonAc });
      } catch (err) {
        console.error('FleetStats fetch error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchFleet();
  }, []);

  const activePct  = fleet.total > 0 ? Math.round((fleet.active  / fleet.total) * 100) : 0;
  const acPct      = fleet.total > 0 ? Math.round((fleet.ac      / fleet.total) * 100) : 0;

  const rows = [
    {
      label:   'Active Buses',
      value:   fleet.active,
      icon:    <CheckCircleOutlined fontSize="small" />,
      color:   theme.palette.success.main,
      pct:     activePct,
      barColor:'success',
    },
    {
      label:   'Inactive',
      value:   fleet.inactive,
      icon:    <HighlightOff fontSize="small" />,
      color:   theme.palette.error.main,
      pct:     fleet.total > 0 ? 100 - activePct : 0,
      barColor:'error',
    },
    {
      label:   'AC Buses',
      value:   fleet.ac,
      icon:    <AcUnit fontSize="small" />,
      color:   theme.palette.info.main,
      pct:     acPct,
      barColor:'info',
    },
    {
      label:   'Non-AC Buses',
      value:   fleet.nonAc,
      icon:    <DirectionsBus fontSize="small" />,
      color:   theme.palette.warning.main,
      pct:     fleet.total > 0 ? 100 - acPct : 0,
      barColor:'warning',
    },
  ];

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 3 }}>

        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <DirectionsBus sx={{ color: theme.palette.info.main }} />
            <Typography variant="h6" sx={{ fontWeight: 600 }}>
              Fleet Overview
            </Typography>
          </Box>
          {!loading && (
            <Chip
              label={`${fleet.total} total`}
              size="small"
              color="info"
              variant="outlined"
              sx={{ fontWeight: 700 }}
            />
          )}
        </Box>

        {/* Loading */}
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress size={28} />
          </Box>
        ) : fleet.total === 0 ? (
          <Typography color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>
            No buses found in the fleet yet.
          </Typography>
        ) : (
          <>
            {rows.map((row, idx) => (
              <React.Fragment key={row.label}>
                <Box sx={{ py: 1.5 }}>
                  {/* Label row */}
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 0.8 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Box
                        sx={{
                          color: row.color,
                          display: 'flex',
                          backgroundColor: `${row.color}18`,
                          borderRadius: '50%',
                          p: 0.5,
                        }}
                      >
                        {row.icon}
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        {row.label}
                      </Typography>
                    </Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Typography variant="body2" color="text.secondary" sx={{ fontSize: '0.75rem' }}>
                        {row.pct}%
                      </Typography>
                      <Typography variant="h6" sx={{ fontWeight: 700, color: row.color, minWidth: 28, textAlign: 'right' }}>
                        {row.value}
                      </Typography>
                    </Box>
                  </Box>

                  {/* Progress bar */}
                  <LinearProgress
                    variant="determinate"
                    value={row.pct}
                    color={row.barColor}
                    sx={{
                      height: 6,
                      borderRadius: 3,
                      backgroundColor: `${row.color}18`,
                      '& .MuiLinearProgress-bar': { borderRadius: 3 },
                    }}
                  />
                </Box>

                {idx < rows.length - 1 && (
                  <Divider sx={{ borderColor: 'rgba(255,255,255,0.05)' }} />
                )}
              </React.Fragment>
            ))}
          </>
        )}
      </CardContent>
    </Card>
  );
};
