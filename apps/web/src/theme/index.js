import { createTheme } from '@mui/material/styles';

export const getDesignTokens = (mode) => ({
  palette: {
    mode,
    ...(mode === 'dark' 
      ? {
          primary: { main: '#f59e0b', light: '#fbbf24', dark: '#d97706' },
          secondary: { main: '#0f172a', light: '#1e293b', dark: '#000000' },
          background: { default: '#0f172a', paper: '#1e293b' },
          text: { primary: '#f8fafc', secondary: '#cbd5e1' },
        }
      : {
          primary: { main: '#f59e0b', light: '#fbbf24', dark: '#d97706' },
          secondary: { main: '#0f172a', light: '#1e293b', dark: '#334155' },
          background: { default: '#ffffff', paper: '#ffffff' },
          text: { primary: '#0f172a', secondary: '#475569' },
        }),
    error: { main: '#ef4444' },
    warning: { main: '#f59e0b' },
    info: { main: '#3b82f6' },
    success: { main: '#10b981' },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: { fontWeight: 700 },
    h2: { fontWeight: 600 },
    h3: { fontWeight: 600 },
    h4: { fontWeight: 600 },
    h5: { fontWeight: 600 },
    h6: { fontWeight: 600 },
    button: { textTransform: 'none', fontWeight: 500 },
  },
  shape: { borderRadius: 12 },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          boxShadow: 'none',
          '&:hover': {
            boxShadow: '0 4px 14px 0 rgba(245, 158, 11, 0.39)',
          },
          transition: 'all 0.2s ease-in-out',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          backgroundColor: mode === 'dark' ? 'rgba(30, 41, 59, 0.7)' : 'rgba(255, 255, 255, 0.8)',
          backdropFilter: 'blur(10px)',
          border: mode === 'dark' ? '1px solid rgba(255, 255, 255, 0.05)' : '1px solid rgba(0, 0, 0, 0.05)',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { overflow: 'visible' },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          backgroundColor: mode === 'dark' ? '#1e293b' : '#ffffff',
          backgroundImage: 'none',
        }
      }
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: mode === 'dark' ? 'rgba(15, 23, 42, 0.8)' : 'rgba(255, 255, 255, 0.8)',
          color: mode === 'dark' ? '#f8fafc' : '#0f172a',
        }
      }
    }
  },
});

const theme = createTheme(getDesignTokens('light'));
export default theme;
