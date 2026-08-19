import React, { useState } from 'react';
import { 
  Typography, 
  Card, 
  CardContent, 
  Box, 
  Grid,
  Switch,
  FormControlLabel,
  Button,
  Divider,
  Snackbar,
  Alert,
  useTheme
} from '@mui/material';
import { Save } from '@mui/icons-material';
import { useColorMode } from '../../providers/AppProviders';

export const SettingsView = () => {
  const theme = useTheme();
  const { toggleColorMode } = useColorMode();
  
  const [emailSummaries, setEmailSummaries] = useState(true);
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [snackbarMessage, setSnackbarMessage] = useState('');

  const handleAction = (message) => {
    setSnackbarMessage(message);
  };

  const handleCloseSnackbar = () => {
    setSnackbarMessage('');
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>System Settings</Typography>
      </Box>

      <Grid container spacing={4}>
        <Grid item xs={12} md={6}>
          <Card sx={{ boxShadow: '0 4px 20px rgba(0,0,0,0.5)' }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>General Preferences</Typography>
              
              <FormControlLabel 
                control={
                  <Switch 
                    checked={theme.palette.mode === 'dark'} 
                    onChange={toggleColorMode} 
                    color="primary" 
                  />
                } 
                label="Enable Dark Mode" 
                sx={{ display: 'block', mb: 2 }}
              />
              <FormControlLabel 
                control={
                  <Switch 
                    checked={emailSummaries} 
                    onChange={(e) => setEmailSummaries(e.target.checked)}
                    color="primary" 
                  />
                } 
                label="Receive Email Summaries" 
                sx={{ display: 'block', mb: 2 }}
              />
              <FormControlLabel 
                control={
                  <Switch 
                    checked={maintenanceMode}
                    onChange={(e) => setMaintenanceMode(e.target.checked)}
                    color="primary" 
                  />
                } 
                label="Maintenance Mode" 
                sx={{ display: 'block', mb: 2 }}
              />
              
              <Divider sx={{ my: 3, borderColor: 'rgba(255,255,255,0.05)' }} />
              
              <Button 
                variant="contained" 
                startIcon={<Save />}
                onClick={() => handleAction('Preferences saved successfully.')}
              >
                Save Preferences
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card sx={{ boxShadow: '0 4px 20px rgba(0,0,0,0.5)' }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Security & Danger Zone</Typography>
              
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                Manage critical security settings for the admin portal.
              </Typography>
              
              <Button 
                variant="outlined" 
                color="primary" 
                sx={{ mb: 2, display: 'block' }}
                onClick={() => handleAction('Password reset link sent to your email.')}
              >
                Change Password
              </Button>
              <Button 
                variant="outlined" 
                color="primary" 
                sx={{ mb: 4, display: 'block' }}
                onClick={() => handleAction('Two-Factor Authentication setup initiated.')}
              >
                Enable Two-Factor Auth
              </Button>

              <Divider sx={{ my: 3, borderColor: 'rgba(255,255,255,0.05)' }} />

              <Typography variant="subtitle2" color="error" sx={{ mb: 1, fontWeight: 600 }}>
                Danger Zone
              </Typography>
              <Button 
                variant="contained" 
                color="error"
                onClick={() => handleAction('Analytics data purge scheduled.')}
              >
                Purge Analytics Data
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Snackbar 
        open={!!snackbarMessage} 
        autoHideDuration={4000} 
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert onClose={handleCloseSnackbar} severity="info" sx={{ width: '100%', boxShadow: '0 4px 20px rgba(0,0,0,0.5)' }}>
          {snackbarMessage}
        </Alert>
      </Snackbar>
    </Box>
  );
};
