import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ColumnDef } from '@tanstack/react-table';
import { getUsers, banUser, unbanUser } from '@/api/users';
import { User } from '@/types/user';
import { DataTable } from '@/components/common/DataTable';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { format } from 'date-fns';

export function UsersPage() {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin-users', page, search],
    queryFn: () => getUsers({ page, limit: 20, q: search || undefined }),
  });

  const users = data?.users ?? [];
  const pagination = data?.pagination;

  const columns: ColumnDef<User, unknown>[] = [
    {
      header: 'Callsign',
      accessorFn: (row) => row.profile?.callsign ?? '-',
    },
    {
      header: 'Name',
      accessorFn: (row) => row.profile?.name ?? '-',
    },
    {
      header: 'Email',
      accessorKey: 'email',
    },
    {
      header: 'Role',
      accessorKey: 'role',
      cell: ({ getValue }) => (
        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
          getValue() === 'ADMIN' ? 'bg-purple-100 text-purple-700' :
          getValue() === 'MODERATOR' ? 'bg-blue-100 text-blue-700' :
          'bg-gray-100 text-gray-700'
        }`}>
          {getValue() as string}
        </span>
      ),
    },
    {
      header: 'Status',
      cell: ({ row }) => (
        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
          row.original.isBanned ? 'bg-red-100 text-red-700' :
          row.original.isActive ? 'bg-green-100 text-green-700' :
          'bg-gray-100 text-gray-700'
        }`}>
          {row.original.isBanned ? 'Banned' : row.original.isActive ? 'Active' : 'Inactive'}
        </span>
      ),
    },
    {
      header: 'Last Seen',
      accessorKey: 'lastSeenAt',
      cell: ({ getValue }) => {
        const v = getValue() as string | null;
        return v ? format(new Date(v), 'dd MMM yyyy HH:mm') : '-';
      },
    },
    {
      header: 'Actions',
      cell: ({ row }) => {
        const user = row.original;
        if (user.role === 'ADMIN') return null;

        const refresh = () => queryClient.invalidateQueries({ queryKey: ['admin-users'] });

        return user.isBanned ? (
          <ConfirmDialog
            title="Unban User"
            message={`Unban ${user.profile?.callsign ?? user.email}?`}
            confirmLabel="Unban"
            onConfirm={async () => { await unbanUser(user.id); refresh(); }}
          >
            {(open) => (
              <button onClick={open} className="text-sm text-blue-600 hover:underline">Unban</button>
            )}
          </ConfirmDialog>
        ) : (
          <ConfirmDialog
            title="Ban User"
            message={`Ban ${user.profile?.callsign ?? user.email}? They will be immediately disconnected.`}
            confirmLabel="Ban"
            variant="danger"
            onConfirm={async () => { await banUser(user.id, 'Banned by admin'); refresh(); }}
          >
            {(open) => (
              <button onClick={open} className="text-sm text-red-600 hover:underline">Ban</button>
            )}
          </ConfirmDialog>
        );
      },
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Users</h1>
        <input
          type="text"
          placeholder="Search callsign, name, email..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          className="w-72 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
      </div>

      {isLoading ? (
        <div className="py-12 text-center text-gray-400">Loading...</div>
      ) : (
        <>
          <DataTable data={users} columns={columns} />
          {pagination && pagination.totalPages > 1 && (
            <div className="flex items-center justify-between">
              <p className="text-sm text-gray-500">
                Page {pagination.page} of {pagination.totalPages} ({pagination.total} total)
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page <= 1}
                  className="rounded-lg border border-gray-300 px-3 py-1 text-sm disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage((p) => p + 1)}
                  disabled={page >= pagination.totalPages}
                  className="rounded-lg border border-gray-300 px-3 py-1 text-sm disabled:opacity-50"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
