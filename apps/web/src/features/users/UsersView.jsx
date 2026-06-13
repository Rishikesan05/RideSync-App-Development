import React, { useState } from 'react';
import {
  Typography,
  Box,
  useTheme,
  CircularProgress,
  Alert,
  Tab,
  Tabs,
} from '@mui/material';
import {
  AdminPanelSettings,
  DirectionsBus,
  Person,
} from '@mui/icons-material';
import { useUsersFirestore } from './useUsersFirestore';

// ── Category config ───────────────────────────────────────────────────────────
const CATEGORIES = [
  { key: 'passengers', label: 'Passengers', icon: <Person /> },
  { key: 'operators',  label: 'Operators',  icon: <DirectionsBus /> },
  { key: 'admins',     label: 'Admins',     icon: <AdminPanelSettings /> },
];

// ── Tab Panel ─────────────────────────────────────────────────────────────────
const TabPanel = ({ children, value, index }) => (
  <Box role="tabpanel" hidden={value !== index} sx={{ mt: 3 }}>
    {value === index && children}
  </Box>
);

// ── Main Component ────────────────────────────────────────────────────────────
export const UsersView = () => {
  const theme = useTheme();
  const [activeTab, setActiveTab] = useState(0);
  const { passengers, operators, admins, loading, error } = useUsersFirestore();

  const counts = [passengers.length, operators.length, admins.length];
  const lists  = [passengers, operators, admins];

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 300 }}>
        <CircularProgress sx={{ color: '#E68D33' }} />
      </Box>
    );
  }

  if (error) {
    return <Alert severity="error" sx={{ borderRadius: 2 }}>{error}</Alert>;
  }

  return (
    <Box>
      {/* ── Header ─────────────────────────────────────────────────────── */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 800, color: theme.palette.text.primary }}>
          Users Management
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
          Manage passengers, operators, and admins across all categories
        </Typography>
      </Box>

      {/* ── Category Tabs ──────────────────────────────────────────────── */}
      <Box
        sx={{
          borderRadius: 3,
          backgroundColor: theme.palette.background.paper,
          boxShadow: theme.palette.mode === 'dark'
            ? '0 4px 24px rgba(0,0,0,0.3)'
            : '0 4px 24px rgba(0,0,0,0.06)',
          border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`,
          overflow: 'hidden',
        }}
      >
        <Tabs
          value={activeTab}
          onChange={(_, v) => setActiveTab(v)}
          sx={{
            borderBottom: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`,
            '& .MuiTab-root': {
              fontWeight: 600,
              fontSize: '0.85rem',
              textTransform: 'uppercase',
              letterSpacing: 0.8,
              color: theme.palette.text.secondary,
              py: 2,
              px: 3,
              gap: 1,
              '&.Mui-selected': { color: '#E68D33' },
            },
            '& .MuiTabs-indicator': { backgroundColor: '#E68D33', height: 3, borderRadius: '3px 3px 0 0' },
          }}
        >
          {CATEGORIES.map((cat, i) => (
            <Tab
              key={cat.key}
              id={`users-tab-${cat.key}`}
              aria-controls={`users-panel-${cat.key}`}
              label={
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  {cat.icon}
                  <span>{cat.label}</span>
                  <Box
                    component="span"
                    sx={{
                      ml: 0.5,
                      px: 1,
                      py: 0.2,
                      borderRadius: 10,
                      fontSize: '0.72rem',
                      fontWeight: 700,
                      backgroundColor: activeTab === i ? 'rgba(230,141,51,0.15)' : 'rgba(128,128,128,0.12)',
                      color: activeTab === i ? '#E68D33' : theme.palette.text.secondary,
                    }}
                  >
                    {counts[i]}
                  </Box>
                </Box>
              }
            />
          ))}
        </Tabs>

        {/* Tab panels rendered below */}
        {CATEGORIES.map((cat, i) => (
          <TabPanel key={cat.key} value={activeTab} index={i}>
            <Box sx={{ p: 3 }}>
              <Typography variant="body2" color="text.secondary">
                {lists[i].length === 0
                  ? `No ${cat.label.toLowerCase()} found.`
                  : `${lists[i].length} ${cat.label.toLowerCase()} listed below.`}
              </Typography>
            </Box>
          </TabPanel>
        ))}
      </Box>
    </Box>
  );
};
