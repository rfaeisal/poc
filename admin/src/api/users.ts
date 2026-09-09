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

export async function banUser(userId: string, reason: string): Promise<void> {
  await api.post(`/admin/users/${userId}/ban`, { reason });
}

export async function unbanUser(userId: string): Promise<void> {
  await api.post(`/admin/users/${userId}/unban`);
}
