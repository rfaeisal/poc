import { useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { getChannel, getChannelMembers, kickMember } from '@/api/channels';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';

export function ChannelDetailPage() {
  const { id } = useParams<{ id: string }>();
  const queryClient = useQueryClient();

  const { data: channelData } = useQuery({
    queryKey: ['channel', id],
    queryFn: () => getChannel(id!),
    enabled: !!id,
  });

  const { data: membersData } = useQuery({
    queryKey: ['channel-members', id],
    queryFn: () => getChannelMembers(id!),
    enabled: !!id,
    refetchInterval: 10_000,
  });

  const channel = channelData?.channel;
  const members = membersData?.members ?? [];

  if (!channel) {
    return <div className="py-12 text-center text-gray-400">Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{channel.name}</h1>
        <p className="text-sm text-gray-500">{channel.description ?? 'No description'}</p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <p className="text-sm text-gray-500">Type</p>
          <p className="mt-1 font-medium">{channel.isPrivate ? 'Private' : 'Public'}</p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <p className="text-sm text-gray-500">Members</p>
          <p className="mt-1 font-medium">{channel._count?.members ?? 0} / {channel.maxMembers}</p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <p className="text-sm text-gray-500">Room ID</p>
          <p className="mt-1 font-mono text-sm">{channel.livekitRoomId}</p>
        </div>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">Members ({members.length})</h2>
        <div className="space-y-2">
          {members.map((m) => (
            <div key={m.id} className="flex items-center justify-between rounded-lg border border-gray-100 px-4 py-3">
              <div>
                <p className="font-medium text-gray-900">
                  {m.user.profile?.callsign ?? m.user.email}
                </p>
                <p className="text-xs text-gray-500">
                  {m.role} {m.isMuted && '(muted)'}
                </p>
              </div>
              {m.role !== 'ADMIN' && (
                <ConfirmDialog
                  title="Kick Member"
                  message={`Remove ${m.user.profile?.callsign ?? m.user.email} from this channel?`}
                  confirmLabel="Kick"
                  variant="danger"
                  onConfirm={async () => {
                    await kickMember(id!, m.userId);
                    queryClient.invalidateQueries({ queryKey: ['channel-members', id] });
                  }}
                >
                  {(open) => (
                    <button onClick={open} className="text-sm text-red-600 hover:underline">Kick</button>
                  )}
                </ConfirmDialog>
              )}
            </div>
          ))}
          {members.length === 0 && (
            <p className="py-4 text-center text-sm text-gray-400">No members</p>
          )}
        </div>
      </div>
    </div>
  );
}
