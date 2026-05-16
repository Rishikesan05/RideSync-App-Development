import { useMutation } from '@tanstack/react-query';
import axios from './axios';

export const broadcastToRoute = async (data) => {
  const response = await axios.post('/notify/broadcast', data);
  return response.data;
};

export const sendToUser = async (data) => {
  const response = await axios.post('/notify/user', data);
  return response.data;
};

export const useBroadcastNotification = () => {
  return useMutation({
    mutationFn: broadcastToRoute,
  });
};

export const useSendUserNotification = () => {
  return useMutation({
    mutationFn: sendToUser,
  });
};
