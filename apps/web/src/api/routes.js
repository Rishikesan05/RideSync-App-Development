import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from './axios';

export const fetchRoutes = async () => {
  const response = await axios.get('/routes');
  return response.data; // Assumes backend returns { success: true, data: [...] }
};

export const createRoute = async (routeData) => {
  const response = await axios.post('/routes', routeData);
  return response.data;
};

export const updateRoute = async ({ id, data }) => {
  const response = await axios.put(`/routes/${id}`, data);
  return response.data;
};

export const deactivateRoute = async (id) => {
  const response = await axios.delete(`/routes/${id}`);
  return response.data;
};

export const useRoutesList = () => {
  return useQuery({
    queryKey: ['routes'],
    queryFn: fetchRoutes,
  });
};

export const useCreateRoute = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createRoute,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['routes'] });
    },
  });
};

export const useUpdateRoute = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: updateRoute,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['routes'] });
    },
  });
};

export const useDeactivateRoute = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: deactivateRoute,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['routes'] });
    },
  });
};
