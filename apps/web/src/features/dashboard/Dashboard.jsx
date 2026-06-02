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
import { FleetStats } from './FleetStats';

const StatCard = ({ title, value, icon, trend, color, loading }) => {
  const theme = useTheme();
  const isDark = theme.palette.mode === 'dark';
  return (
    <Card sx={{ 
      height: '100%', 
      position: 'relative', 
      overflow: 'hidden',
      background: isDark
        ? `linear-gradient(135deg, rgba(30, 41, 59, 0.65) 0%, rgba(30, 41, 59, 0.45) 100%)`
        : `linear-gradient(135deg, rgba(255, 255, 255, 0.85) 0%, rgba(255, 255, 255, 0.7) 100%)`,
      backdropFilter: 'blur(16px)',
      transition: 'transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease',
      cursor: 'pointer',
      border: `1px solid ${isDark ? 'rgba(255, 255, 255, 0.06)' : 'rgba(0, 0, 0, 0.05)'}`,
      borderRadius: '16px',
      '&:hover': {
        transform: 'translateY(-5px)',
        boxShadow: isDark 
          ? `0 12px 24px -10px ${color}50, 0 4px 20px rgba(0,0,0,0.3)` 
          : `0 12px 20px -10px ${color}35, 0 4px 12px rgba(0,0,0,0.04)`,
        borderColor: `${color}60`,
      },
      '&::before': {
        content: '""',
        position: 'absolute',
        top: 0,
        right: 0,
        width: '120px',
        height: '120px',
        background: `radial-gradient(circle at top right, ${color}12, transparent 70%)`,
        zIndex: 0,
      }
    }}>
      {/* Icon watermark */}
      <Box sx={{ position: 'absolute', top: -10, right: -10, opacity: isDark ? 0.06 : 0.04, transform: 'scale(1.8)', zIndex: 0, color }}>
        {icon}
      </Box>
      <CardContent sx={{ p: 3, position: 'relative', zIndex: 1 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box>
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 1.2, mb: 1, fontSize: '0.75rem' }}>
              {title}
            </Typography>
            <Typography variant="h3" sx={{ fontWeight: 700, color: theme.palette.text.primary, tracking: '-0.5px' }}>
              {loading ? <CircularProgress size={24} sx={{ color }} /> : value}
            </Typography>
          </Box>
          <Box sx={{ 
            backgroundColor: isDark ? `${color}15` : `${color}10`, 
            borderRadius: '12px', 
            p: 1.5, 
            display: 'flex', 
            color: color,
            border: `1px solid ${color}20`,
            boxShadow: `0 4px 12px ${color}15`
          }}>
            {React.cloneElement(icon, { fontSize: 'medium' })}
          </Box>
        </Box>
        {trend && (() => {
          const isPositive = !trend.startsWith('-');
          const TrendIcon = isPositive ? TrendingUp : TrendingDown;
          const trendColor = isPositive ? theme.palette.success.main : theme.palette.error.main;
          return (
            <Box sx={{ display: 'flex', alignItems: 'center', mt: 2.5, color: trendColor }}>
              <Box sx={{ 
                display: 'flex', 
                alignItems: 'center', 
                backgroundColor: isPositive ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)', 
                borderRadius: '6px', 
                px: 0.8, 
                py: 0.3,
                mr: 1 
              }}>
                <TrendIcon fontSize="small" sx={{ mr: 0.5, fontSize: '0.9rem' }} />
                <Typography variant="caption" sx={{ fontWeight: 700 }}>{trend}</Typography>
              </Box>
              <Typography variant="caption" color="text.secondary">vs last week</Typography>
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
        <IconButton sx={{ color: '#E68D33', backgroundColor: 'rgba(230, 141, 51, 0.1)' }}>
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
          <StatCard title="Total Bookings" value={stats.totalPassengers} icon={<People />} trend={stats.bookingsTrend} color={'#E68D33'} loading={loading} />
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} sm={6} md={3}>
          <FleetStats />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <UserStats />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <RecentBookings />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <TodaySchedules />
        </Grid>
      </Grid>

      <Grid container spacing={3} sx={{ mt: 3 }}>
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
