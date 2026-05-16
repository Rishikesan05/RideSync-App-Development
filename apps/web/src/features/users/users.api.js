import axiosInstance from '../../api/axios';

export const usersApi = {
  getUsers: async (role) => {
    const params = role ? { role } : {};
    const response = await axiosInstance.get('/users', { params });
    return response.data.data;
  },
  
  approveOperator: async (uid) => {
    const response = await axiosInstance.put(`/users/${uid}/approve`);
    return response.data;
  },
  
  rejectOperator: async (uid) => {
    const response = await axiosInstance.put(`/users/${uid}/reject`);
    return response.data;
  }
};
