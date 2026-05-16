import React, { useState } from 'react';
import { 
  Typography, 
  Card, 
  CardContent, 
  Box, 
  Grid,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Tabs,
  Tab,
  Alert,
  CircularProgress,
  useTheme
} from '@mui/material';
import { Send, Campaign } from '@mui/icons-material';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useBroadcastNotification, useSendUserNotification } from '../../api/notifications';

const broadcastSchema = z.object({
  scheduleId: z.string().min(1, 'Schedule ID is required'),
  title: z.string().min(1, 'Title is required'),
  body: z.string().min(1, 'Message body is required'),
});

const userSchema = z.object({
  userId: z.string().min(1, 'User ID is required'),
  title: z.string().min(1, 'Title is required'),
  body: z.string().min(1, 'Message body is required'),
});

function TabPanel(props) {
  const { children, value, index, ...other } = props;
  return (
    <div role="tabpanel" hidden={value !== index} {...other}>
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

export const NotificationsView = () => {
  const theme = useTheme();
  const [tabValue, setTabValue] = useState(0);
  const [successMsg, setSuccessMsg] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const broadcastMutation = useBroadcastNotification();
  const userMutation = useSendUserNotification();

  const handleTabChange = (event, newValue) => {
    setTabValue(newValue);
    setSuccessMsg('');
    setErrorMsg('');
  };

  const {
    control: broadcastControl,
    handleSubmit: handleBroadcastSubmit,
    reset: resetBroadcast,
    formState: { errors: broadcastErrors, isSubmitting: isBroadcastSubmitting }
  } = useForm({
    resolver: zodResolver(broadcastSchema),
    defaultValues: { scheduleId: '', title: '', body: '' }
  });

  const {
    control: userControl,
    handleSubmit: handleUserSubmit,
    reset: resetUser,
    formState: { errors: userErrors, isSubmitting: isUserSubmitting }
  } = useForm({
    resolver: zodResolver(userSchema),
    defaultValues: { userId: '', title: '', body: '' }
  });

  const onBroadcast = async (data) => {
    setSuccessMsg('');
    setErrorMsg('');
    try {
      await broadcastMutation.mutateAsync(data);
      setSuccessMsg('Broadcast sent successfully to all passengers on the schedule.');
      resetBroadcast();
    } catch (err) {
      setErrorMsg(err.message || 'Failed to send broadcast.');
    }
  };

  const onUserSend = async (data) => {
    setSuccessMsg('');
    setErrorMsg('');
    try {
      await userMutation.mutateAsync(data);
      setSuccessMsg('Notification sent successfully to the user.');
      resetUser();
    } catch (err) {
      setErrorMsg(err.message || 'Failed to send notification.');
    }
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Dispatch Notifications</Typography>
      </Box>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8} lg={6}>
          <Card sx={{ boxShadow: '0 4px 20px rgba(0,0,0,0.5)' }}>
            <Box sx={{ borderBottom: 1, borderColor: 'rgba(255,255,255,0.05)' }}>
              <Tabs value={tabValue} onChange={handleTabChange} aria-label="notification tabs">
                <Tab icon={<Campaign sx={{ mr: 1 }} />} iconPosition="start" label="Broadcast to Schedule" />
                <Tab icon={<Send sx={{ mr: 1 }} />} iconPosition="start" label="Send to User" />
              </Tabs>
            </Box>

            <CardContent>
              {successMsg && <Alert severity="success" sx={{ mb: 3 }}>{successMsg}</Alert>}
              {errorMsg && <Alert severity="error" sx={{ mb: 3 }}>{errorMsg}</Alert>}

              {/* Broadcast Tab */}
              <TabPanel value={tabValue} index={0}>
                <form onSubmit={handleBroadcastSubmit(onBroadcast)}>
                  <Controller
                    name="scheduleId"
                    control={broadcastControl}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Schedule ID"
                        variant="outlined"
                        margin="normal"
                        error={!!broadcastErrors.scheduleId}
                        helperText={broadcastErrors.scheduleId?.message || "All passengers booked on this schedule will receive the push notification."}
                      />
                    )}
                  />
                  <Controller
                    name="title"
                    control={broadcastControl}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Notification Title"
                        variant="outlined"
                        margin="normal"
                        error={!!broadcastErrors.title}
                        helperText={broadcastErrors.title?.message}
                      />
                    )}
                  />
                  <Controller
                    name="body"
                    control={broadcastControl}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Message Body"
                        variant="outlined"
                        margin="normal"
                        multiline
                        rows={4}
                        error={!!broadcastErrors.body}
                        helperText={broadcastErrors.body?.message}
                      />
                    )}
                  />
                  <Button 
                    type="submit" 
                    variant="contained" 
                    size="large" 
                    disabled={isBroadcastSubmitting}
                    startIcon={isBroadcastSubmitting ? <CircularProgress size={20} /> : <Campaign />}
                    sx={{ mt: 3, width: '100%' }}
                  >
                    Send Broadcast
                  </Button>
                </form>
              </TabPanel>

              {/* Individual User Tab */}
              <TabPanel value={tabValue} index={1}>
                <form onSubmit={handleUserSubmit(onUserSend)}>
                  <Controller
                    name="userId"
                    control={userControl}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Target User UID"
                        variant="outlined"
                        margin="normal"
                        error={!!userErrors.userId}
                        helperText={userErrors.userId?.message}
                      />
                    )}
                  />
                  <Controller
                    name="title"
                    control={userControl}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Notification Title"
                        variant="outlined"
                        margin="normal"
                        error={!!userErrors.title}
                        helperText={userErrors.title?.message}
                      />
                    )}
                  />
                  <Controller
                    name="body"
                    control={userControl}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        fullWidth
                        label="Message Body"
                        variant="outlined"
                        margin="normal"
                        multiline
                        rows={4}
                        error={!!userErrors.body}
                        helperText={userErrors.body?.message}
                      />
                    )}
                  />
                  <Button 
                    type="submit" 
                    variant="contained" 
                    size="large" 
                    disabled={isUserSubmitting}
                    startIcon={isUserSubmitting ? <CircularProgress size={20} /> : <Send />}
                    sx={{ mt: 3, width: '100%' }}
                  >
                    Send Notification
                  </Button>
                </form>
              </TabPanel>

            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4} lg={6}>
          <Box sx={{ p: 3, backgroundColor: 'rgba(99, 102, 241, 0.05)', borderRadius: 4, height: '100%' }}>
            <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>About Push Notifications</Typography>
            <Typography variant="body2" color="text.secondary" paragraph>
              The RideSync Notification Engine utilizes Firebase Cloud Messaging (FCM) to deliver real-time push alerts directly to the Flutter Mobile App.
            </Typography>
            <Typography variant="subtitle2" sx={{ fontWeight: 600, mt: 2, mb: 1 }}>Broadcasts</Typography>
            <Typography variant="body2" color="text.secondary" paragraph>
              Sending a broadcast to a Schedule ID will efficiently dispatch a multicast message to the FCM tokens of all passengers currently holding an active booking for that specific trip. This is ideal for delay announcements or emergency reroutes.
            </Typography>
            <Typography variant="subtitle2" sx={{ fontWeight: 600, mt: 2, mb: 1 }}>Direct Messages</Typography>
            <Typography variant="body2" color="text.secondary">
              Targeting a specific User UID allows you to send account-related alerts, warnings, or personalized support responses directly to an individual's device.
            </Typography>
          </Box>
        </Grid>
      </Grid>
    </Box>
  );
};
