import { api } from './client';

export interface Organization {
  id: string;
  name: string;
  slug: string;
  plan: 'FREE' | 'COMMUNITY' | 'ENTERPRISE';
  maxUsers: number;
  maxChannels: number;
  createdAt: string;
  _count?: { users: number; channels: number };
}

export async function getOrganization(id: string): Promise<{ organization: Organization }> {
  const { data } = await api.get(`/organizations/${id}`);
  return data;
}

export async function getOrgMembers(id: string) {
  const { data } = await api.get(`/organizations/${id}/members`);
  return data;
}

export async function updateOrgSettings(id: string, body: Partial<Organization>): Promise<{ organization: Organization }> {
  const { data } = await api.patch(`/organizations/${id}/settings`, body);
  return data;
}
