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
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Divider,
  Snackbar,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import {
  AdminPanelSettings,
  DirectionsBus,
  Person,
  Edit,
  Delete,
  HourglassEmpty,
  Close,
  Save,
  Warning,
  Search,
  VpnKey,
  CheckCircle,
  PendingActions,
} from '@mui/icons-material';
import { useUsersFirestore } from './useUsersFirestore';
import { usersApi } from './users.api';

// ── Category config ───────────────────────────────────────────────────────────
const CATEGORIES = [
  {
    key: 'passengers',
    label: 'Passengers',
    icon: <Person />,
    color: '#4f86f7',
    bgColor: 'rgba(79,134,247,0.1)',
    singular: 'Passenger',
  },
  {
    key: 'operators',
    label: 'Operators',
    icon: <DirectionsBus />,
    color: '#E68D33',
    bgColor: 'rgba(230,141,51,0.1)',
    singular: 'Operator',
  },
  {
    key: 'admins',
    label: 'Admins',
    icon: <AdminPanelSettings />,
    color: '#e05c7a',
    bgColor: 'rgba(224,92,122,0.1)',
    singular: 'Admin',
  },
  {
    key: 'pending',
    label: 'Pending',
    icon: <PendingActions />,
    color: '#f59e0b',
    bgColor: 'rgba(245,158,11,0.1)',
    singular: 'Pending',
  },
];

// ── Helpers ───────────────────────────────────────────────────────────────────
const avatarColor = (name = '') => {
  const palette = ['#4f86f7', '#E68D33', '#e05c7a', '#34c577', '#a259ff', '#f7c948'];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return palette[Math.abs(hash) % palette.length];
};

const initials = (name = '') =>
  name.split(' ').slice(0, 2).map((w) => w[0]).join('').toUpperCase() || '?';

const roleBadgeLabel = (role) => {
  if (!role) return 'No Role';
  if (role === 'operator_pending')  return 'Operator Pending';
  if (role === 'operator_request')  return 'Operator Request';
  return role.charAt(0).toUpperCase() + role.slice(1);
};

// ── Tab Panel ─────────────────────────────────────────────────────────────────
const TabPanel = ({ children, value, index, catKey }) => (
  <Box
    role="tabpanel"
    id={`users-panel-${catKey}`}
    aria-labelledby={`users-tab-${catKey}`}
    hidden={value !== index}
  >
    {value === index && children}
  </Box>
);

// ── User Card ─────────────────────────────────────────────────────────────────
const UserCard = ({ user, categoryKey, onEdit, onDelete, onChangeRole, theme }) => {
  const cat        = CATEGORIES.find((c) => c.key === categoryKey) || CATEGORIES[0];
  const name       = user.name || user.displayName || 'Unknown User';
  const email      = user.email || '—';
  const phone      = user.phone || user.phoneNumber || '—';
  const isPending  = categoryKey === 'pending';

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        gap: 2,
        p: 2,
        borderRadius: 2,
        backgroundColor: isPending
          ? (theme.palette.mode === 'dark' ? 'rgba(245,158,11,0.05)' : 'rgba(245,158,11,0.03)')
          : (theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.015)'),
        border: `1px solid ${isPending
          ? 'rgba(245,158,11,0.2)'
          : (theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.06)')}`,
        transition: 'all 0.18s ease',
        '&:hover': {
          backgroundColor: isPending
            ? 'rgba(245,158,11,0.08)'
            : (theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.035)'),
          transform: 'translateY(-1px)',
          boxShadow: `0 4px 16px ${cat.color}18`,
        },
      }}
    >
      {/* Avatar */}
      <Avatar sx={{ bgcolor: avatarColor(name), width: 44, height: 44, fontSize: '0.85rem', fontWeight: 700, flexShrink: 0 }}>
        {initials(name)}
      </Avatar>

      {/* Info */}
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
          <Typography variant="body1" sx={{ fontWeight: 700 }} noWrap>{name}</Typography>

          {/* Pending role label */}
          {isPending && (
            <Chip
              icon={<HourglassEmpty sx={{ fontSize: '0.7rem !important' }} />}
              label={roleBadgeLabel(user.role)}
              size="small"
              sx={{
                height: 18, fontSize: '0.62rem', fontWeight: 700,
                backgroundColor: 'transparent',
                color: '#f59e0b',
                border: '1px solid rgba(245,158,11,0.3)',
                '& .MuiChip-icon': { color: 'inherit' },
              }}
            />
          )}


        </Box>

        <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap', mt: 0.2 }}>
          <Typography variant="caption" color="text.secondary">{email}</Typography>
          {phone !== '—' && <Typography variant="caption" color="text.disabled">· {phone}</Typography>}
          {user.operatorId && <Typography variant="caption" color="text.disabled">· ID: {user.operatorId}</Typography>}
        </Box>
      </Box>

      {/* Role chip */}
      <Chip
        label={cat.singular}
        size="small"
        sx={{
          fontWeight: 700, fontSize: '0.68rem',
          backgroundColor: cat.bgColor, color: cat.color,
          border: `1px solid ${cat.color}33`, flexShrink: 0,
        }}
      />

      {/* Action buttons */}
      <Box sx={{ display: 'flex', gap: 0.5, flexShrink: 0 }}>

        {/* "Change Role" — shown on pending cards AND as an extra action on all cards */}
        <Tooltip title={isPending ? 'Verify & assign role' : 'Change role'}>
          <IconButton
            id={`role-btn-${user.id}`}
            size="small"
            onClick={() => onChangeRole(user, categoryKey)}
            sx={{
              color: '#f59e0b',
              backgroundColor: 'transparent',
              border: 'none',
              '&:hover': { backgroundColor: 'rgba(245,158,11,0.08)' },
            }}
          >
            <VpnKey fontSize="small" />
          </IconButton>
        </Tooltip>

        <Tooltip title="Edit user">
          <IconButton
            id={`edit-btn-${user.id}`}
            size="small"
            onClick={() => onEdit(user, categoryKey)}
            sx={{ color: '#4f86f7', '&:hover': { backgroundColor: 'rgba(79,134,247,0.1)' } }}
          >
            <Edit fontSize="small" />
          </IconButton>
        </Tooltip>

        <Tooltip title="Delete user">
          <IconButton
            id={`delete-btn-${user.id}`}
            size="small"
            onClick={() => onDelete(user, categoryKey)}
            sx={{ color: '#e05c7a', '&:hover': { backgroundColor: 'rgba(224,92,122,0.1)' } }}
          >
            <Delete fontSize="small" />
          </IconButton>
        </Tooltip>
      </Box>
    </Box>
  );
};

// ── User List ─────────────────────────────────────────────────────────────────
const UserList = ({ users, categoryKey, onEdit, onDelete, onChangeRole, search, theme }) => {
  const filtered = search
    ? users.filter((u) => {
        const q = search.toLowerCase();
        return (
          (u.name || '').toLowerCase().includes(q) ||
          (u.email || '').toLowerCase().includes(q) ||
          (u.operatorId || '').toLowerCase().includes(q) ||
          (u.role || '').toLowerCase().includes(q)
        );
      })
    : users;

  if (filtered.length === 0) {
    return (
      <Box sx={{ py: 6, textAlign: 'center' }}>
        <Typography color="text.secondary" variant="body2">
          {search ? `No results for "${search}".` : `No ${categoryKey} found.`}
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
      {filtered.map((user) => (
        <UserCard
          key={user.id}
          user={user}
          categoryKey={categoryKey}
          onEdit={onEdit}
          onDelete={onDelete}
          onChangeRole={onChangeRole}
          theme={theme}
        />
      ))}
    </Box>
  );
};

// ── Change Role Dialog ────────────────────────────────────────────────────────
const ChangeRoleDialog = ({ open, user, onClose, onDone, theme }) => {
  const [selectedRole, setSelectedRole] = useState('admin');
  const [saving, setSaving]             = useState(false);
  const [err, setErr]                   = useState('');

  const name = user ? (user.name || user.displayName || 'this user') : '';

  React.useEffect(() => {
    if (open) { setSelectedRole('admin'); setErr(''); }
  }, [open]);

  const handleApprove = async () => {
    setSaving(true);
    setErr('');
    try {
      await usersApi.changeRole(user.id, selectedRole);
      onDone(`${name} verified and assigned as ${selectedRole}.`);
      onClose();
    } catch (e) {
      setErr(e.message || 'Failed to change role.');
    } finally {
      setSaving(false);
    }
  };

  const roleOptions = [
    { value: 'admin',     label: 'Admin',     icon: '🛡️', desc: 'Full dashboard access' },
    { value: 'operator',  label: 'Operator',  icon: '🚌', desc: 'Bus operator access' },
    { value: 'passenger', label: 'Passenger', icon: '👤', desc: 'Mobile app passenger' },
  ];

  return (
    <Dialog
      open={open}
      onClose={onClose}
      fullWidth
      maxWidth="xs"
      PaperProps={{
        sx: {
          borderRadius: 3,
          backgroundColor: theme.palette.background.paper,
          backgroundImage: 'none',
          border: '1px solid rgba(245,158,11,0.25)',
          boxShadow: '0 24px 48px rgba(0,0,0,0.3)',
        },
      }}
    >
      {/* ── Title ─────────────────────────────────────────────────────── */}
      <DialogTitle sx={{ pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{
            bgcolor: 'transparent', borderRadius: 2,
            p: 0.8, display: 'flex', color: '#f59e0b',
          }}>
            <VpnKey fontSize="small" />
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2 }}>
              Verify &amp; Assign Role
            </Typography>
            <Typography variant="caption" color="text.secondary" noWrap>
              Approving: <strong>{name}</strong>
            </Typography>
          </Box>
          <IconButton onClick={onClose} sx={{ ml: 'auto' }} size="small">
            <Close fontSize="small" />
          </IconButton>
        </Box>
      </DialogTitle>

      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />

      {/* ── Content ───────────────────────────────────────────────────── */}
      <DialogContent sx={{ pt: 2, pb: 1 }}>
        {err && <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>{err}</Alert>}

        {/* Current role info */}
        {user?.role && (
          <Box sx={{
            mb: 2.5, p: 1.5, borderRadius: 2,
            backgroundColor: 'transparent',
            border: '1px solid rgba(245,158,11,0.2)',
            display: 'flex', alignItems: 'center', gap: 1,
          }}>
            <HourglassEmpty sx={{ color: '#f59e0b', fontSize: '1rem' }} />
            <Typography variant="caption" sx={{ color: '#f59e0b', fontWeight: 600 }}>
              Current role: <strong>{roleBadgeLabel(user.role)}</strong>
            </Typography>
          </Box>
        )}

        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          Select the role to assign. This will also mark the account as <strong>Approved</strong>.
        </Typography>

        {/* Role selector cards */}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
          {roleOptions.map((opt) => (
            <Box
              key={opt.value}
              id={`role-option-${opt.value}`}
              onClick={() => setSelectedRole(opt.value)}
              sx={{
                p: 1.5,
                borderRadius: 2,
                cursor: 'pointer',
                border: `2px solid ${selectedRole === opt.value ? '#f59e0b' : (theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)')}`,
                backgroundColor: selectedRole === opt.value ? 'rgba(245,158,11,0.08)' : 'transparent',
                display: 'flex',
                alignItems: 'center',
                gap: 1.5,
                transition: 'all 0.15s ease',
                '&:hover': { borderColor: '#f59e0b', backgroundColor: 'rgba(245,158,11,0.05)' },
              }}
            >
              <Typography sx={{ fontSize: '1.3rem' }}>{opt.icon}</Typography>
              <Box sx={{ flex: 1 }}>
                <Typography variant="body2" sx={{ fontWeight: 700 }}>{opt.label}</Typography>
                <Typography variant="caption" color="text.secondary">{opt.desc}</Typography>
              </Box>
              {selectedRole === opt.value && (
                <CheckCircle sx={{ color: '#f59e0b', fontSize: '1.1rem' }} />
              )}
            </Box>
          ))}
        </Box>
      </DialogContent>

      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />

      {/* ── Actions ───────────────────────────────────────────────────── */}
      <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
        <Button onClick={onClose} color="inherit" variant="outlined" disabled={saving}>
          Cancel
        </Button>
        <Button
          id="confirm-role-btn"
          onClick={handleApprove}
          variant="contained"
          disabled={saving}
          startIcon={saving ? <CircularProgress size={14} color="inherit" /> : <CheckCircle fontSize="small" />}
          sx={{
            backgroundColor: '#f59e0b',
            color: '#000',
            fontWeight: 700,
            '&:hover': { backgroundColor: '#d97706' },
          }}
        >
          {saving ? 'Saving…' : `Approve as ${selectedRole.charAt(0).toUpperCase() + selectedRole.slice(1)}`}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ── Edit Dialog ───────────────────────────────────────────────────────────────
const EditDialog = ({ open, user, categoryKey, onClose, onSaved, theme }) => {
  const [form, setForm]     = useState({ name: '', email: '', phone: '' });
  const [saving, setSaving] = useState(false);
  const [err, setErr]       = useState('');

  React.useEffect(() => {
    if (user) {
      setForm({
        name:  user.name || user.displayName || '',
        email: user.email || '',
        phone: user.phone || user.phoneNumber || '',
      });
      setErr('');
    }
  }, [user]);

  const handleSave = async () => {
    if (!form.name.trim()) { setErr('Name is required.'); return; }
    setSaving(true);
    setErr('');
    try {
      await usersApi.updateUser(user.id, categoryKey, {
        name:  form.name.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
      });
      onSaved(`${form.name} updated successfully.`);
      onClose();
    } catch (e) {
      setErr(e.message || 'Update failed.');
    } finally {
      setSaving(false);
    }
  };

  const cat = CATEGORIES.find((c) => c.key === categoryKey) || CATEGORIES[0];

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="xs"
      PaperProps={{
        sx: {
          borderRadius: 3, backgroundColor: theme.palette.background.paper,
          backgroundImage: 'none',
          border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)'}`,
          boxShadow: '0 24px 48px rgba(0,0,0,0.3)',
        },
      }}
    >
      <DialogTitle sx={{ pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{ bgcolor: cat.bgColor, borderRadius: 2, p: 0.8, display: 'flex', color: cat.color }}>
            <Edit fontSize="small" />
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2 }}>Edit {cat.singular}</Typography>
            <Typography variant="caption" color="text.secondary">Update user information</Typography>
          </Box>
          <IconButton onClick={onClose} sx={{ ml: 'auto' }} size="small"><Close fontSize="small" /></IconButton>
        </Box>
      </DialogTitle>
      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />
      <DialogContent sx={{ pt: 2, pb: 1 }}>
        {err && <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>{err}</Alert>}
        <TextField id="edit-user-name" label="Full Name" value={form.name}
          onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
          fullWidth margin="dense" InputLabelProps={{ shrink: true }} required />
        <TextField id="edit-user-email" label="Email" type="email" value={form.email}
          onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
          fullWidth margin="dense" InputLabelProps={{ shrink: true }} />
        <TextField id="edit-user-phone" label="Phone" value={form.phone}
          onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
          fullWidth margin="dense" InputLabelProps={{ shrink: true }} placeholder="+94XXXXXXXXX" />
      </DialogContent>
      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />
      <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
        <Button onClick={onClose} color="inherit" variant="outlined" disabled={saving}>Cancel</Button>
        <Button id="save-user-btn" onClick={handleSave} variant="contained" disabled={saving}
          startIcon={saving ? <CircularProgress size={14} color="inherit" /> : <Save fontSize="small" />}
          sx={{ backgroundColor: cat.color, '&:hover': { filter: 'brightness(0.9)' } }}>
          {saving ? 'Saving…' : 'Save Changes'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ── Delete Dialog ─────────────────────────────────────────────────────────────
const DeleteDialog = ({ open, user, categoryKey, onClose, onDeleted, theme }) => {
  const [deleting, setDeleting] = useState(false);
  const [err, setErr]           = useState('');
  const name = user ? (user.name || user.displayName || 'this user') : '';

  const handleDelete = async () => {
    setDeleting(true);
    setErr('');
    try {
      await usersApi.deleteUser(user.id, categoryKey);
      onDeleted(`${name} deleted successfully.`);
      onClose();
    } catch (e) {
      setErr(e.message || 'Delete failed.');
      setDeleting(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="xs"
      PaperProps={{
        sx: {
          borderRadius: 3, backgroundColor: theme.palette.background.paper,
          backgroundImage: 'none',
          border: '1px solid rgba(224,92,122,0.2)',
          boxShadow: '0 24px 48px rgba(0,0,0,0.3)',
        },
      }}
    >
      <DialogTitle sx={{ pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{ bgcolor: 'rgba(224,92,122,0.12)', borderRadius: 2, p: 0.8, display: 'flex', color: '#e05c7a' }}>
            <Warning fontSize="small" />
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2 }}>Delete User</Typography>
            <Typography variant="caption" color="text.secondary">This action cannot be undone</Typography>
          </Box>
          <IconButton onClick={onClose} sx={{ ml: 'auto' }} size="small"><Close fontSize="small" /></IconButton>
        </Box>
      </DialogTitle>
      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />
      <DialogContent sx={{ pt: 2 }}>
        {err && <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>{err}</Alert>}
        <Typography variant="body2" color="text.secondary">
          Are you sure you want to permanently delete{' '}
          <strong style={{ color: '#e05c7a' }}>{name}</strong>?
          This will remove their record from the database.
        </Typography>
      </DialogContent>
      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />
      <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
        <Button onClick={onClose} color="inherit" variant="outlined" disabled={deleting}>Cancel</Button>
        <Button id="confirm-delete-btn" onClick={handleDelete} variant="contained" color="error"
          disabled={deleting}
          startIcon={deleting ? <CircularProgress size={14} color="inherit" /> : <Delete fontSize="small" />}>
          {deleting ? 'Deleting…' : 'Delete User'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ── Main Component ────────────────────────────────────────────────────────────
export const UsersView = () => {
  const theme = useTheme();
  const [activeTab,     setActiveTab]     = useState(0);
  const [editTarget,    setEditTarget]    = useState(null);
  const [deleteTarget,  setDeleteTarget]  = useState(null);
  const [roleTarget,    setRoleTarget]    = useState(null); // { user }
  const [search,        setSearch]        = useState('');
  const [toast,         setToast]         = useState('');

  const { passengers, operators, admins, pending, loading, error } = useUsersFirestore();

  const counts = [passengers.length, operators.length, admins.length, pending.length];
  const lists  = [passengers, operators, admins, pending];

  const handleEdit       = (user, categoryKey) => setEditTarget({ user, categoryKey });
  const handleDelete     = (user, categoryKey) => setDeleteTarget({ user, categoryKey });
  const handleChangeRole = (user)               => setRoleTarget({ user });

  if (loading) {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: 300, gap: 2 }}>
        <CircularProgress sx={{ color: '#E68D33' }} />
        <Typography variant="body2" color="text.secondary">Loading users…</Typography>
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
        <Typography variant="h4" sx={{ fontWeight: 800, letterSpacing: -0.5 }}>
          Users Management
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
          View, verify, edit, and manage all users across every role
        </Typography>
      </Box>

      {/* ── Pending alert banner ────────────────────────────────────────── */}
      {pending.length > 0 && (
        <Box
          onClick={() => { setActiveTab(3); setSearch(''); }}
          sx={{
            mb: 3, p: 2, borderRadius: 2, cursor: 'pointer',
            backgroundColor: 'transparent',
            border: '1px solid rgba(245,158,11,0.35)',
            display: 'flex', alignItems: 'center', gap: 1.5,
            transition: 'all 0.2s',
            '&:hover': { backgroundColor: 'rgba(245,158,11,0.04)' },
          }}
        >
          <PendingActions sx={{ color: '#f59e0b' }} />
          <Box sx={{ flex: 1 }}>
            <Typography variant="body2" sx={{ fontWeight: 700, color: '#f59e0b' }}>
              {pending.length} account{pending.length > 1 ? 's' : ''} pending verification
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Click to review and assign roles to pending users
            </Typography>
          </Box>
          <Chip
            label={pending.length}
            size="small"
            sx={{ backgroundColor: '#f59e0b', color: '#000', fontWeight: 800, fontSize: '0.8rem' }}
          />
        </Box>
      )}

      {/* ── Stat cards ─────────────────────────────────────────────────── */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 2, mb: 3 }}>
        {CATEGORIES.map((cat, i) => (
          <Box
            key={cat.key}
            id={`stat-card-${cat.key}`}
            onClick={() => { setActiveTab(i); setSearch(''); }}
            sx={{
              p: 2, borderRadius: 3, cursor: 'pointer',
              backgroundColor: activeTab === i ? cat.bgColor : theme.palette.background.paper,
              border: `1px solid ${activeTab === i ? cat.color + '55' : (theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.06)')}`,
              transition: 'all 0.2s ease',
              boxShadow: activeTab === i
                ? `0 6px 20px ${cat.color}28`
                : (theme.palette.mode === 'dark' ? '0 2px 8px rgba(0,0,0,0.2)' : '0 2px 8px rgba(0,0,0,0.04)'),
              '&:hover': { transform: 'translateY(-2px)', boxShadow: `0 8px 24px ${cat.color}28` },
              // Pulsing ring on Pending card if there are pending users
              ...(cat.key === 'pending' && pending.length > 0 && activeTab !== i && {
                animation: 'pendingPulse 2s infinite',
                '@keyframes pendingPulse': {
                  '0%, 100%': { borderColor: 'rgba(245,158,11,0.3)' },
                  '50%':      { borderColor: 'rgba(245,158,11,0.8)' },
                },
              }),
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
              <Box sx={{
                color: cat.color,
                bgcolor: 'transparent',
                display: 'flex',
                '& .MuiSvgIcon-root': { fontSize: 28 },
              }}>
                {cat.icon}
              </Box>
              <Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                  <Typography variant="h5" sx={{ fontWeight: 800, color: cat.color, lineHeight: 1 }}>
                    {counts[i]}
                  </Typography>
                  {/* Red dot badge on Pending if count > 0 */}
                  {cat.key === 'pending' && counts[i] > 0 && (
                    <Box sx={{
                      width: 8, height: 8, borderRadius: '50%',
                      backgroundColor: '#f59e0b',
                      animation: 'dot-blink 1.4s infinite',
                      '@keyframes dot-blink': { '0%,100%': { opacity: 1 }, '50%': { opacity: 0.3 } },
                    }} />
                  )}
                </Box>
                <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.8 }}>
                  {cat.label}
                </Typography>
              </Box>
            </Box>
          </Box>
        ))}
      </Box>

      {/* ── Main panel ─────────────────────────────────────────────────── */}
      <Box sx={{
        borderRadius: 3,
        backgroundColor: theme.palette.background.paper,
        boxShadow: theme.palette.mode === 'dark' ? '0 4px 24px rgba(0,0,0,0.3)' : '0 4px 24px rgba(0,0,0,0.06)',
        border: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.06)'}`,
        overflow: 'hidden',
      }}>

        {/* Tabs */}
        <Tabs
          value={activeTab}
          onChange={(_, v) => { setActiveTab(v); setSearch(''); }}
          sx={{
            borderBottom: `1px solid ${theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.06)'}`,
            '& .MuiTab-root': {
              fontWeight: 600, fontSize: '0.82rem', textTransform: 'uppercase',
              letterSpacing: 0.8, color: theme.palette.text.secondary,
              py: 2, px: 3, '&.Mui-selected': { color: '#E68D33' },
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
                  <Box component="span" sx={{
                    px: 1, py: 0.2, borderRadius: 10,
                    fontSize: '0.7rem', fontWeight: 700,
                    backgroundColor: activeTab === i
                      ? (cat.key === 'pending' ? 'rgba(245,158,11,0.2)' : 'rgba(230,141,51,0.15)')
                      : 'rgba(128,128,128,0.12)',
                    color: activeTab === i
                      ? (cat.key === 'pending' ? '#f59e0b' : '#E68D33')
                      : (cat.key === 'pending' && counts[i] > 0 ? '#f59e0b' : theme.palette.text.secondary),
                  }}>
                    {counts[i]}
                  </Box>
                </Box>
              }
            />
          ))}
        </Tabs>

        {/* Search bar */}
        <Box sx={{ px: 3, pt: 2.5, pb: 1 }}>
          <TextField
            id="users-search"
            size="small"
            placeholder={`Search ${CATEGORIES[activeTab].label.toLowerCase()}…`}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            InputProps={{
              startAdornment: <Search sx={{ mr: 1, color: 'text.disabled', fontSize: '1.1rem' }} />,
            }}
            sx={{ width: { xs: '100%', sm: 320 } }}
          />
        </Box>

        {/* Pending tab helper text */}
        {activeTab === 3 && pending.length > 0 && (
          <Box sx={{ px: 3, pb: 1 }}>
            <Typography variant="caption" color="text.secondary">
              🔑 Click the <strong style={{ color: '#f59e0b' }}>yellow key icon</strong> on any user to verify and assign their role.
            </Typography>
          </Box>
        )}

        {/* List panels */}
        {CATEGORIES.map((cat, i) => (
          <TabPanel key={cat.key} value={activeTab} index={i} catKey={cat.key}>
            <Box sx={{ px: 3, pb: 3, pt: 1 }}>
              <UserList
                users={lists[i]}
                categoryKey={cat.key}
                onEdit={handleEdit}
                onDelete={handleDelete}
                onChangeRole={handleChangeRole}
                search={search}
                theme={theme}
              />
            </Box>
          </TabPanel>
        ))}
      </Box>

      {/* ── Dialogs ──────────────────────────────────────────────────── */}
      <ChangeRoleDialog
        open={Boolean(roleTarget)}
        user={roleTarget?.user || null}
        onClose={() => setRoleTarget(null)}
        onDone={(msg) => setToast(msg)}
        theme={theme}
      />

      <EditDialog
        open={Boolean(editTarget)}
        user={editTarget?.user || null}
        categoryKey={editTarget?.categoryKey || 'passengers'}
        onClose={() => setEditTarget(null)}
        onSaved={(msg) => setToast(msg)}
        theme={theme}
      />

      <DeleteDialog
        open={Boolean(deleteTarget)}
        user={deleteTarget?.user || null}
        categoryKey={deleteTarget?.categoryKey || 'passengers'}
        onClose={() => setDeleteTarget(null)}
        onDeleted={(msg) => setToast(msg)}
        theme={theme}
      />

      {/* Toast */}
      <Snackbar
        open={Boolean(toast)}
        autoHideDuration={4000}
        onClose={() => setToast('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
        message={toast}
      />
    </Box>
  );
};
