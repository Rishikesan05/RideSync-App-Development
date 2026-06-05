/**
 * RouteStatsBar.jsx
 *
 * A compact summary row that sits between the header and the search bar
 * showing live counts derived from the Firestore routes snapshot.
 *
 * Props:
 *   routes  — array of route objects from useRoutesFirestore()
 *   loading — boolean
 */

import React from 'react';
import { Box, Card, Typography, Skeleton, Divider, useTheme } from '@mui/material';
import {
  Route as RouteIcon,
  CheckCircleOutlined,
  HighlightOff,
  AltRoute,
} from '@mui/icons-material';

const StatPill = ({ icon, label, value, color, loading, onClick, active }) => {
  const theme = useTheme();
  return (
    <Box
      onClick={onClick}
      sx={{
        display:        'flex',
        alignItems:     'center',
        gap:            1.5,
        px:             2.5,
        py:             1.5,
        borderRadius:   2,
        flex:           1,
        minWidth:       130,
        backgroundColor: active ? `${color}22` : `${color}12`,
        border:         active ? `1px solid ${color}` : `1px solid ${color}30`,
        boxShadow:      active ? `0 0 12px ${color}44` : 'none',
        transition:     'all 0.2s ease-in-out',
        cursor:         onClick ? 'pointer' : 'default',
        '&:hover': onClick ? { 
          backgroundColor: active ? `${color}28` : `${color}20`,
          border: active ? `1px solid ${color}` : `1px solid ${color}80`,
          boxShadow: active ? `0 0 14px ${color}55` : `0 0 10px ${color}22`,
        } : {},
      }}
    >
      <Box
        sx={{
          color,
          display:         'flex',
          alignItems:      'center',
          backgroundColor: `${color}20`,
          borderRadius:    '50%',
          p:               0.8,
        }}
      >
        {icon}
      </Box>
      <Box>
        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', lineHeight: 1.2 }}>
          {label}
        </Typography>
        {loading ? (
          <Skeleton width={32} height={24} />
        ) : (
          <Typography variant="h6" sx={{ fontWeight: 800, color, lineHeight: 1.2 }}>
            {value}
          </Typography>
        )}
      </Box>
    </Box>
  );
};

export const RouteStatsBar = ({ routes = [], loading = false, activeFilter = 'all', onFilterChange }) => {
  const theme = useTheme();

  const total    = routes.length;
  const active   = routes.filter((r) => r.isActive).length;
  const inactive = total - active;
  const stops    = routes.reduce((sum, r) => sum + (r.stops?.length || 0), 0);

  const stats = [
    {
      icon:  <RouteIcon fontSize="small" />,
      label: 'Total Routes',
      value: total,
      color: theme.palette.primary.main,
      filterType: 'all',
    },
    {
      icon:  <CheckCircleOutlined fontSize="small" />,
      label: 'Active',
      value: active,
      color: theme.palette.success.main,
      filterType: 'active',
    },
    {
      icon:  <HighlightOff fontSize="small" />,
      label: 'Inactive',
      value: inactive,
      color: theme.palette.error.main,
      filterType: 'inactive',
    },
    {
      icon:  <AltRoute fontSize="small" />,
      label: 'Total Stops',
      value: stops,
      color: theme.palette.warning.main,
    },
  ];

  return (
    <Card
      sx={{
        mb:              3,
        p:               2,
        backgroundColor: 'rgba(255,255,255,0.02)',
        border:          '1px solid rgba(255,255,255,0.06)',
        borderRadius:    2,
      }}
    >
      <Box
        sx={{
          display:    'flex',
          gap:        2,
          alignItems: 'stretch',
          flexWrap:   'wrap',
        }}
      >
        {stats.map((s, i) => {
          const isClickable = s.filterType !== undefined;
          return (
            <React.Fragment key={s.label}>
              <StatPill
                {...s}
                loading={loading}
                onClick={isClickable && onFilterChange ? () => onFilterChange(s.filterType) : undefined}
                active={isClickable && activeFilter === s.filterType}
              />
              {i < stats.length - 1 && (
                <Divider
                  orientation="vertical"
                  flexItem
                  sx={{ borderColor: 'rgba(255,255,255,0.06)', display: { xs: 'none', sm: 'block' } }}
                />
              )}
            </React.Fragment>
          );
        })}
      </Box>
    </Card>
  );
};
