import { Routes, Route, Navigate } from 'react-router-dom';
import { AppLayout } from '@/components/layout/AppLayout';
import { LoginPage } from '@/pages/auth/LoginPage';
import { DashboardPage } from '@/pages/dashboard/DashboardPage';
import { UsersPage } from '@/pages/users/UsersPage';
import { UserDetailPage } from '@/pages/users/UserDetailPage';
import { CreateUserPage } from '@/pages/users/CreateUserPage';
import { ChannelsPage } from '@/pages/channels/ChannelsPage';
import { ChannelDetailPage } from '@/pages/channels/ChannelDetailPage';
import { CreateChannelPage } from '@/pages/channels/CreateChannelPage';
import { OrganizationsPage } from '@/pages/organizations/OrganizationsPage';
import { OrgDetailPage } from '@/pages/organizations/OrgDetailPage';
import { LiveMonitorPage } from '@/pages/monitor/LiveMonitorPage';
import { AuditLogsPage } from '@/pages/audit/AuditLogsPage';
import { SettingsPage } from '@/pages/settings/SettingsPage';

export function AppRouter() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<AppLayout />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/users" element={<UsersPage />} />
        <Route path="/users/create" element={<CreateUserPage />} />
        <Route path="/users/:id" element={<UserDetailPage />} />
        <Route path="/channels" element={<ChannelsPage />} />
        <Route path="/channels/create" element={<CreateChannelPage />} />
        <Route path="/channels/:id" element={<ChannelDetailPage />} />
        <Route path="/organizations" element={<OrganizationsPage />} />
        <Route path="/organizations/:id" element={<OrgDetailPage />} />
        <Route path="/monitor" element={<LiveMonitorPage />} />
        <Route path="/audit" element={<AuditLogsPage />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
