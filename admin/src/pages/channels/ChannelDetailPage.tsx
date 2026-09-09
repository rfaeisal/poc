import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserX, VolumeX } from 'lucide-react';
import { getChannel, updateChannel, deleteChannel, getChannelMembers, kickMember, muteMember } from '@/api/channels';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { format } from 'date-fns';

export function ChannelDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const { data: channelData, isLoading } = useQuery({
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

  const [form, setForm] = useState({
    name: '',
    description: '',
    maxMembers: 500,
    isPrivate: false,
    isActive: true,
  });

  useEffect(() => {
    if (channel) {
      setForm({
        name: channel.name,
        description: channel.description ?? '',
        maxMembers: channel.maxMembers,
        isPrivate: channel.isPrivate,
        isActive: channel.isActive,
      });
    }
  }, [channel]);

  const updateMutation = useMutation({
    mutationFn: () => updateChannel(id!, {
      name: form.name,
      description: form.description || undefined,
      maxMembers: form.maxMembers,
      isPrivate: form.isPrivate,
      isActive: form.isActive,
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['channel', id] });
      queryClient.invalidateQueries({ queryKey: ['channels'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: () => deleteChannel(id!),
    onSuccess: () => navigate('/channels'),
  });

  const set = (field: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm((f) => ({ ...f, [field]: e.target.type === 'checkbox' ? (e.target as HTMLInputElement).checked : e.target.type === 'number' ? Number(e.target.value) : e.target.value }));

  if (isLoading) {
    return <div className="py-12 text-center text-gray-400">Loading...</div>;
  }

  if (!channel) {
    return <div className="py-12 text-center text-gray-500">Channel not found</div>;
  }

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{channel.name}</h1>
          <p className="text-sm text-gray-500">
            Created {format(new Date(channel.createdAt), 'dd MMM yyyy HH:mm')} · Room: <code className="text-xs">{channel.livekitRoomId}</code>
          </p>
        </div>
        <ConfirmDialog
          title="Delete Channel"
          message={`Delete "${channel.name}"? All members will be disconnected. This cannot be undone.`}
          confirmLabel="Delete"
          variant="danger"
          onConfirm={() => deleteMutation.mutateAsync()}
        >
          {(open) => (
            <button onClick={open} className="rounded-lg border border-red-300 px-3 py-1.5 text-sm font-medium text-red-700 hover:bg-red-50">
              Delete Channel
            </button>
          )}
        </ConfirmDialog>
      </div>

      {/* Status badges */}
      <div className="flex gap-2">
        <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
          channel.isPrivate ? 'bg-yellow-100 text-yellow-700' : 'bg-green-100 text-green-700'
        }`}>
          {channel.isPrivate ? 'Private' : 'Public'}
        </span>
        <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
          channel.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
        }`}>
          {channel.isActive ? 'Active' : 'Inactive'}
        </span>
        <span className="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-700">
          {channel._count?.members ?? 0} / {channel.maxMembers} members
        </span>
      </div>

      {/* Edit form */}
      <form
        onSubmit={(e) => { e.preventDefault(); updateMutation.mutate(); }}
        className="space-y-4 rounded-xl border border-gray-200 bg-white p-6"
      >
        <h2 className="text-lg font-semibold text-gray-900">Edit Channel</h2>

        <div>
          <label className="block text-sm font-medium text-gray-700">Name</label>
          <input
            type="text"
            required
            minLength={2}
            value={form.name}
            onChange={set('name')}
            className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Description</label>
          <textarea
            value={form.description}
            onChange={set('description')}
            rows={3}
            className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Max Members</label>
            <input
              type="number"
              min={2}
              max={500}
              value={form.maxMembers}
              onChange={set('maxMembers')}
              className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          <div className="flex flex-col justify-end gap-3 py-2">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={form.isPrivate}
                onChange={set('isPrivate')}
                className="h-4 w-4 rounded border-gray-300"
              />
              <span className="text-sm text-gray-700">Private channel</span>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={set('isActive')}
                className="h-4 w-4 rounded border-gray-300"
              />
              <span className="text-sm text-gray-700">Active</span>
            </label>
          </div>
        </div>

        {updateMutation.error && (
          <p className="text-sm text-red-600">
            {(updateMutation.error as Error & { response?: { data?: { error?: string } } })?.response?.data?.error
              ?? 'Failed to update channel'}
          </p>
        )}
        {updateMutation.isSuccess && (
          <p className="text-sm text-green-600">Channel updated successfully</p>
        )}

        <div className="flex justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={() => navigate('/channels')}
            className="rounded-lg px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100"
          >
            Back
          </button>
          <button
            type="submit"
            disabled={updateMutation.isPending}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {updateMutation.isPending ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </form>

      {/* Members list */}
      <div className="rounded-xl border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold text-gray-900">Members ({members.length})</h2>
        <div className="space-y-2">
          {members.map((m) => (
            <div key={m.id} className="flex items-center justify-between rounded-lg border border-gray-100 px-4 py-3">
              <div className="flex items-center gap-3">
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 text-xs font-bold text-gray-600">
                  {(m.user.profile?.callsign ?? '?')[0]}
                </div>
                <div>
                  <p className="font-medium text-gray-900">
                    {m.user.profile?.callsign ?? m.user.email}
                    {m.user.profile?.name && (
                      <span className="ml-2 text-sm font-normal text-gray-500">{m.user.profile.name}</span>
                    )}
                  </p>
                  <p className="text-xs text-gray-400">
                    <span className={`rounded-full px-1.5 py-0.5 text-xs font-medium ${
                      m.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' :
                      m.role === 'MODERATOR' ? 'bg-blue-100 text-blue-700' :
                      'bg-gray-100 text-gray-600'
                    }`}>
                      {m.role}
                    </span>
                    {m.isMuted && <span className="ml-2 rounded-full bg-red-100 px-1.5 py-0.5 text-xs font-medium text-red-600">Muted</span>}
                  </p>
                </div>
              </div>
              {m.role !== 'ADMIN' && (
                <div className="flex items-center gap-1">
                  <ConfirmDialog
                    title="Mute Member"
                    message={`${m.isMuted ? 'Unmute' : 'Mute'} ${m.user.profile?.callsign ?? m.user.email}?`}
                    confirmLabel={m.isMuted ? 'Unmute' : 'Mute'}
                    onConfirm={async () => {
                      await muteMember(id!, m.userId);
                      queryClient.invalidateQueries({ queryKey: ['channel-members', id] });
                    }}
                  >
                    {(open) => (
                      <button
                        onClick={open}
                        title={m.isMuted ? 'Unmute member' : 'Mute member'}
                        className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-orange-50 hover:text-orange-600"
                      >
                        <VolumeX size={16} />
                      </button>
                    )}
                  </ConfirmDialog>
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
                      <button
                        onClick={open}
                        title="Kick member"
                        className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-red-50 hover:text-red-600"
                      >
                        <UserX size={16} />
                      </button>
                    )}
                  </ConfirmDialog>
                </div>
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
