import React, { useState, useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../../api/firebase';
import { useAuth } from '../../providers/AuthProvider';
import { useColorMode } from '../../providers/AppProviders';
import {
  Box,
  Drawer,
  AppBar,
  Toolbar,
  List,
  Typography,
  Divider,
  IconButton,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  useTheme,
  Avatar,
  Menu,
  MenuItem,
  Tooltip,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard,
  Route as RouteIcon,
  EventNote,
  DirectionsBus,
  People,
  Assessment,
  Notifications,
  Settings,
  Logout,
  EventSeat,
  Map,
  DarkMode,
  LightMode,
} from '@mui/icons-material';

const drawerWidth = 260;

const menuItems = [
  { text: 'Dashboard', icon: <Dashboard />, path: '/' },
  { text: 'Routes', icon: <RouteIcon />, path: '/routes' },
  { text: 'Schedules', icon: <EventNote />, path: '/schedules' },
  { text: 'Fleet', icon: <DirectionsBus />, path: '/fleet' },
  { text: 'Seat Management', icon: <EventSeat />, path: '/seats' },
  { text: 'Live Tracking', icon: <Map />, path: '/live' },
  { text: 'Users', icon: <People />, path: '/users' },
  { text: 'Analytics', icon: <Assessment />, path: '/analytics' },
  { text: 'Notifications', icon: <Notifications />, path: '/notifications' },
];

export const AdminLayout = () => {
  const theme = useTheme();
  const navigate = useNavigate();
  const location = useLocation();
  const { currentUser } = useAuth();
  const { toggleColorMode } = useColorMode();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);
  const [scrolled, setScrolled] = useState(false);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleMenuOpen = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = async () => {
    handleMenuClose();
    try {
      await signOut(auth);
      navigate('/login');
    } catch (error) {
      console.error('Logout error', error);
    }
  };

  const handleNavigate = (path) => {
    navigate(path);
    setMobileOpen(false);
  };

  useEffect(() => {
    const onScroll = () => {
      setScrolled(window.scrollY > 8);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  // Theme-aware colors so nav bars are visible in both light and dark modes
  const appBarBg = theme.palette.mode === 'dark'
    ? 'rgba(15, 23, 42, 0.5)'
    : 'rgba(255, 255, 255, 0.5)';

  const appBarBorder = theme.palette.mode === 'dark'
    ? '1px solid rgba(255, 255, 255, 0.08)'
    : '1px solid rgba(0, 0, 0, 0.06)';

  const appBarShadow = theme.palette.mode === 'dark'
    ? '0 8px 32px 0 rgba(2, 6, 23, 0.5)'
    : '0 8px 32px 0 rgba(31, 38, 135, 0.06)';

  const drawerBg = scrolled
    ? (theme.palette.mode === 'dark' ? 'rgba(15,23,42,0.72)' : 'rgba(255,255,255,0.96)')
    : (theme.palette.mode === 'dark' ? 'rgba(15,23,42,0.5)' : 'rgba(255,255,255,0.92)');

  const drawerShadow = theme.palette.mode === 'dark'
    ? '0 4px 20px rgba(0, 0, 0, 0.25)'
    : '0 4px 20px rgba(0, 0, 0, 0.04)';

  const navBorder = theme.palette.mode === 'dark' ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)';
  const navText = theme.palette.text.primary;

  const drawer = (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <Toolbar sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', py: 2 }}>
        <Typography variant="h5" component="div" sx={{ fontWeight: 'bold', color: '#E68D33', letterSpacing: 1, textTransform: 'uppercase' }}>
          RideSync
        </Typography>
      </Toolbar>
      <Divider sx={{ borderColor: 'rgba(255,255,255,0.06)' }} />
      <List sx={{ px: 2, pt: 2, flexGrow: 1 }}>
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path || (item.path !== '/' && location.pathname.startsWith(item.path));
          return (
            <ListItem key={item.text} disablePadding sx={{ mb: 1 }}>
              <ListItemButton
                onClick={() => handleNavigate(item.path)}
                sx={{
                  borderRadius: 2,
                  backgroundColor: isActive ? (theme.palette.mode === 'dark' ? 'rgba(230,141,51,0.12)' : 'rgba(230,141,51,0.08)') : 'transparent',
                  color: isActive ? '#E68D33' : navText,
                  '&:hover': {
                    backgroundColor: 'rgba(230,141,51,0.08)',
                    color: '#E68D33',
                  },
                  transition: 'all 0.2s',
                }}
              >
                <ListItemIcon sx={{ color: 'inherit', minWidth: 40 }}>
                  {item.icon}
                </ListItemIcon>
                <ListItemText 
                  primary={item.text} 
                  primaryTypographyProps={{ 
                    fontWeight: isActive ? 600 : 500,
                    fontSize: '0.95rem',
                    textTransform: 'uppercase'
                  }} 
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>
      <Divider sx={{ borderColor: 'rgba(255,255,255,0.05)' }} />
      <Box sx={{ p: 2 }}>
        <ListItem disablePadding>
          <ListItemButton onClick={() => handleNavigate('/settings')} sx={{ borderRadius: 2, color: '#000000' }}>
            <ListItemIcon sx={{ color: 'inherit', minWidth: 40 }}><Settings /></ListItemIcon>
            <ListItemText primary="Settings" primaryTypographyProps={{ fontSize: '0.95rem' }} />
          </ListItemButton>
        </ListItem>
      </Box>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', backgroundColor: theme.palette.background.default }}>
      <AppBar
        position="fixed"
        elevation={0}
        sx={{
          top: 16,
          width: { xs: `calc(100% - 32px)`, sm: `calc(100% - ${drawerWidth}px - 48px)` },
          ml: { xs: '16px', sm: `${drawerWidth + 32}px` },
          mr: { xs: '16px', sm: '16px' },
          backgroundColor: appBarBg,
          color: '#E68D33',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          border: appBarBorder,
          borderRadius: '999px',
          boxShadow: appBarShadow,
          zIndex: 1200,
          transition: 'background-color 0.3s, box-shadow 0.3s, border-color 0.3s',
        }}
      >
        <Toolbar sx={{ justifyContent: 'space-between' }}>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          
          <Typography variant="h6" noWrap component="div" sx={{ fontWeight: 700, color: 'inherit', display: { xs: 'none', sm: 'block' }, fontSize: '1.5rem', textTransform: 'uppercase' }}>
            {menuItems.find(m => m.path === location.pathname)?.text || 'Dashboard'}
          </Typography>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, ml: 'auto' }}>
            <Tooltip title={theme.palette.mode === 'dark' ? "Enable Light Mode" : "Enable Dark Mode"}>
              <IconButton onClick={toggleColorMode} color="inherit">
                {theme.palette.mode === 'dark' ? <LightMode /> : <DarkMode />}
              </IconButton>
            </Tooltip>
            <Tooltip title="Notifications">
              <IconButton color="inherit" onClick={() => handleNavigate('/notifications')}>
                <Notifications />
              </IconButton>
            </Tooltip>
            <Tooltip title={currentUser?.email || 'Admin Profile'}>
              <IconButton onClick={handleMenuOpen} sx={{ p: 0 }}>
                <Avatar sx={{ bgcolor: '#E68D33', color: '#fff', width: 36, height: 36 }}>
                  {currentUser?.email?.charAt(0).toUpperCase() || 'A'}
                </Avatar>
              </IconButton>
            </Tooltip>
            <Menu
              anchorEl={anchorEl}
              open={Boolean(anchorEl)}
              onClose={handleMenuClose}
              PaperProps={{
                sx: {
                  mt: 1.5,
                  minWidth: 180,
                  backgroundColor: theme.palette.background.paper,
                  border: '1px solid rgba(255,255,255,0.05)',
                  boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
                }
              }}
              transformOrigin={{ horizontal: 'right', vertical: 'top' }}
              anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
            >
              <MenuItem onClick={() => { handleMenuClose(); handleNavigate('/settings'); }}>
                <ListItemIcon><Settings fontSize="small" /></ListItemIcon>
                Settings
              </MenuItem>
              <Divider sx={{ my: 1, borderColor: 'rgba(255,255,255,0.05)' }} />
              <MenuItem onClick={handleLogout} sx={{ color: theme.palette.error.main }}>
                <ListItemIcon><Logout fontSize="small" sx={{ color: 'inherit' }} /></ListItemIcon>
                Logout
              </MenuItem>
            </Menu>
          </Box>
        </Toolbar>
      </AppBar>
      
      <Box component="nav" sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}>
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{
              display: { xs: 'block', sm: 'none' },
              '& .MuiDrawer-paper': {
                position: 'fixed',
                top: '16px',
                left: '16px',
                height: 'calc(100% - 32px)',
                boxSizing: 'border-box',
                width: drawerWidth,
                backgroundColor: drawerBg,
                color: navText,
                borderRight: `1px solid ${navBorder}`,
                backdropFilter: scrolled ? 'blur(12px)' : 'blur(6px)',
                WebkitBackdropFilter: scrolled ? 'blur(12px)' : 'blur(6px)',
                boxShadow: drawerShadow,
                borderRadius: '32px',
                overflow: 'hidden'
              },
            }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
              display: { xs: 'none', sm: 'block' },
              '& .MuiDrawer-paper': {
                position: 'fixed',
                top: '16px',
                left: '16px',
                height: 'calc(100% - 32px)',
                boxSizing: 'border-box',
                width: drawerWidth,
                backgroundColor: drawerBg,
                color: navText,
                borderRight: `1px solid ${navBorder}`,
                backdropFilter: scrolled ? 'blur(12px)' : 'blur(6px)',
                WebkitBackdropFilter: scrolled ? 'blur(12px)' : 'blur(6px)',
                boxShadow: drawerShadow,
                borderRadius: '32px',
                overflow: 'hidden'
              },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>
      
      <Box 
        component="main" 
        sx={{ 
          flexGrow: 1, 
          p: 3, 
          width: { sm: `calc(100% - ${drawerWidth}px - 24px)` }, 
          ml: { sm: '24px' },
          mt: 10 
        }}
      >
        <Outlet />
      </Box>
    </Box>
  );
};
