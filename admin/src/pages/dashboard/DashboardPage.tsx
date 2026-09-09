import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { getStats } from '@/api/stats';
import { getChannels } from '@/api/channels';
import { StatsCard } from '@/components/common/StatsCard';
import { LiveBadge } from '@/components/common/LiveBadge';

export function DashboardPage() {
  const { data: statsData, isLoading: statsLoading } = useQuery({
    queryKey: ['stats'],
    queryFn: getStats,
    refetchInterval: 30_000,
  });

  const { data: channelsData, isLoading: channelsLoading } = useQuery({
    queryKey: ['channels'],
    queryFn: getChannels,
    refetchInterval: 30_000,
  });

  const stats = statsData?.stats;
  const channels = channelsData?.channels ?? [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <span className="text-sm text-gray-400">Auto-refresh setiap 30 detik</span>
      </div>

      {/* Stats Grid */}
      {statsLoading ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="h-28 animate-pulse rounded-xl border border-gray-200 bg-gray-100" />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
          <StatsCard title="Total Users" value={stats?.totalUsers ?? 0} subtitle="Registered accounts" />
          <StatsCard title="Active Users" value={stats?.activeUsers ?? 0} subtitle="Not banned" trend="up" />
          <StatsCard title="Total Channels" value={stats?.totalChannels ?? 0} subtitle="All channels" />
          <StatsCard title="Active Channels" value={stats?.activeChannels ?? 0} subtitle="Currently active" trend="up" />
          <StatsCard title="Organizations" value={stats?.totalOrganizations ?? 0} subtitle="Registered orgs" />
        </div>
      )}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Channel List */}
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">Channels</h2>
            <Link
              to="/channels/create"
              className="rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-blue-700"
            >
              + New Channel
            </Link>
          </div>

          {channelsLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-16 animate-pulse rounded-lg bg-gray-100" />
              ))}
            </div>
          ) : channels.length === 0 ? (
            <p className="py-8 text-center text-sm text-gray-400">Belum ada channel</p>
          ) : (
            <div className="space-y-2">
              {channels.map((ch) => (
                <Link
                  key={ch.id}
                  to={`/channels/${ch.id}`}
                  className="flex items-center justify-between rounded-lg border border-gray-100 px-4 py-3 transition-colors hover:bg-gray-50"
                >
                  <div className="flex items-center gap-3">
                    <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-50 text-lg">
                      {ch.isPrivate ? '🔒' : '📻'}
                    </span>
                    <div>
                      <p className="font-medium text-gray-900">{ch.name}</p>
                      <p className="text-xs text-gray-500">
                        {ch.isPrivate ? 'Private' : 'Public'} · {ch._count?.members ?? 0} members
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {ch.isActive && <LiveBadge />}
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Quick Info */}
        <div className="space-y-6">
          <div className="rounded-xl border border-gray-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">Quick Actions</h2>
            <div className="grid grid-cols-2 gap-3">
              <Link
                to="/users"
                className="flex items-center gap-3 rounded-lg border border-gray-200 p-3 transition-colors hover:bg-gray-50"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-purple-50 text-sm">👥</span>
                <span className="text-sm font-medium text-gray-700">Manage Users</span>
              </Link>
              <Link
                to="/channels"
                className="flex items-center gap-3 rounded-lg border border-gray-200 p-3 transition-colors hover:bg-gray-50"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-green-50 text-sm">📻</span>
                <span className="text-sm font-medium text-gray-700">Manage Channels</span>
              </Link>
              <Link
                to="/organizations"
                className="flex items-center gap-3 rounded-lg border border-gray-200 p-3 transition-colors hover:bg-gray-50"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-orange-50 text-sm">🏢</span>
                <span className="text-sm font-medium text-gray-700">Organizations</span>
              </Link>
              <Link
                to="/monitor"
                className="flex items-center gap-3 rounded-lg border border-gray-200 p-3 transition-colors hover:bg-gray-50"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-red-50 text-sm">📡</span>
                <span className="text-sm font-medium text-gray-700">Live Monitor</span>
              </Link>
            </div>
          </div>

          <div className="rounded-xl border border-gray-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">System Info</h2>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Platform</span>
                <span className="font-medium text-gray-900">POC-Pecek v0.1.0</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Backend</span>
                <span className="font-medium text-green-600">● Connected</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">LiveKit</span>
                <span className="font-medium text-green-600">● Running</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">MQTT Broker</span>
                <span className="font-medium text-green-600">● Running</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
