import React, { useState, useEffect } from 'react';
import {
  Typography,
  Card,
  CardContent,
  Box,
  Grid,
  TextField,
  Button,
  Chip,
  CircularProgress,
  Alert,
  Divider,
  Avatar,
  Badge,
  IconButton,
  Tooltip,
  useTheme,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Autocomplete,
} from '@mui/material';
import {
  Send,
  ReportProblem,
  DirectionsBus,
  Person,
  CheckCircle,
  HourglassEmpty,
  Autorenew,
  Reply as ReplyIcon,
  NotificationsActive,
  MarkEmailRead,
  Message,
  ForwardToInbox,
} from '@mui/icons-material';
import {
  collection,
  query,
  orderBy,
  onSnapshot,
  doc,
  updateDoc,
  serverTimestamp,
  addDoc,
  Timestamp,
} from 'firebase/firestore';
import { db } from '../../api/firebase';
import { useUsersFirestore } from '../users/useUsersFirestore';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
const STATUS_COLORS = {
  pending: 'warning',
  in_progress: 'info',
  resolved: 'success',
};

const STATUS_LABELS = {
  pending: 'Pending',
  in_progress: 'In Progress',
  resolved: 'Resolved',
};

function timeAgo(ts) {
  if (!ts) return '';
  const dt = ts instanceof Timestamp ? ts.toDate() : new Date(ts);
  const diff = Math.floor((Date.now() - dt.getTime()) / 1000);
  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return dt.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Card
// ─────────────────────────────────────────────────────────────────────────────
function ReportCard({ report, isSelected, onClick, isOperator }) {
  const theme = useTheme();
  const hasReply = !!report.adminReply;
  const borderColor = isSelected ? '#E68D33' : 'transparent';

  return (
    <Card
      onClick={onClick}
      sx={{
        mb: 1.5,
        cursor: 'pointer',
        border: `2px solid ${borderColor}`,
        transition: 'all 0.2s',
        backgroundColor: isSelected
          ? (theme.palette.mode === 'dark' ? 'rgba(230,141,51,0.12)' : 'rgba(230,141,51,0.06)')
          : theme.palette.background.paper,
        '&:hover': { border: '2px solid #E68D33', transform: 'translateY(-1px)' },
      }}
    >
      <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1.5 }}>
          <Avatar
            sx={{
              bgcolor: isOperator ? 'rgba(230,141,51,0.15)' : 'rgba(99,102,241,0.15)',
              width: 36,
              height: 36,
            }}
          >
            {isOperator ? (
              <DirectionsBus sx={{ fontSize: 18, color: '#E68D33' }} />
            ) : (
              <Person sx={{ fontSize: 18, color: '#6366f1' }} />
            )}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
              <Typography variant="caption" sx={{ fontWeight: 700, color: 'text.secondary', textTransform: 'uppercase', letterSpacing: 0.5 }}>
                {isOperator
                  ? `Operator · ${report.operatorId || report.operatorName || 'Unknown'}`
                  : `Passenger · ${report.passengerName || report.passengerId || 'Unknown'}`}
              </Typography>
              <Typography variant="caption" color="text.disabled">{timeAgo(report.createdAt)}</Typography>
            </Box>
            <Typography variant="body2" sx={{ fontWeight: 600, mb: 0.5 }} noWrap>
              {report.title || report.type || 'Report'}
            </Typography>
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }} noWrap>
              {report.description}
            </Typography>
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
              <Chip
                size="small"
                label={STATUS_LABELS[report.status] || report.status}
                color={STATUS_COLORS[report.status] || 'default'}
                sx={{ height: 20, fontSize: 10 }}
              />
              {hasReply && (
                <Chip
                  size="small"
                  icon={<MarkEmailRead sx={{ fontSize: 12 }} />}
                  label="Replied"
                  color="success"
                  variant="outlined"
                  sx={{ height: 20, fontSize: 10 }}
                />
              )}
            </Box>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reply Panel
// ─────────────────────────────────────────────────────────────────────────────
function ReplyPanel({ report, isOperator, onReplySent }) {
  const theme = useTheme();
  const [replyText, setReplyText] = useState('');
  const [newStatus, setNewStatus] = useState(report?.status || 'pending');
  const [sending, setSending] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    setReplyText('');
    setNewStatus(report?.status || 'pending');
    setSuccess('');
    setError('');
  }, [report?.id]);

  if (!report) {
    return (
      <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: 400, color: 'text.disabled' }}>
        <ReportProblem sx={{ fontSize: 64, mb: 2, opacity: 0.3 }} />
        <Typography variant="body2">Select a report from the list to view details and reply</Typography>
      </Box>
    );
  }

  const handleSend = async () => {
    if (!replyText.trim()) return;
    setSending(true);
    setSuccess('');
    setError('');
    try {
      const collectionName = isOperator ? 'operator_reports' : 'passenger_reports';
      const reportRef = doc(db, collectionName, report.id);

      // 1. Update the report document with admin reply + status change
      await updateDoc(reportRef, {
        adminReply: replyText.trim(),
        adminReplyAt: serverTimestamp(),
        status: newStatus,
        repliedAt: serverTimestamp(),
      });

      // 2. Write a notification to the user's Firestore inbox
      const targetUid = isOperator ? report.operatorId : report.passengerId;
      if (targetUid) {
        await addDoc(collection(db, 'notifications', targetUid, 'items'), {
          title: '📬 Admin replied to your report',
          body: replyText.trim(),
          type: 'alert',
          isRead: false,
          createdAt: serverTimestamp(),
          data: {
            type: 'admin_reply',
            reportId: report.id,
            targetUserId: targetUid,
          },
        });
      }

      setSuccess('Reply sent successfully! The user will receive the notification on their mobile app.');
      setReplyText('');
      if (onReplySent) onReplySent();
    } catch (e) {
      setError(`Failed to send reply: ${e.message}`);
    } finally {
      setSending(false);
    }
  };

  const markResolved = async () => {
    try {
      const collectionName = isOperator ? 'operator_reports' : 'passenger_reports';
      await updateDoc(doc(db, collectionName, report.id), {
        status: 'resolved',
        resolvedAt: serverTimestamp(),
      });
      setNewStatus('resolved');
      setSuccess('Report marked as Resolved.');
    } catch (e) {
      setError(`Failed to update status: ${e.message}`);
    }
  };

  return (
    <Box>
      {/* Report Header */}
      <Box sx={{ mb: 3, p: 2, borderRadius: 3, backgroundColor: theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)', border: '1px solid', borderColor: 'divider' }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
          <Box>
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>{report.title || report.type}</Typography>
            <Typography variant="caption" color="text.secondary">
              {isOperator
                ? `Operator: ${report.operatorName || report.operatorId}`
                : `Passenger: ${report.passengerName || report.passengerId}`}
              {' · '}{timeAgo(report.createdAt)}
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Chip size="small" label={STATUS_LABELS[report.status] || report.status} color={STATUS_COLORS[report.status] || 'default'} />
            {report.status !== 'resolved' && (
              <Tooltip title="Mark as Resolved">
                <IconButton size="small" onClick={markResolved} color="success">
                  <CheckCircle fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
          </Box>
        </Box>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 1, lineHeight: 1.6 }}>
          {report.description}
        </Typography>
        <Typography variant="caption" sx={{ mt: 1.5, display: 'block', color: 'text.disabled', fontFamily: 'monospace' }}>
          Target UID: {report.operatorId || report.passengerId}
        </Typography>
      </Box>

      {/* Previous Admin Reply if any */}
      {report.adminReply && (
        <Box sx={{ mb: 3, p: 2, borderRadius: 3, backgroundColor: 'rgba(230,141,51,0.06)', border: '1px solid rgba(230,141,51,0.25)' }}>
          <Typography variant="caption" sx={{ fontWeight: 700, color: '#E68D33', textTransform: 'uppercase', letterSpacing: 0.5 }}>
            Previous Admin Reply
          </Typography>
          <Typography variant="body2" sx={{ mt: 1, lineHeight: 1.6 }}>{report.adminReply}</Typography>
          <Typography variant="caption" color="text.disabled">{timeAgo(report.adminReplyAt)}</Typography>
        </Box>
      )}

      <Divider sx={{ mb: 3 }} />

      {/* Reply Form */}
      <Typography variant="subtitle2" sx={{ mb: 2, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
        <ReplyIcon fontSize="small" /> Reply to {isOperator ? 'Operator' : 'Passenger'}
      </Typography>

      {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}
      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <TextField
        fullWidth
        multiline
        rows={4}
        placeholder={`Type your reply to this ${isOperator ? 'operator' : 'passenger'}...`}
        value={replyText}
        onChange={(e) => setReplyText(e.target.value)}
        sx={{ mb: 2 }}
        variant="outlined"
      />

      {/* Status selector */}
      <Box sx={{ display: 'flex', gap: 1, mb: 3, flexWrap: 'wrap', alignItems: 'center' }}>
        <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', mr: 1 }}>Status after reply:</Typography>
        {['pending', 'in_progress', 'resolved'].map((s) => (
          <Chip
            key={s}
            label={STATUS_LABELS[s]}
            color={newStatus === s ? STATUS_COLORS[s] : 'default'}
            variant={newStatus === s ? 'filled' : 'outlined'}
            onClick={() => setNewStatus(s)}
            icon={s === 'pending' ? <HourglassEmpty /> : s === 'in_progress' ? <Autorenew /> : <CheckCircle />}
            sx={{ cursor: 'pointer' }}
          />
        ))}
      </Box>

      <Button
        variant="contained"
        fullWidth
        size="large"
        disabled={sending || !replyText.trim()}
        startIcon={sending ? <CircularProgress size={18} /> : <Send />}
        onClick={handleSend}
        sx={{ backgroundColor: '#E68D33', '&:hover': { backgroundColor: '#D4772B' } }}
      >
        Send Reply & Notify User
      </Button>
    </Box>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Direct Message / Send to User Tab (Replaces old Broadcast layout)
// ─────────────────────────────────────────────────────────────────────────────
function DirectMessagePanel({ passengers, operators }) {
  const [targetUid, setTargetUid] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [notifType, setNotifType] = useState('alert');
  const [sending, setSending] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  // Combined options for autocomplete
  const userOptions = [
    ...operators.map(o => ({
      id: o.id,
      label: `[Operator] ${o.displayName || o.name || 'Unnamed'} (${o.operatorId || o.id})`,
      role: 'Operator',
      uid: o.id,
    })),
    ...passengers.map(p => ({
      id: p.id,
      label: `[Passenger] ${p.displayName || p.name || 'Unnamed'} (${p.email || p.phone || p.id})`,
      role: 'Passenger',
      uid: p.id,
    })),
  ];

  const handleSendDirect = async (e) => {
    e.preventDefault();
    const uidToSend = targetUid.trim() || selectedUser?.uid;
    if (!uidToSend) {
      setError('Please provide a Target User UID or select a user.');
      return;
    }
    if (!title.trim() || !body.trim()) {
      setError('Please provide both a Title and Message Body.');
      return;
    }

    setSending(true);
    setSuccess('');
    setError('');

    try {
      // Write to the user's notification inbox
      await addDoc(collection(db, 'notifications', uidToSend, 'items'), {
        title: title.trim(),
        body: body.trim(),
        type: notifType,
        isRead: false,
        createdAt: serverTimestamp(),
        data: {
          type: 'direct_admin_message',
          targetUserId: uidToSend,
        },
      });

      setSuccess(`Notification successfully sent to user (${uidToSend})!`);
      setTitle('');
      setBody('');
      setTargetUid('');
      setSelectedUser(null);
    } catch (err) {
      setError(`Failed to send notification: ${err.message}`);
    } finally {
      setSending(false);
    }
  };

  return (
    <Card sx={{ maxWidth: 800, mx: 'auto', boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
      <CardContent sx={{ p: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 3 }}>
          <Avatar sx={{ bgcolor: 'rgba(230,141,51,0.15)' }}>
            <ForwardToInbox sx={{ color: '#E68D33' }} />
          </Avatar>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700 }}>Send Notification to User</Typography>
            <Typography variant="body2" color="text.secondary">
              Directly dispatch a push notification to any Operator or Passenger
            </Typography>
          </Box>
        </Box>

        {success && <Alert severity="success" sx={{ mb: 3 }}>{success}</Alert>}
        {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

        <form onSubmit={handleSendDirect}>
          <Autocomplete
            options={userOptions}
            getOptionLabel={(option) => option.label || ''}
            value={selectedUser}
            onChange={(_, newValue) => {
              setSelectedUser(newValue);
              if (newValue) setTargetUid(newValue.uid);
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                label="Quick Select Operator / Passenger"
                placeholder="Type name, phone, email or operator ID..."
                variant="outlined"
                margin="normal"
              />
            )}
            sx={{ mb: 2 }}
          />

          <TextField
            fullWidth
            label="Target User UID"
            placeholder="e.g. 3jKl9x... (Firebase Auth UID)"
            value={targetUid}
            onChange={(e) => setTargetUid(e.target.value)}
            variant="outlined"
            margin="normal"
            helperText="The notification will be delivered directly to this user's mobile app inbox"
          />

          <FormControl fullWidth margin="normal">
            <InputLabel>Notification Type</InputLabel>
            <Select
              value={notifType}
              label="Notification Type"
              onChange={(e) => setNotifType(e.target.value)}
            >
              <MenuItem value="alert">⚠️ Urgent Alert</MenuItem>
              <MenuItem value="notice">📢 General Notice</MenuItem>
              <MenuItem value="booking">🎫 Booking Update</MenuItem>
              <MenuItem value="wallet">💰 Payment / Earning Update</MenuItem>
            </Select>
          </FormControl>

          <TextField
            fullWidth
            label="Notification Title"
            placeholder="e.g. Important Schedule Update"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            variant="outlined"
            margin="normal"
          />

          <TextField
            fullWidth
            multiline
            rows={4}
            label="Message Body"
            placeholder="Type your message here..."
            value={body}
            onChange={(e) => setBody(e.target.value)}
            variant="outlined"
            margin="normal"
          />

          <Button
            type="submit"
            variant="contained"
            size="large"
            disabled={sending}
            startIcon={sending ? <CircularProgress size={20} /> : <Send />}
            sx={{
              mt: 3,
              width: '100%',
              backgroundColor: '#E68D33',
              '&:hover': { backgroundColor: '#D4772B' },
              py: 1.5,
              fontWeight: 700,
            }}
          >
            Send Notification
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main NotificationsView
// ─────────────────────────────────────────────────────────────────────────────
export const NotificationsView = () => {
  const [mainTab, setMainTab] = useState(0); // 0 = Reports Inbox, 1 = Send to User
  const [reportsTab, setReportsTab] = useState(0); // 0 = Operators, 1 = Passengers
  const [operatorReports, setOperatorReports] = useState([]);
  const [passengerReports, setPassengerReports] = useState([]);
  const [loadingOp, setLoadingOp] = useState(true);
  const [loadingPax, setLoadingPax] = useState(true);
  const [selectedReport, setSelectedReport] = useState(null);

  const { passengers = [], operators = [] } = useUsersFirestore();

  // Subscribe to operator_reports
  useEffect(() => {
    const q = query(collection(db, 'operator_reports'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(
      q,
      (snap) => {
        setOperatorReports(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoadingOp(false);
      },
      (err) => {
        console.error('[operator_reports stream error]', err);
        setLoadingOp(false);
      }
    );
    return unsub;
  }, []);

  // Subscribe to passenger_reports
  useEffect(() => {
    const q = query(collection(db, 'passenger_reports'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(
      q,
      (snap) => {
        setPassengerReports(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoadingPax(false);
      },
      (err) => {
        console.error('[passenger_reports stream error]', err);
        setLoadingPax(false);
      }
    );
    return unsub;
  }, []);

  const pendingOp = operatorReports.filter((r) => r.status === 'pending').length;
  const pendingPax = passengerReports.filter((r) => r.status === 'pending').length;
  const currentReports = reportsTab === 0 ? operatorReports : passengerReports;
  const loading = reportsTab === 0 ? loadingOp : loadingPax;

  const handleSelect = (report) => {
    setSelectedReport(report);
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3, flexWrap: 'wrap', gap: 2 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Notifications & Reports</Typography>
        <Box sx={{ display: 'flex', gap: 1.5 }}>
          {pendingOp > 0 && (
            <Chip icon={<NotificationsActive />} label={`${pendingOp} Pending Operator Reports`} color="warning" />
          )}
          {pendingPax > 0 && (
            <Chip icon={<NotificationsActive />} label={`${pendingPax} Pending Passenger Reports`} color="info" />
          )}
        </Box>
      </Box>

      {/* Main Mode Tabs: Incoming Reports vs Send to User */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs
          value={mainTab}
          onChange={(_, v) => { setMainTab(v); }}
        >
          <Tab
            icon={<Message sx={{ mr: 1 }} />}
            iconPosition="start"
            label={
              <Badge badgeContent={pendingOp + pendingPax} color="error">
                <Box sx={{ pr: (pendingOp + pendingPax) > 0 ? 1.5 : 0 }}>
                  Incoming Reports & Inquiries
                </Box>
              </Badge>
            }
          />
          <Tab
            icon={<Send sx={{ mr: 1 }} />}
            iconPosition="start"
            label="Send to User (Direct Message)"
          />
        </Tabs>
      </Box>

      {/* Tab 0: Incoming Reports View */}
      {mainTab === 0 && (
        <Grid container spacing={3}>
          {/* Left List */}
          <Grid item xs={12} md={5}>
            <Card sx={{ boxShadow: '0 4px 20px rgba(0,0,0,0.08)', height: '100%' }}>
              <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
                <Tabs
                  value={reportsTab}
                  onChange={(_, v) => { setReportsTab(v); setSelectedReport(null); }}
                >
                  <Tab
                    label={
                      <Badge badgeContent={pendingOp} color="warning" max={99}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, pr: pendingOp > 0 ? 1.5 : 0 }}>
                          <DirectionsBus fontSize="small" />
                          Operators ({operatorReports.length})
                        </Box>
                      </Badge>
                    }
                  />
                  <Tab
                    label={
                      <Badge badgeContent={pendingPax} color="info" max={99}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, pr: pendingPax > 0 ? 1.5 : 0 }}>
                          <Person fontSize="small" />
                          Passengers ({passengerReports.length})
                        </Box>
                      </Badge>
                    }
                  />
                </Tabs>
              </Box>
              <CardContent sx={{ p: 2, overflowY: 'auto', maxHeight: 600 }}>
                {loading ? (
                  <Box sx={{ display: 'flex', justifyContent: 'center', pt: 4 }}>
                    <CircularProgress color="warning" />
                  </Box>
                ) : currentReports.length === 0 ? (
                  <Box sx={{ textAlign: 'center', pt: 6, color: 'text.disabled' }}>
                    <ReportProblem sx={{ fontSize: 48, mb: 1, opacity: 0.3 }} />
                    <Typography variant="body2">No reports found</Typography>
                  </Box>
                ) : (
                  currentReports.map((report) => (
                    <ReportCard
                      key={report.id}
                      report={report}
                      isOperator={reportsTab === 0}
                      isSelected={selectedReport?.id === report.id}
                      onClick={() => handleSelect(report)}
                    />
                  ))
                )}
              </CardContent>
            </Card>
          </Grid>

          {/* Right Reply Panel */}
          <Grid item xs={12} md={7}>
            <Card sx={{ boxShadow: '0 4px 20px rgba(0,0,0,0.08)', height: '100%' }}>
              <CardContent sx={{ p: 3 }}>
                <ReplyPanel
                  report={selectedReport}
                  isOperator={reportsTab === 0}
                  onReplySent={() => {
                    const refreshed = currentReports.find((r) => r.id === selectedReport?.id);
                    if (refreshed) setSelectedReport(refreshed);
                  }}
                />
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Tab 1: Send to User Direct Message */}
      {mainTab === 1 && (
        <DirectMessagePanel passengers={passengers} operators={operators} />
      )}
    </Box>
  );
};
