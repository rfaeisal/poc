import { api } from './client';
import { PlatformStats } from '@/types/stats';

export async function getStats(): Promise<{ stats: PlatformStats }> {
  const { data } = await api.get('/admin/stats');
  return data;
}
