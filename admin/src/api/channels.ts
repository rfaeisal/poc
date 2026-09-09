import { api } from './client';
import { Channel, ChannelMember } from '@/types/channel';

export async function getChannels(): Promise<{ channels: Channel[] }> {
  const { data } = await api.get('/channels');
  return data;
}

export async function getChannel(id: string): Promise<{ channel: Channel }> {
  const { data } = await api.get(`/channels/${id}`);
  return data;
}

export async function createChannel(body: {
  name: string;
  description?: string;
  isPrivate: boolean;
  password?: string;
  maxMembers?: number;
}): Promise<{ channel: Channel }> {
  const { data } = await api.post('/channels', body);
  return data;
}

export async function updateChannel(id: string, body: {
  name?: string;
  description?: string;
  maxMembers?: number;
  isActive?: boolean;
  isPrivate?: boolean;
}): Promise<{ channel: Channel }> {
  const { data } = await api.patch(`/admin/channels/${id}`, body);
  return data;
}

export async function deleteChannel(id: string): Promise<void> {
  await api.delete(`/admin/channels/${id}`);
}

export async function getChannelMembers(id: string): Promise<{ members: ChannelMember[] }> {
  const { data } = await api.get(`/channels/${id}/members`);
  return data;
}

export async function kickMember(channelId: string, userId: string): Promise<void> {
  await api.post(`/channels/${channelId}/members/${userId}/kick`);
}

export async function muteMember(channelId: string, userId: string): Promise<void> {
  await api.post(`/channels/${channelId}/members/${userId}/mute`);
}
