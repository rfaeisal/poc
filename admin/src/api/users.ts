import { api } from './client';
import { User, Pagination } from '@/types/user';

interface UsersResponse {
  users: User[];
  pagination: Pagination;
}

export async function getUsers(params: { page?: number; limit?: number; q?: string }): Promise<UsersResponse> {
  const { data } = await api.get('/admin/users', { params });
  return data;
}

export async function getUser(id: string): Promise<{ user: User & { channels?: { id: string; name: string; role: string; joinedAt: string }[]; _count?: Record<string, number> } }> {
  const { data } = await api.get(`/admin/users/${id}`);
  return data;
}

export async function createUser(body: {
  email: string;
  password: string;
  callsign: string;
  name: string;
  role?: string;
}): Promise<{ user: User }> {
  const { data } = await api.post('/admin/users', body);
  return data;
}

export async function updateUser(id: string, body: {
  email?: string;
  password?: string;
  callsign?: string;
  name?: string;
  role?: string;
  bio?: string;
}): Promise<{ user: User }> {
  const { data } = await api.patch(`/admin/users/${id}`, body);
  return data;
}

export async function deleteUser(id: string): Promise<void> {
  await api.delete(`/admin/users/${id}`);
}

export async function banUser(userId: string, reason: string): Promise<void> {
  await api.post(`/admin/users/${userId}/ban`, { reason });
}

export async function unbanUser(userId: string): Promise<void> {
  await api.post(`/admin/users/${userId}/unban`);
}
