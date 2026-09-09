import { useQuery } from '@tanstack/react-query';
import { getChannels } from '@/api/channels';
import { useRealtime } from '@/hooks/useRealtime';
import { LiveBadge } from '@/components/common/LiveBadge';
import { useMemo } from 'react';

export function LiveMonitorPage() {
  const { data } = useQuery({
    queryKey: ['channels'],
    queryFn: getChannels,
    refetchInterval: 15_000,
  });

  const channels = data?.channels ?? [];
  const topics = useMemo(
    () => channels.flatMap((ch) => [
      `poc/channels/${ch.id}/ptt`,
      `poc/channels/${ch.id}/status`,
    ]),
    [channels]
  );

  const { messages, connected } = useRealtime(topics);

  const latestPtt = useMemo(() => {
    const map = new Map<string, { callsign: string; action: string }>();
    messages
      .filter((m) => m.topic.includes('/ptt'))
      .forEach((m) => {
        const channelId = m.topic.split('/')[2];
        map.set(channelId, {
          callsign: m.payload.callsign as string,
          action: m.payload.action as string,
        });
      });
    return map;
  }, [messages]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Live Monitor</h1>
        <div className="flex items-center gap-2">
          <span className={`h-2 w-2 rounded-full ${connected ? 'bg-green-500' : 'bg-red-500'}`} />
          <span className="text-sm text-gray-500">
            {connected ? 'MQTT Connected' : 'Disconnected'}
          </span>
        </div>
      </div>

      <div className="space-y-3">
        {channels.length === 0 && (
          <div className="rounded-xl border border-gray-200 bg-white p-8 text-center text-gray-400">
            No channels
          </div>
        )}
        {channels.map((ch) => {
          const ptt = latestPtt.get(ch.id);
          const isTransmitting = ptt?.action === 'start';

          return (
            <div
              key={ch.id}
              className={`rounded-xl border bg-white p-4 transition-colors ${
                isTransmitting ? 'border-red-300 bg-red-50' : 'border-gray-200'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="text-xl">📻</span>
                  <div>
                    <p className="font-semibold text-gray-900">{ch.name}</p>
                    {isTransmitting ? (
                      <p className="text-sm text-red-600">
                        🎙 {ptt!.callsign} is transmitting...
                      </p>
                    ) : (
                      <p className="text-sm text-gray-400">Idle</p>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-sm text-gray-500">
                    {ch._count?.members ?? 0} users
                  </span>
                  {ch.isActive && <LiveBadge />}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
