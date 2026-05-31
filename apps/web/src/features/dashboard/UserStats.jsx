import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  CircularProgress,
  Divider,
  useTheme,
} from '@mui/material';
import {
  PersonOutline,
  SupportAgentOutlined,
  HourglassTopOutlined,
  PeopleAltOutlined,
} from '@mui/icons-material';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../../api/firebase';

// ── Component ─────────────────────────────────────────────────────────────────

/**
 * UserStats
 * Reads the `users` Firestore collection and counts entries by `role` field.
 * Roles tracked: passenger | operator | admin_pending
 */
export const UserStats = () => {
  const theme = useTheme();

  const [loading, setLoading] = useState(true);
  const [counts, setCounts]   = useState({
    passengers: 0,
    operators:  0,
    pending:    0,
    total:      0,
  });

  useEffect(() => {
    const fetch = async () => {
      try {
        const snap = await getDocs(collection(db, 'users'));

        let passengers = 0, operators = 0, pending = 0;

        snap.forEach((doc) => {
          const role = (doc.data().role || '').toLowerCase();
          if (role === 'passenger')      passengers++;
          else if (role === 'operator')  operators++;
          else if (role === 'admin_pending') pending++;
        });

        setCounts({
          passengers,
          operators,
          pending,
          total: snap.size,
        });
      } catch (err) {
        console.error('UserStats fetch error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetch();
  }, []);

  const rows = [
    {
      label: 'Passengers',
      value: counts.passengers,
      icon:  <PersonOutline />,
      color: theme.palette.primary.main,
    },
    {
      label: 'Operators',
      value: counts.operators,
      icon:  <SupportAgentOutlined />,
      color: theme.palette.info.main,
    },
    {
      label: 'Pending Approval',
      value: counts.pending,
      icon:  <HourglassTopOutlined />,
      color: theme.palette.warning.main,
    },
  ];

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 3 }}>

        {/* Title */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <PeopleAltOutlined sx={{ color: theme.palette.primary.main }} />
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            Registered Users
          </Typography>
        </Box>

        {/* Loading */}
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress size={28} />
          </Box>
        ) : (
          <>
            {/* Role rows */}
            {rows.map((row, idx) => (
              <React.Fragment key={row.label}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    py: 1.5,
                  }}
                >
                  {/* Icon + label */}
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <Box
                      sx={{
                        backgroundColor: `${row.color}20`,
                        color: row.color,
                        borderRadius: '50%',
                        p: 0.8,
                        display: 'flex',
                      }}
                    >
                      {React.cloneElement(row.icon, { fontSize: 'small' })}
                    </Box>
                    <Typography variant="body2" color="text.secondary">
                      {row.label}
                    </Typography>
                  </Box>

                  {/* Count */}
                  <Typography
                    variant="h6"
                    sx={{ fontWeight: 700, color: row.color }}
                  >
                    {row.value}
                  </Typography>
                </Box>

                {idx < rows.length - 1 && (
                  <Divider sx={{ borderColor: 'rgba(255,255,255,0.05)' }} />
                )}
              </React.Fragment>
            ))}

            {/* Total footer */}
            <Divider sx={{ mt: 2, mb: 1.5, borderColor: 'rgba(255,255,255,0.05)' }} />
            <Box
              sx={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}
              >
                Total Users
              </Typography>
              <Typography variant="h5" sx={{ fontWeight: 800 }}>
                {counts.total}
              </Typography>
            </Box>
          </>
        )}
      </CardContent>
    </Card>
  );
};
