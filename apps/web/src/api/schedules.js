import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from './axios';

export const fetchSchedules = async () => {
  const response = await axios.get('/schedules');
  return response.data;
};

export const createSchedule = async (scheduleData) => {
  const response = await axios.post('/schedules', scheduleData);
  return response.data;
};

export const updateSchedule = async ({ id, data }) => {
  const response = await axios.put(`/schedules/${id}`, data);
  return response.data;
};

export const cancelSchedule = async (id) => {
  const response = await axios.delete(`/schedules/${id}`);
  return response.data;
};

export const useSchedulesList = () => {
  return useQuery({
    queryKey: ['schedules'],
    queryFn: fetchSchedules,
  });
};

export const useCreateSchedule = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createSchedule,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schedules'] });
    },
  });
};

export const useUpdateSchedule = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: updateSchedule,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schedules'] });
    },
  });
};

export const useCancelSchedule = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: cancelSchedule,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['schedules'] });
    },
  });
};
