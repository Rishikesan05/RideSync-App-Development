import React, { useState } from 'react';
import { 
  Typography, 
  Card, 
  Box, 
  Chip,
  IconButton,
  Menu,
  MenuItem,
  ListItemIcon,
  Avatar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  useTheme,
  CircularProgress,
  Alert,
  Button
} from '@mui/material';
import { 
  MoreVert, 
  Security, 
  AdminPanelSettings,
  Person,
  CheckCircle,
  Cancel
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { doc, setDoc } from 'firebase/firestore';
import { db } from '../../api/firebase';
import { usersApi } from './users.api';

export const UsersView = () => {
  const theme = useTheme();
  const queryClient = useQueryClient();
  const [seeding, setSeeding] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);
  const [menuUserId, setMenuUserId] = useState(null);
  const [menuUserRole, setMenuUserRole] = useState(null);

  const handleSeedOperator = async () => {
    setSeeding(true);
    try {
      await setDoc(doc(db, "users", "OP_TEST_KAMAL_001"), {
        name: "Kamal Perera",
        role: "operator",
        email: "kamal@ridesync.lk",
        phone: "+94771234567",
        isApproved: true,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      alert("Sample operator 'OP_TEST_KAMAL_001' created successfully!");
      queryClient.invalidateQueries(['users']);
    } catch (err) {
      console.error("Seed error:", err);
      alert("Failed to seed: " + err.message);
    } finally {
      setSeeding(false);
    }
  };

  const { data: users, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => usersApi.getUsers()
  });

  const approveMutation = useMutation({
    mutationFn: (uid) => usersApi.approveOperator(uid),
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      handleCloseMenu();
    }
  });

  const rejectMutation = useMutation({
    mutationFn: (uid) => usersApi.rejectOperator(uid),
    onSuccess: () => {
      queryClient.invalidateQueries(['users']);
      handleCloseMenu();
    }
  });

  const handleOpenMenu = (event, user) => {
    setAnchorEl(event.currentTarget);
    setMenuUserId(user.id);
    setMenuUserRole(user.role);
  };

  const handleCloseMenu = () => {
    setAnchorEl(null);
    setMenuUserId(null);
    setMenuUserRole(null);
  };

  const getRoleIcon = (role) => {
    switch(role) {
      case 'admin': return <AdminPanelSettings fontSize="small" />;
      case 'operator': return <Security fontSize="small" />;
      case 'operator_pending': return <Security fontSize="small" />;
      default: return <Person fontSize="small" />;
    }
  };

  const getRoleColor = (role) => {
    switch(role) {
      case 'admin': return 'error';
      case 'operator': return 'success';
      case 'operator_pending': return 'warning';
      default: return 'default';
    }
  };

  const formatRole = (role) => {
    if (role === 'operator_pending') return 'PENDING OPERATOR';
    return role.toUpperCase();
  };

  if (isLoading) return <CircularProgress />;
  if (error) return <Alert severity="error">{error.message}</Alert>;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700 }}>Users Management</Typography>
        <Button 
          variant="contained" 
          color="secondary" 
          onClick={handleSeedOperator}
          disabled={seeding}
        >
          {seeding ? 'Seeding...' : 'Seed Sample Operator'}
        </Button>
      </Box>

      <Card sx={{ boxShadow: '0 4px 20px rgba(0,0,0,0.05)' }}>
        <TableContainer>
          <Table sx={{ minWidth: 650 }}>
            <TableHead sx={{ backgroundColor: 'rgba(0,0,0,0.02)' }}>
              <TableRow>
                <TableCell>User</TableCell>
                <TableCell>Role</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Assigned Bus</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {users?.map((user) => (
                <TableRow key={user.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                  <TableCell component="th" scope="row">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                      <Avatar sx={{ bgcolor: theme.palette.primary.main, width: 32, height: 32 }}>
                        {user.name ? user.name.charAt(0).toUpperCase() : '?'}
                      </Avatar>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>{user.name || 'Unknown'}</Typography>
                        <Typography variant="caption" color="text.secondary">{user.email}</Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Chip 
                      icon={getRoleIcon(user.role)} 
                      label={formatRole(user.role)} 
                      color={getRoleColor(user.role)}
                      size="small"
                      variant="outlined"
                      sx={{ pl: 0.5 }}
                    />
                  </TableCell>
                  <TableCell>
                    <Chip 
                      label={user.role === 'operator_pending' ? 'Review Required' : 'Active'} 
                      color={user.role === 'operator_pending' ? 'warning' : 'success'}
                      size="small"
                      variant="filled"
                      sx={{ height: 20, fontSize: '0.7rem' }}
                    />
                  </TableCell>
                  <TableCell>
                    {user.busId ? (
                      <Typography variant="body2" color="text.secondary">{user.busId}</Typography>
                    ) : (
                      <Typography variant="caption" color="text.disabled">-</Typography>
                    )}
                  </TableCell>
                  <TableCell align="right">
                    <IconButton onClick={(e) => handleOpenMenu(e, user)} size="small">
                      <MoreVert />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleCloseMenu}
      >
        {menuUserRole === 'operator_pending' ? [
          <MenuItem key="approve" onClick={() => approveMutation.mutate(menuUserId)}>
            <ListItemIcon><CheckCircle fontSize="small" color="success" /></ListItemIcon>
            Approve Operator
          </MenuItem>,
          <MenuItem key="reject" onClick={() => rejectMutation.mutate(menuUserId)}>
            <ListItemIcon><Cancel fontSize="small" color="error" /></ListItemIcon>
            Reject Application
          </MenuItem>
        ] : [
          <MenuItem key="set-operator" onClick={handleCloseMenu}>
            <ListItemIcon><Security fontSize="small" /></ListItemIcon>
            Set as Operator
          </MenuItem>,
          <MenuItem key="set-admin" onClick={handleCloseMenu}>
            <ListItemIcon><AdminPanelSettings fontSize="small" /></ListItemIcon>
            Set as Admin
          </MenuItem>
        ]}
      </Menu>
    </Box>
  );
};
