import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
import { Pencil, ShieldOff, ShieldCheck, Trash2 } from 'lucide-react';
import { getUsers, banUser, unbanUser, deleteUser } from '@/api/users';
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

  const deleteMutation = useMutation({
    mutationFn: deleteUser,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin-users'] }),
  });

  const users = data?.users ?? [];
  const pagination = data?.pagination;
  const refresh = () => queryClient.invalidateQueries({ queryKey: ['admin-users'] });

  const columns: ColumnDef<User, unknown>[] = [
    {
      header: 'Callsign',
      accessorFn: (row) => row.profile?.callsign ?? '-',
      cell: ({ row }) => (
        <Link to={`/users/${row.original.id}`} className="font-medium text-blue-600 hover:underline">
          {row.original.profile?.callsign ?? '-'}
        </Link>
      ),
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
      header: 'Created',
      accessorKey: 'createdAt',
      cell: ({ getValue }) => {
        const v = getValue() as string | null;
        return v ? format(new Date(v), 'dd MMM yyyy') : '-';
      },
    },
    {
      header: 'Actions',
      cell: ({ row }) => {
        const user = row.original;

        return (
          <div className="flex items-center gap-1">
            <Link
              to={`/users/${user.id}`}
              title="Edit user"
              className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-blue-50 hover:text-blue-600"
            >
              <Pencil size={16} />
            </Link>
            {user.role !== 'ADMIN' && (
              <>
                {user.isBanned ? (
                  <ConfirmDialog
                    title="Unban User"
                    message={`Unban ${user.profile?.callsign ?? user.email}?`}
                    confirmLabel="Unban"
                    onConfirm={async () => { await unbanUser(user.id); refresh(); }}
                  >
                    {(open) => (
                      <button
                        onClick={open}
                        title="Unban user"
                        className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-green-50 hover:text-green-600"
                      >
                        <ShieldCheck size={16} />
                      </button>
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
                      <button
                        onClick={open}
                        title="Ban user"
                        className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-orange-50 hover:text-orange-600"
                      >
                        <ShieldOff size={16} />
                      </button>
                    )}
                  </ConfirmDialog>
                )}
                <ConfirmDialog
                  title="Delete User"
                  message={`Permanently delete ${user.profile?.callsign ?? user.email}? This cannot be undone.`}
                  confirmLabel="Delete"
                  variant="danger"
                  onConfirm={() => deleteMutation.mutateAsync(user.id)}
                >
                  {(open) => (
                    <button
                      onClick={open}
                      title="Delete user"
                      className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-red-50 hover:text-red-600"
                    >
                      <Trash2 size={16} />
                    </button>
                  )}
                </ConfirmDialog>
              </>
            )}
          </div>
        );
      },
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Users</h1>
        <div className="flex items-center gap-3">
          <input
            type="text"
            placeholder="Search callsign, name, email..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            className="w-72 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
          <Link
            to="/users/create"
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            + Create User
          </Link>
        </div>
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
