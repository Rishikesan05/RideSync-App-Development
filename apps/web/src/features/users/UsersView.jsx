import React, { useState } from 'react';
import {
  Typography,
  Box,
  useTheme,
  CircularProgress,
  Alert,
  Tab,
  Tabs,
  Avatar,
  Chip,
  IconButton,
  Tooltip,
  Divider,
} from '@mui/material';
import {
  AdminPanelSettings,
  DirectionsBus,
  Person,
  Edit,
  Delete,
  CheckCircle,
  Cancel,
  VerifiedUser,
  HourglassEmpty,
} from '@mui/icons-material';
import { useUsersFirestore } from './useUsersFirestore';

// ── Category config ───────────────────────────────────────────────────────────
const CATEGORIES = [
  {
    key: 'passengers',
    label: 'Passengers',
    icon: <Person />,
    color: '#4f86f7',
    bgColor: 'rgba(79,134,247,0.1)',
  },
  {
    key: 'operators',
    label: 'Operators',
    icon: <DirectionsBus />,
    color: '#E68D33',
    bgColor: 'rgba(230,141,51,0.1)',
  },
  {
    key: 'admins',
    label: 'Admins',
    icon: <AdminPanelSettings />,
    color: '#e05c7a',
    bgColor: 'rgba(224,92,122,0.1)',
  },
];

// ── Avatar colour from name ───────────────────────────────────────────────────
const avatarColor = (name = '') => {
  const palette = ['#4f86f7', '#E68D33', '#e05c7a', '#34c577', '#a259ff', '#f7c948'];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return palette[Math.abs(hash) % palette.length];
};

// ── Initials helper ───────────────────────────────────────────────────────────
const initials = (name = '') =>
  name
    .split(' ')
    .slice(0, 2)
    .map((w) => w[0])
    .join('')
    .toUpperCase() || '?';

// ── Tab Panel ─────────────────────────────────────────────────────────────────
const TabPanel = ({ children, value, index }) => (
  <Box role="tabpanel" id={`users-panel-${index}`} hidden={value !== index}>
    {value === index && children}
  </Box>
);

// ── User Card ─────────────────────────────────────────────────────────────────
const UserCard = ({ user, category, onEdit, onDelete, theme }) => {
  const cat = CATEGORIES.find((c) => c.key === category) || CATEGORIES[0];
  const name  = user.name || user.displayName || 'Unknown User';
  const email = user.email || '—';
  const phone = user.phone || user.phoneNumber || '—';
  const isApproved = user.isApproved !== false; // default true if field absent

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        gap: 2,
        p: 2,
        borderRadius: 2,
        backgroundColor: theme.palette.mode === 'dark'
          ? 'rgba(255,255,255,0.03)'
          : 'rgba(0,0,0,0.02)',
        border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)'}`,
        transition: 'all 0.2s',
        '&:hover': {
          backgroundColor: theme.palette.mode === 'dark'
            ? 'rgba(255,255,255,0.06)'
            : 'rgba(0,0,0,0.04)',
          transform: 'translateY(-1px)',
          boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
        },
      }}
    >
      {/* Avatar */}
      <Avatar
        sx={{
          bgcolor: avatarColor(name),
          width: 44,
          height: 44,
          fontSize: '0.9rem',
          fontWeight: 700,
          flexShrink: 0,
        }}
      >
        {initials(name)}
      </Avatar>

      {/* Info */}
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
          <Typography variant="body1" sx={{ fontWeight: 700, color: theme.palette.text.primary }}>
            {name}
          </Typography>
          {/* Operator approval badge */}
          {category === 'operators' && (
            <Chip
              icon={isApproved ? <VerifiedUser sx={{ fontSize: '0.75rem !important' }} /> : <HourglassEmpty sx={{ fontSize: '0.75rem !important' }} />}
              label={isApproved ? 'Approved' : 'Pending'}
              size="small"
              sx={{
                height: 20,
                fontSize: '0.65rem',
                fontWeight: 700,
                backgroundColor: isApproved ? 'rgba(52,197,119,0.12)' : 'rgba(245,158,11,0.12)',
                color: isApproved ? '#34c577' : '#f59e0b',
                border: `1px solid ${isApproved ? 'rgba(52,197,119,0.3)' : 'rgba(245,158,11,0.3)'}`,
                '& .MuiChip-icon': { color: 'inherit' },
              }}
            />
          )}
        </Box>
        <Typography variant="caption" color="text.secondary" noWrap>
          {email}
        </Typography>
        {phone !== '—' && (
          <Typography variant="caption" color="text.secondary" sx={{ ml: 1.5 }}>
            · {phone}
          </Typography>
        )}
        {user.operatorId && (
          <Typography variant="caption" color="text.disabled" sx={{ ml: 1.5 }}>
            · ID: {user.operatorId}
          </Typography>
        )}
      </Box>

      {/* Role chip */}
      <Chip
        label={cat.label.slice(0, -1)}   // "Passenger" / "Operator" / "Admin"
        size="small"
        sx={{
          fontWeight: 700,
          fontSize: '0.68rem',
          backgroundColor: cat.bgColor,
          color: cat.color,
          border: `1px solid ${cat.color}33`,
          flexShrink: 0,
        }}
      />

      {/* Actions */}
      <Box sx={{ display: 'flex', gap: 0.5, flexShrink: 0 }}>
        <Tooltip title="Edit user">
          <IconButton
            id={`edit-user-${user.id}`}
            size="small"
            onClick={() => onEdit(user)}
            sx={{
              color: '#4f86f7',
              '&:hover': { backgroundColor: 'rgba(79,134,247,0.1)' },
            }}
          >
            <Edit fontSize="small" />
          </IconButton>
        </Tooltip>
        <Tooltip title="Delete user">
          <IconButton
            id={`delete-user-${user.id}`}
            size="small"
            onClick={() => onDelete(user)}
            sx={{
              color: '#e05c7a',
              '&:hover': { backgroundColor: 'rgba(224,92,122,0.1)' },
            }}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Tooltip>
      </Box>
    </Box>
  );
};

// ── User List Panel ───────────────────────────────────────────────────────────
const UserList = ({ users, category, onEdit, onDelete, theme }) => {
  if (users.length === 0) {
    return (
      <Box sx={{ py: 6, textAlign: 'center' }}>
        <Typography color="text.secondary" variant="body2">
          No {category} found in the database.
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
      {users.map((user) => (
        <UserCard
          key={user.id}
          user={user}
          category={category}
          onEdit={onEdit}
          onDelete={onDelete}
          theme={theme}
        />
      ))}
    </Box>
  );
};

// ── Main Component (shell only — dialogs added in next commits) ───────────────
export const UsersView = () => {
  const theme = useTheme();
  const [activeTab, setActiveTab] = useState(0);
  const [editUser,   setEditUser]   = useState(null); // user to edit
  const [deleteUser, setDeleteUser] = useState(null); // user to delete

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
      {/* ── Header ───────────────────────────────────────────────────── */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 800, color: theme.palette.text.primary }}>
          Users Management
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
          Manage passengers, operators, and admins across all categories
        </Typography>
      </Box>

      {/* ── Summary Cards ────────────────────────────────────────────── */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 2, mb: 3 }}>
        {CATEGORIES.map((cat, i) => (
          <Box
            key={cat.key}
            onClick={() => setActiveTab(i)}
            sx={{
              p: 2.5,
              borderRadius: 3,
              cursor: 'pointer',
              backgroundColor: activeTab === i ? cat.bgColor : theme.palette.background.paper,
              border: `1px solid ${activeTab === i ? cat.color + '44' : (theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)')}`,
              transition: 'all 0.2s',
              boxShadow: activeTab === i
                ? `0 4px 16px ${cat.color}22`
                : theme.palette.mode === 'dark' ? '0 2px 8px rgba(0,0,0,0.2)' : '0 2px 8px rgba(0,0,0,0.04)',
              '&:hover': { transform: 'translateY(-2px)', boxShadow: `0 6px 20px ${cat.color}22` },
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
              <Box sx={{ color: cat.color, display: 'flex' }}>{cat.icon}</Box>
              <Box>
                <Typography variant="h5" sx={{ fontWeight: 800, color: cat.color, lineHeight: 1 }}>
                  {counts[i]}
                </Typography>
                <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.8 }}>
                  {cat.label}
                </Typography>
              </Box>
            </Box>
          </Box>
        ))}
      </Box>

      {/* ── Tab Panel ────────────────────────────────────────────────── */}
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
        {/* Tabs */}
        <Tabs
          value={activeTab}
          onChange={(_, v) => setActiveTab(v)}
          sx={{
            borderBottom: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'}`,
            '& .MuiTab-root': {
              fontWeight: 600,
              fontSize: '0.82rem',
              textTransform: 'uppercase',
              letterSpacing: 0.8,
              color: theme.palette.text.secondary,
              py: 2,
              px: 3,
              '&.Mui-selected': { color: '#E68D33' },
            },
            '& .MuiTabs-indicator': {
              backgroundColor: '#E68D33',
              height: 3,
              borderRadius: '3px 3px 0 0',
            },
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
                      fontSize: '0.7rem',
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

        {/* List panels */}
        {CATEGORIES.map((cat, i) => (
          <TabPanel key={cat.key} value={activeTab} index={i}>
            <Box sx={{ p: 3 }}>
              <UserList
                users={lists[i]}
                category={cat.key}
                onEdit={setEditUser}
                onDelete={setDeleteUser}
                theme={theme}
              />
            </Box>
          </TabPanel>
        ))}
      </Box>
    </Box>
  );
};
