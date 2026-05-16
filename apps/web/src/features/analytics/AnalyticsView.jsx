import React from 'react';
import { 
  Typography, 
  Card, 
  CardContent, 
  Box, 
  Grid,
  useTheme
} from '@mui/material';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  Legend
} from 'recharts';

// Mock data for analytics
const revenueData = [
  { name: 'Jan', revenue: 40000, bookings: 240 },
  { name: 'Feb', revenue: 30000, bookings: 139 },
  { name: 'Mar', revenue: 20000, bookings: 980 },
  { name: 'Apr', revenue: 27800, bookings: 390 },
  { name: 'May', revenue: 18900, bookings: 480 },
  { name: 'Jun', revenue: 23900, bookings: 380 },
  { name: 'Jul', revenue: 34900, bookings: 430 },
];

const routePopularityData = [
  { name: 'Colombo - Kandy', value: 400 },
  { name: 'Colombo - Galle', value: 300 },
  { name: 'Kandy - Nuwara Eliya', value: 300 },
  { name: 'Colombo - Jaffna', value: 200 },
];

const timeOfDayData = [
  { name: 'Morning (6A-12P)', count: 450 },
  { name: 'Afternoon (12P-6P)', count: 320 },
  { name: 'Evening (6P-12A)', count: 280 },
  { name: 'Night (12A-6A)', count: 90 },
];

const COLORS = ['#6366f1', '#ec4899', '#10b981', '#f59e0b'];

export const AnalyticsView = () => {
  const theme = useTheme();

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Analytics & Reports</Typography>
      </Box>

      <Grid container spacing={3}>
        {/* Revenue & Bookings Over Time */}
        <Grid item xs={12}>
          <Card sx={{ height: 400 }}>
            <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Revenue & Booking Volume (YTD)</Typography>
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
                    <YAxis yAxisId="left" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} />
                    <YAxis yAxisId="right" orientation="right" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} />
                    <RechartsTooltip 
                      contentStyle={{ backgroundColor: theme.palette.background.paper, border: 'none', borderRadius: 8, boxShadow: '0 4px 20px rgba(0,0,0,0.5)' }}
                      itemStyle={{ color: theme.palette.primary.light }}
                    />
                    <Legend />
                    <Area yAxisId="left" type="monotone" dataKey="revenue" name="Revenue (LKR)" stroke={theme.palette.primary.main} strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
                    <Line yAxisId="right" type="monotone" dataKey="bookings" name="Total Bookings" stroke={theme.palette.secondary.main} strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }} />
                  </AreaChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Route Popularity */}
        <Grid item xs={12} md={6}>
          <Card sx={{ height: 400 }}>
            <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Route Popularity</Typography>
              <Box sx={{ flexGrow: 1, minHeight: 0, display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={routePopularityData}
                      cx="50%"
                      cy="50%"
                      innerRadius={80}
                      outerRadius={120}
                      paddingAngle={5}
                      dataKey="value"
                      stroke="none"
                    >
                      {routePopularityData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <RechartsTooltip 
                      contentStyle={{ backgroundColor: theme.palette.background.paper, border: 'none', borderRadius: 8 }}
                      itemStyle={{ color: theme.palette.text.primary }}
                    />
                    <Legend verticalAlign="bottom" height={36}/>
                  </PieChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Booking Time Distribution */}
        <Grid item xs={12} md={6}>
          <Card sx={{ height: 400 }}>
            <CardContent sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Bookings by Time of Day</Typography>
              <Box sx={{ flexGrow: 1, minHeight: 0 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={timeOfDayData} layout="vertical" margin={{ top: 10, right: 30, left: 40, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" horizontal={false} />
                    <XAxis type="number" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} />
                    <YAxis dataKey="name" type="category" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} />
                    <RechartsTooltip 
                      cursor={{fill: 'rgba(255,255,255,0.05)'}}
                      contentStyle={{ backgroundColor: theme.palette.background.paper, border: 'none', borderRadius: 8 }}
                    />
                    <Bar dataKey="count" name="Bookings" fill={theme.palette.info.main} radius={[0, 4, 4, 0]} barSize={30} />
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
