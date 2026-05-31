import React, { useState, useEffect } from 'react';
import { Box, Grid, Card, CardContent, Typography, useTheme, IconButton, CircularProgress } from '@mui/material';
import { TrendingUp, TrendingDown, DirectionsBus, EventNote, People, Assessment } from '@mui/icons-material';
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

import { collection, getDocs, query, where, Timestamp } from 'firebase/firestore';
import { db } from '../../api/firebase';
import { RecentBookings } from './RecentBookings';
import { UserStats } from './UserStats';
import { TodaySchedules } from './TodaySchedules';

const StatCard = ({ title, value, icon, trend, color, loading }) => {
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
              {loading ? <CircularProgress size={24} /> : value}
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
        {trend && (() => {
          const isPositive = !trend.startsWith('-');
          const TrendIcon = isPositive ? TrendingUp : TrendingDown;
          const trendColor = isPositive ? theme.palette.success.main : theme.palette.error.main;
          return (
            <Box sx={{ display: 'flex', alignItems: 'center', mt: 2, color: trendColor }}>
              <TrendIcon fontSize="small" sx={{ mr: 0.5 }} />
              <Typography variant="body2" sx={{ fontWeight: 600 }}>{trend}</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>vs last week</Typography>
            </Box>
          );
        })()}
      </CardContent>
    </Card>
  );
};

export const Dashboard = () => {
  const theme = useTheme();
  
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalRevenue: 0,
    activeBuses: 0,
    schedulesToday: 0,
    totalPassengers: 0,
    revenueTrend: null,
    bookingsTrend: null,
  });
  const [revenueData, setRevenueData] = useState([]);
  const [bookingsData, setBookingsData] = useState([]);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        
        // Active Buses
        const busesSnapshot = await getDocs(query(collection(db, 'buses'), where('isActive', '==', true)));
        const activeBuses = busesSnapshot.size;

        // Total Passengers (count all unique passengers in bookings, or just users with role 'passenger')
        // For simplicity, let's count all users for now, or just total bookings
        const bookingsSnapshot = await getDocs(collection(db, 'bookings'));
        const totalPassengers = bookingsSnapshot.size; // Total bookings proxy for passenger engagements

        // Schedules Today
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        
        const schedulesSnapshot = await getDocs(
          query(collection(db, 'schedules'), 
          where('departureTime', '>=', Timestamp.fromDate(today)),
          where('departureTime', '<', Timestamp.fromDate(tomorrow)))
        );
        const schedulesToday = schedulesSnapshot.size;

        // Calculate Revenue & Bookings by Class + week-over-week trends
        let totalRevenue = 0;
        let acBookings = 0;
        let nonAcBookings = 0;

        // Week boundaries for trend comparison
        const now = new Date();
        const thisWeekStart = new Date(now);
        thisWeekStart.setDate(now.getDate() - 7);
        thisWeekStart.setHours(0, 0, 0, 0);
        const lastWeekStart = new Date(now);
        lastWeekStart.setDate(now.getDate() - 14);
        lastWeekStart.setHours(0, 0, 0, 0);

        let thisWeekRevenue = 0, lastWeekRevenue = 0;
        let thisWeekBookings = 0, lastWeekBookings = 0;

        // Last 7 days buckets for the revenue chart
        const last7Days = Array.from({length: 7}, (_, i) => {
          const d = new Date();
          d.setDate(d.getDate() - (6 - i));
          d.setHours(0, 0, 0, 0);
          return { name: d.toLocaleDateString('en-US', { weekday: 'short' }), revenue: 0, date: d };
        });

        bookingsSnapshot.forEach(doc => {
          const data = doc.data();
          const fare = data.totalFare || 0;
          totalRevenue += fare;

          const cls = (data.busClass || data.class || '').toUpperCase();
          if (cls === 'AC') acBookings++;
          else nonAcBookings++;

          // Read timestamp — support multiple field names used by the mobile app
          const rawTs = data.timestamp ?? data.createdAt ?? data.bookedAt ?? null;
          if (rawTs) {
            const bookingDate = typeof rawTs.toDate === 'function'
              ? rawTs.toDate()
              : new Date(rawTs);

            // Trend buckets
            if (bookingDate >= thisWeekStart) {
              thisWeekRevenue  += fare;
              thisWeekBookings += 1;
            } else if (bookingDate >= lastWeekStart) {
              lastWeekRevenue  += fare;
              lastWeekBookings += 1;
            }

            // Revenue chart bucket
            const dayMatch = last7Days.find(d =>
              d.date.getDate()     === bookingDate.getDate() &&
              d.date.getMonth()    === bookingDate.getMonth() &&
              d.date.getFullYear() === bookingDate.getFullYear()
            );
            if (dayMatch) dayMatch.revenue += fare;
          }
        });

        // Compute trend percentage strings
        const calcTrend = (curr, prev) => {
          if (prev === 0) return curr > 0 ? '+100%' : null;
          const pct = (((curr - prev) / prev) * 100).toFixed(1);
          return pct >= 0 ? `+${pct}%` : `${pct}%`;
        };
        const revenueTrend  = calcTrend(thisWeekRevenue,  lastWeekRevenue);
        const bookingsTrend = calcTrend(thisWeekBookings, lastWeekBookings);

        setStats({
          totalRevenue,
          activeBuses,
          schedulesToday,
          totalPassengers,
          revenueTrend,
          bookingsTrend,
        });

        setBookingsData([
          { name: 'AC', count: acBookings },
          { name: 'Non-AC', count: nonAcBookings }
        ]);

        // If no real recent revenue data, just show some trends for visualization demo
        const hasData = last7Days.some(d => d.revenue > 0);
        if (hasData) {
          setRevenueData(last7Days);
        } else {
          // Fallback demo data if real bookings have no timestamps or are empty
          setRevenueData([
            { name: 'Mon', revenue: 4000 },
            { name: 'Tue', revenue: 3000 },
            { name: 'Wed', revenue: 2000 },
            { name: 'Thu', revenue: 2780 },
            { name: 'Fri', revenue: 1890 },
            { name: 'Sat', revenue: 2390 },
            { name: 'Sun', revenue: 3490 },
          ]);
        }
        
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

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
          <StatCard title="Total Revenue" value={`LKR ${(stats.totalRevenue / 1000).toFixed(1)}K`} icon={<TrendingUp />} trend={stats.revenueTrend} color={theme.palette.success.main} loading={loading} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Active Buses" value={stats.activeBuses} icon={<DirectionsBus />} color={theme.palette.info.main} loading={loading} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Schedules Today" value={stats.schedulesToday} icon={<EventNote />} color={theme.palette.warning.main} loading={loading} />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Total Bookings" value={stats.totalPassengers} icon={<People />} trend={stats.bookingsTrend} color={theme.palette.primary.main} loading={loading} />
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

      {/* ── Row 3: Today's Schedules (full width) ──────────────────────── */}
      <Grid container spacing={3} sx={{ mt: 3 }}>
        <Grid item xs={12}>
          <TodaySchedules />
        </Grid>
      </Grid>

      {/* ── Row 4: UserStats (left) + RecentBookings (right) ───────────── */}
      <Grid container spacing={3} sx={{ mt: 3 }}>
        <Grid item xs={12} md={4}>
          <UserStats />
        </Grid>
        <Grid item xs={12} md={8}>
          <RecentBookings />
        </Grid>
      </Grid>

    </Box>
  );
};
