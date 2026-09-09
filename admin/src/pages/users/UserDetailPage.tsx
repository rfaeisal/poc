import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getUser, updateUser, deleteUser, banUser, unbanUser } from '@/api/users';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { format } from 'date-fns';

export function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin-user', id],
    queryFn: () => getUser(id!),
    enabled: !!id,
  });

  const user = data?.user;

  const [form, setForm] = useState({
    email: '',
    callsign: '',
    name: '',
    role: 'USER',
    bio: '',
    password: '',
  });

  useEffect(() => {
    if (user) {
      setForm({
        email: user.email,
        callsign: user.profile?.callsign ?? '',
        name: user.profile?.name ?? '',
        role: user.role,
        bio: user.profile?.bio ?? '',
        password: '',
      });
    }
  }, [user]);

  const updateMutation = useMutation({
    mutationFn: () => {
      const body: Record<string, string> = {};
      if (form.email !== user?.email) body.email = form.email;
      if (form.callsign !== user?.profile?.callsign) body.callsign = form.callsign;
      if (form.name !== user?.profile?.name) body.name = form.name;
      if (form.role !== user?.role) body.role = form.role;
      if (form.bio !== (user?.profile?.bio ?? '')) body.bio = form.bio;
      if (form.password) body.password = form.password;
      return updateUser(id!, body);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-user', id] });
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      setForm((f) => ({ ...f, password: '' }));
    },
  });

  const deleteMutation = useMutation({
    mutationFn: () => deleteUser(id!),
    onSuccess: () => navigate('/users'),
  });

  const set = (field: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
    setForm((f) => ({ ...f, [field]: e.target.value }));

  if (isLoading) {
    return <div className="py-12 text-center text-gray-400">Loading...</div>;
  }

  if (!user) {
    return <div className="py-12 text-center text-gray-500">User not found</div>;
  }

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{user.profile?.callsign ?? user.email}</h1>
          <p className="text-sm text-gray-500">Created {format(new Date(user.createdAt), 'dd MMM yyyy HH:mm')}</p>
        </div>
        <div className="flex items-center gap-2">
          {user.isBanned ? (
            <button
              onClick={async () => { await unbanUser(user.id); queryClient.invalidateQueries({ queryKey: ['admin-user', id] }); }}
              className="rounded-lg border border-green-300 px-3 py-1.5 text-sm font-medium text-green-700 hover:bg-green-50"
            >
              Unban
            </button>
          ) : user.role !== 'ADMIN' ? (
            <ConfirmDialog
              title="Ban User"
              message={`Ban ${user.profile?.callsign ?? user.email}?`}
              confirmLabel="Ban"
              variant="danger"
              onConfirm={async () => { await banUser(user.id, 'Banned by admin'); queryClient.invalidateQueries({ queryKey: ['admin-user', id] }); }}
            >
              {(open) => (
                <button onClick={open} className="rounded-lg border border-orange-300 px-3 py-1.5 text-sm font-medium text-orange-700 hover:bg-orange-50">
                  Ban
                </button>
              )}
            </ConfirmDialog>
          ) : null}
          {user.role !== 'ADMIN' && (
            <ConfirmDialog
              title="Delete User"
              message={`Permanently delete ${user.profile?.callsign ?? user.email}? This cannot be undone.`}
              confirmLabel="Delete"
              variant="danger"
              onConfirm={() => deleteMutation.mutateAsync()}
            >
              {(open) => (
                <button onClick={open} className="rounded-lg border border-red-300 px-3 py-1.5 text-sm font-medium text-red-700 hover:bg-red-50">
                  Delete
                </button>
              )}
            </ConfirmDialog>
          )}
        </div>
      </div>

      {/* Status badges */}
      <div className="flex gap-2">
        <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
          user.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' :
          user.role === 'MODERATOR' ? 'bg-blue-100 text-blue-700' :
          'bg-gray-100 text-gray-700'
        }`}>
          {user.role}
        </span>
        <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
          user.isBanned ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'
        }`}>
          {user.isBanned ? 'Banned' : 'Active'}
        </span>
      </div>

      {/* Edit form */}
      <form
        onSubmit={(e) => { e.preventDefault(); updateMutation.mutate(); }}
        className="space-y-4 rounded-xl border border-gray-200 bg-white p-6"
      >
        <h2 className="text-lg font-semibold text-gray-900">Edit User</h2>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              required
              value={form.email}
              onChange={set('email')}
              className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Callsign</label>
            <input
              type="text"
              required
              value={form.callsign}
              onChange={set('callsign')}
              className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm uppercase focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Name</label>
            <input
              type="text"
              required
              value={form.name}
              onChange={set('name')}
              className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Role</label>
            <select
              value={form.role}
              onChange={set('role')}
              className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="USER">User</option>
              <option value="MODERATOR">Moderator</option>
              <option value="ADMIN">Admin</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Bio</label>
          <textarea
            value={form.bio}
            onChange={set('bio')}
            rows={3}
            className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">New Password</label>
          <input
            type="password"
            value={form.password}
            onChange={set('password')}
            placeholder="Leave blank to keep current"
            minLength={6}
            className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        {updateMutation.error && (
          <p className="text-sm text-red-600">
            {(updateMutation.error as Error & { response?: { data?: { error?: string } } })?.response?.data?.error
              ?? 'Failed to update user'}
          </p>
        )}
        {updateMutation.isSuccess && (
          <p className="text-sm text-green-600">User updated successfully</p>
        )}

        <div className="flex justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={() => navigate('/users')}
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

      {/* Channel memberships */}
      {(user as any).channels && (user as any).channels.length > 0 && (
        <div className="rounded-xl border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold text-gray-900">Channel Memberships</h2>
          <div className="space-y-2">
            {(user as any).channels.map((ch: any) => (
              <div key={ch.id} className="flex items-center justify-between rounded-lg border border-gray-100 px-4 py-2">
                <span className="text-sm font-medium text-gray-900">{ch.name}</span>
                <div className="flex items-center gap-3">
                  <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                    ch.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' : 'bg-gray-100 text-gray-700'
                  }`}>
                    {ch.role}
                  </span>
                  <span className="text-xs text-gray-400">
                    Joined {format(new Date(ch.joinedAt), 'dd MMM yyyy')}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
