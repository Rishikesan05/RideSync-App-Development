import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from './axios';

export const fetchBuses = async () => {
  const response = await axios.get('/buses');
  return response.data;
};

export const createBus = async (busData) => {
  const response = await axios.post('/buses', busData);
  return response.data;
};

export const updateBus = async ({ id, data }) => {
  const response = await axios.put(`/buses/${id}`, data);
  return response.data;
};

export const deactivateBus = async (id) => {
  const response = await axios.delete(`/buses/${id}`);
  return response.data;
};

export const useBusesList = () => {
  return useQuery({
    queryKey: ['buses'],
    queryFn: fetchBuses,
  });
};

export const useCreateBus = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createBus,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['buses'] });
    },
  });
};

export const useUpdateBus = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: updateBus,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['buses'] });
    },
  });
};

export const useDeactivateBus = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: deactivateBus,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['buses'] });
    },
  });
};
