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
import { motion } from 'framer-motion';

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
      height: '180px', 
      width: '100%',
      display: 'flex',
      flexDirection: 'column',
      position: 'relative', 
      overflow: 'visible', // Allow cutouts to bleed off edges
      background: isDark
        ? `linear-gradient(135deg, rgba(30, 41, 59, 0.75) 0%, rgba(15, 23, 42, 0.8) 100%)`
        : `linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(248, 250, 252, 0.9) 100%)`,
      backdropFilter: 'blur(20px)',
      transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      cursor: 'pointer',
      border: `1.5px solid ${color}40`,
      borderTop: `4px solid ${color}`,
      borderRadius: '16px',
      boxShadow: isDark 
        ? '0 4px 20px -2px rgba(0, 0, 0, 0.3)' 
        : '0 4px 20px -2px rgba(0, 0, 0, 0.03)',
      '&:hover': {
        transform: 'translateY(-6px)',
        boxShadow: isDark 
          ? `0 16px 28px -10px ${color}40, 0 8px 30px rgba(0,0,0,0.4)` 
          : `0 16px 24px -10px ${color}30, 0 6px 20px rgba(0,0,0,0.06)`,
        borderColor: color,
        '& .ticket-notch': {
          borderColor: color,
        }
      },
    }}>
      {/* Left Ticket Notch */}
      <Box 
        className="ticket-notch"
        sx={{
          position: 'absolute',
          left: '-10px',
          top: '50%',
          transform: 'translateY(-50%)',
          width: '20px',
          height: '20px',
          borderRadius: '50%',
          backgroundColor: theme.palette.background.default,
          border: `1.5px solid ${color}40`,
          borderLeftColor: 'transparent',
          borderTopColor: 'transparent',
          borderBottomColor: 'transparent',
          zIndex: 2,
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        }} 
      />
      
      {/* Right Ticket Notch */}
      <Box 
        className="ticket-notch"
        sx={{
          position: 'absolute',
          right: '-10px',
          top: '50%',
          transform: 'translateY(-50%)',
          width: '20px',
          height: '20px',
          borderRadius: '50%',
          backgroundColor: theme.palette.background.default,
          border: `1.5px solid ${color}40`,
          borderRightColor: 'transparent',
          borderTopColor: 'transparent',
          borderBottomColor: 'transparent',
          zIndex: 2,
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        }} 
      />

      <CardContent sx={{ 
        p: 0, 
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        position: 'relative',
        zIndex: 1,
      }}>
        {/* Upper portion */}
        <Box sx={{ 
          p: 2.5, 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'space-between', 
          height: '50%',
          boxSizing: 'border-box',
          gap: 2
        }}>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1.2, fontSize: '0.85rem' }}>
              {title}
            </Typography>
          </Box>
          <Box sx={{ 
            backgroundColor: 'transparent', 
            borderRadius: '50%', 
            p: 1.2, 
            display: 'flex', 
            color: color,
            border: 'none',
            boxShadow: 'none'
          }}>
            {React.cloneElement(icon, { fontSize: 'large' })}
          </Box>
        </Box>

        {/* Perforation dashed line */}
        <Box sx={{
          width: '100%',
          borderTop: `1px dashed ${isDark ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.1)'}`,
          height: 0,
        }} />

        {/* Lower portion */}
        <Box sx={{ 
          p: 2.5, 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'space-between', 
          height: '50%',
          boxSizing: 'border-box',
          gap: 2
        }}>
          <Typography variant="h4" sx={{ fontWeight: 800, color: theme.palette.text.primary, letterSpacing: '-0.5px' }}>
            {loading ? <CircularProgress size={24} sx={{ color }} /> : value}
          </Typography>
          {trend ? (() => {
            const isPositive = !trend.startsWith('-');
            const TrendIcon = isPositive ? TrendingUp : TrendingDown;
            const trendColor = isPositive ? '#10B981' : '#EF4444';
            const bgOpacity = isPositive ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)';
            return (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Box sx={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  backgroundColor: bgOpacity, 
                  borderRadius: '8px', 
                  px: 0.8, 
                  py: 0.2,
                  border: `1px solid ${isPositive ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)'}`
                }}>
                  <TrendIcon fontSize="small" sx={{ mr: 0.3, fontSize: '0.9rem', color: trendColor }} />
                  <Typography variant="caption" sx={{ fontWeight: 800, fontSize: '0.7rem', color: trendColor }}>{trend}</Typography>
                </Box>
                <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 500, display: { xs: 'none', sm: 'block' } }}>vs last week</Typography>
              </Box>
            );
          })() : null}
        </Box>
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

        setRevenueData(last7Days);
        
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  // Motion stagger animation variants
  const containerVariants = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.08
      }
    }
  };

  const cardVariants = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 100, damping: 15 } }
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 700, mb: 1 }}>Overview</Typography>
          <Typography variant="body1" color="text.secondary">Welcome back to the RideSync Admin Dashboard.</Typography>
        </Box>

      </Box>

      {/* Row 1: Stat Cards (Modern Designs with Brand Color & Spring Animations) */}
      <Grid 
        container 
        spacing={3} 
        sx={{ mb: 4 }}
        component={motion.div}
        variants={containerVariants}
        initial="hidden"
        animate="show"
      >
        <Grid item xs={12} sm={6} lg={3} component={motion.div} variants={cardVariants}>
          <StatCard title="Total Revenue" value={`LKR ${(stats.totalRevenue / 1000).toFixed(1)}K`} icon={<TrendingUp />} trend={stats.revenueTrend} color={'#E68D33'} loading={loading} />
        </Grid>
        <Grid item xs={12} sm={6} lg={3} component={motion.div} variants={cardVariants}>
          <StatCard title="Active Buses" value={stats.activeBuses} icon={<DirectionsBus />} color={'#E68D33'} loading={loading} />
        </Grid>
        <Grid item xs={12} sm={6} lg={3} component={motion.div} variants={cardVariants}>
          <StatCard title="Schedules Today" value={stats.schedulesToday} icon={<EventNote />} color={'#E68D33'} loading={loading} />
        </Grid>
        <Grid item xs={12} sm={6} lg={3} component={motion.div} variants={cardVariants}>
          <StatCard title="Total Bookings" value={stats.totalPassengers} icon={<People />} trend={stats.bookingsTrend} color={'#E68D33'} loading={loading} />
        </Grid>
      </Grid>

      {/* Row 2: Detailed Overview Cards (Optimized layout making Fleet Overview wider) */}
      <Grid container spacing={3}>
        <Grid item xs={12} sm={6} lg={4}>
          <FleetStats />
        </Grid>
        <Grid item xs={12} sm={6} lg={2}>
          <UserStats />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <RecentBookings />
        </Grid>
        <Grid item xs={12} sm={6} lg={3}>
          <TodaySchedules />
        </Grid>
      </Grid>

      <Grid container spacing={3} sx={{ mt: 3 }}>
        <Grid item xs={12}>
          <Card sx={{ height: 500, display: 'flex', flexDirection: 'column' }}>
            <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', p: 3 }}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Revenue Trend</Typography>
              <Box sx={{ flexGrow: 1, minHeight: 0, width: '100%' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={revenueData} margin={{ top: 10, right: 10, left: 0, bottom: 20 }}>
                    <defs>
                      <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor={'#E68D33'} stopOpacity={0.4}/>
                        <stop offset="95%" stopColor={'#E68D33'} stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(128,128,128,0.2)" vertical={false} />
                    <XAxis dataKey="name" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} dy={10} interval={0} />
                    <YAxis stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} dx={-10} width={80} />
                    <Tooltip 
                       contentStyle={{ backgroundColor: theme.palette.background.paper, border: 'none', borderRadius: 8, boxShadow: '0 4px 20px rgba(0,0,0,0.15)' }}
                      itemStyle={{ color: '#E68D33', fontWeight: 600 }}
                    />
                    <Area type="monotone" dataKey="revenue" stroke={'#E68D33'} strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
                  </AreaChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12}>
          <Card sx={{ height: 500, display: 'flex', flexDirection: 'column' }}>
            <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', p: 3 }}>
              <Typography variant="h6" sx={{ fontWeight: 600, mb: 3 }}>Bookings by Class</Typography>
              <Box sx={{ flexGrow: 1, minHeight: 0, width: '100%' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={bookingsData} margin={{ top: 10, right: 10, left: 0, bottom: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(128,128,128,0.2)" vertical={false} />
                    <XAxis dataKey="name" stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} dy={10} interval={0} />
                    <YAxis stroke={theme.palette.text.secondary} tick={{fill: theme.palette.text.secondary}} axisLine={false} tickLine={false} dx={-10} width={80} />
                    <Tooltip 
                      cursor={{fill: 'rgba(128,128,128,0.1)'}}
                      contentStyle={{ backgroundColor: theme.palette.background.paper, border: 'none', borderRadius: 8, boxShadow: '0 4px 20px rgba(0,0,0,0.15)' }}
                      itemStyle={{ color: '#E68D33', fontWeight: 600 }}
                    />
                    <Bar dataKey="count" fill={'#E68D33'} radius={[6, 6, 0, 0]} maxBarSize={80} />
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
