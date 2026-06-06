/**
 * RouteStatsBar.jsx
 *
 * A compact summary row that sits between the header and the search bar
 * showing live counts derived from the Firestore routes snapshot.
 *
 * Props:
 *   routes       — array of route objects from useRoutesFirestore()
 *   loading      — boolean
 *   activeFilter — 'all' | 'active' | 'inactive'  (currently selected filter)
 *   onFilter     — (filterValue: string) => void  (called when a pill is clicked)
 */

import React from 'react';
import { Box, Card, Typography, Skeleton, Divider, useTheme, Tooltip } from '@mui/material';
import {
  Route as RouteIcon,
  CheckCircleOutlined,
  HighlightOff,
  AltRoute,
} from '@mui/icons-material';

const StatPill = ({ icon, label, value, color, loading, onClick, isActive }) => {
  const theme = useTheme();

  return (
    <Tooltip title={onClick ? `Click to filter by ${label}` : ''} placement="top" arrow>
      <Box
        onClick={onClick}
        role={onClick ? 'button' : undefined}
        tabIndex={onClick ? 0 : undefined}
        onKeyDown={onClick ? (e) => (e.key === 'Enter' || e.key === ' ') && onClick() : undefined}
        sx={{
          display:         'flex',
          alignItems:      'center',
          gap:             1.5,
          px:              2.5,
          py:              1.5,
          borderRadius:    2,
          flex:            1,
          minWidth:        130,
          backgroundColor: isActive ? `${color}25` : `${color}12`,
          border:          isActive
            ? `2px solid ${color}80`
            : `1px solid ${color}30`,
          transition:      'all 0.2s ease',
          cursor:          onClick ? 'pointer' : 'default',
          userSelect:      'none',
          transform:       isActive ? 'translateY(-1px)' : 'none',
          boxShadow:       isActive ? `0 4px 16px ${color}30` : 'none',
          '&:hover': onClick
            ? {
                backgroundColor: `${color}20`,
                transform:       'translateY(-2px)',
                boxShadow:       `0 6px 20px ${color}35`,
                border:          `2px solid ${color}60`,
              }
            : {},
          '&:active': onClick
            ? { transform: 'translateY(0)', boxShadow: `0 2px 8px ${color}25` }
            : {},
          '&:focus-visible': {
            outline: `2px solid ${color}`,
            outlineOffset: '2px',
          },
        }}
      >
        <Box
          sx={{
            color,
            display:         'flex',
            alignItems:      'center',
            backgroundColor: isActive ? `${color}30` : `${color}20`,
            borderRadius:    '50%',
            p:               0.8,
            transition:      'background 0.2s',
          }}
        >
          {icon}
        </Box>
        <Box>
          <Typography
            variant="caption"
            color="text.secondary"
            sx={{ display: 'block', lineHeight: 1.2, fontWeight: isActive ? 700 : 400 }}
          >
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
    </Tooltip>
  );
};

export const RouteStatsBar = ({
  routes       = [],
  loading      = false,
  activeFilter = 'all',
  onFilter     = null,
}) => {
  const theme = useTheme();

  const total    = routes.length;
  const active   = routes.filter((r) => r.isActive).length;
  const inactive = total - active;
  const stops    = routes.reduce((sum, r) => sum + (r.stops?.length || 0), 0);

  const stats = [
    {
      key:   'all',
      icon:  <RouteIcon fontSize="small" />,
      label: 'Total Routes',
      value: total,
      color: theme.palette.primary.main,
    },
    {
      key:   'active',
      icon:  <CheckCircleOutlined fontSize="small" />,
      label: 'Active',
      value: active,
      color: theme.palette.success.main,
    },
    {
      key:   'inactive',
      icon:  <HighlightOff fontSize="small" />,
      label: 'Inactive',
      value: inactive,
      color: theme.palette.error.main,
    },
    {
      key:   null,          // not filterable — informational only
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
        {stats.map((s, i) => (
          <React.Fragment key={s.label}>
            <StatPill
              icon={s.icon}
              label={s.label}
              value={s.value}
              color={s.color}
              loading={loading}
              isActive={s.key !== null && activeFilter === s.key}
              onClick={
                s.key !== null && onFilter
                  ? () => onFilter(activeFilter === s.key ? 'all' : s.key)
                  : undefined
              }
            />
            {i < stats.length - 1 && (
              <Divider
                orientation="vertical"
                flexItem
                sx={{ borderColor: 'rgba(255,255,255,0.06)', display: { xs: 'none', sm: 'block' } }}
              />
            )}
          </React.Fragment>
        ))}
      </Box>
    </Card>
  );
};
