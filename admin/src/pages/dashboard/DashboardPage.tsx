import { useQuery } from '@tanstack/react-query';
import { getStats } from '@/api/stats';
import { getChannels } from '@/api/channels';
import { StatsCard } from '@/components/common/StatsCard';
import { LiveBadge } from '@/components/common/LiveBadge';

export function DashboardPage() {
  const { data: statsData, isLoading } = useQuery({
    queryKey: ['stats'],
    queryFn: getStats,
    refetchInterval: 30_000,
  });

  const { data: channelsData } = useQuery({
    queryKey: ['channels'],
    queryFn: getChannels,
    refetchInterval: 30_000,
  });

  const stats = statsData?.stats;
  const channels = channelsData?.channels ?? [];

  if (isLoading) {
    return <div className="flex items-center justify-center py-12 text-gray-400">Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatsCard title="Total Users" value={stats?.totalUsers ?? 0} />
        <StatsCard title="Active Users" value={stats?.activeUsers ?? 0} />
        <StatsCard title="Total Channels" value={stats?.totalChannels ?? 0} />
        <StatsCard title="Active Channels" value={stats?.activeChannels ?? 0} />
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">Channels</h2>
        <div className="space-y-3">
          {channels.length === 0 && (
            <p className="py-4 text-center text-sm text-gray-400">No channels yet</p>
          )}
          {channels.map((ch) => (
            <div
              key={ch.id}
              className="flex items-center justify-between rounded-lg border border-gray-100 px-4 py-3"
            >
              <div className="flex items-center gap-3">
                <span className="text-lg">📻</span>
                <div>
                  <p className="font-medium text-gray-900">{ch.name}</p>
                  <p className="text-xs text-gray-500">
                    {ch.isPrivate ? 'Private' : 'Public'}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-sm text-gray-500">
                  {ch._count?.members ?? 0} members
                </span>
                {ch.isActive && <LiveBadge />}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
