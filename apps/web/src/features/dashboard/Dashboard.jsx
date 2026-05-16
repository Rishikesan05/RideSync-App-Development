import React from 'react';
import { Box, Grid, Card, CardContent, Typography, useTheme, IconButton } from '@mui/material';
import { TrendingUp, DirectionsBus, EventNote, People, Assessment } from '@mui/icons-material';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar
} from 'recharts';

const revenueData = [
  { name: 'Mon', revenue: 4000 },
  { name: 'Tue', revenue: 3000 },
  { name: 'Wed', revenue: 2000 },
  { name: 'Thu', revenue: 2780 },
  { name: 'Fri', revenue: 1890 },
  { name: 'Sat', revenue: 2390 },
  { name: 'Sun', revenue: 3490 },
];

const bookingsData = [
  { name: 'AC', count: 400 },
  { name: 'Non-AC', count: 300 },
];

const StatCard = ({ title, value, icon, trend, color }) => {
  const theme = useTheme();
  return (
    <Card sx={{ height: '100%', position: 'relative', overflow: 'hidden' }}>
      <Box sx={{ position: 'absolute', top: -20, right: -20, opacity: 0.1, transform: 'scale(2)' }}>
        {icon}
      </Box>
      <CardContent sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box>
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1, mb: 1 }}>
              {title}
            </Typography>
            <Typography variant="h3" sx={{ fontWeight: 700, color: theme.palette.text.primary }}>
              {value}
            </Typography>
          </Box>
          <Box sx={{ 
            backgroundColor: `${color}20`, 
            borderRadius: '50%', 
            p: 1.5, 
            display: 'flex', 
            color: color 
          }}>
            {React.cloneElement(icon, { fontSize: 'medium' })}
          </Box>
        </Box>
        {trend && (
          <Box sx={{ display: 'flex', alignItems: 'center', mt: 2, color: theme.palette.success.main }}>
            <TrendingUp fontSize="small" sx={{ mr: 0.5 }} />
            <Typography variant="body2" sx={{ fontWeight: 600 }}>{trend}</Typography>
            <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>vs last week</Typography>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export const Dashboard = () => {
  const theme = useTheme();

  return (
    <Box sx={{ flexGrow: 1 }}>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, mb: 1 }}>Overview</Typography>
          <Typography variant="body1" color="text.secondary">Welcome back to the RideSync Admin Dashboard.</Typography>
        </Box>
        <IconButton color="primary" sx={{ backgroundColor: 'rgba(99, 102, 241, 0.1)' }}>
          <Assessment />
        </IconButton>
      </Box>

      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Total Revenue" value="LKR 45.2K" icon={<TrendingUp />} trend="+12.5%" color={theme.palette.success.main} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Active Buses" value="24" icon={<DirectionsBus />} color={theme.palette.info.main} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Schedules Today" value="18" icon={<EventNote />} color={theme.palette.warning.main} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Passengers" value="1,204" icon={<People />} trend="+5.2%" color={theme.palette.primary.main} />
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} lg={8}>
          <Card sx={{ height: 400, display: 'flex', flexDirection: 'column' }}>
            <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Revenue Trend</Typography>
              <Box sx={{ flexGrow: 1, minHeight: 0 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={revenueData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                    <defs>
                      <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor={theme.palette.primary.main} stopOpacity={0.4}/>
                        <stop offset="95%" stopColor={theme.palette.primary.main} stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                    <XAxis dataKey="name" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} />
                    <YAxis stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} />
                    <Tooltip 
                      contentStyle={{ backgroundColor: theme.palette.background.paper, border: 'none', borderRadius: 8, boxShadow: '0 4px 20px rgba(0,0,0,0.5)' }}
                      itemStyle={{ color: theme.palette.primary.light }}
                    />
                    <Area type="monotone" dataKey="revenue" stroke={theme.palette.primary.main} strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
                  </AreaChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} lg={4}>
          <Card sx={{ height: 400, display: 'flex', flexDirection: 'column' }}>
            <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Bookings by Class</Typography>
              <Box sx={{ flexGrow: 1, minHeight: 0 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={bookingsData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                    <XAxis dataKey="name" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} />
                    <Tooltip 
                      cursor={{fill: 'rgba(255,255,255,0.05)'}}
                      contentStyle={{ backgroundColor: theme.palette.background.paper, border: 'none', borderRadius: 8 }}
                    />
                    <Bar dataKey="count" fill={theme.palette.secondary.main} radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};
