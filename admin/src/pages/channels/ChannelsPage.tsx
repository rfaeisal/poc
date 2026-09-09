import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
import { Pencil, Trash2, Users } from 'lucide-react';
import { getChannels, deleteChannel } from '@/api/channels';
import { Channel } from '@/types/channel';
import { DataTable } from '@/components/common/DataTable';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { LiveBadge } from '@/components/common/LiveBadge';
import { format } from 'date-fns';

export function ChannelsPage() {
  const queryClient = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ['channels'],
    queryFn: getChannels,
  });

  const deleteMutation = useMutation({
    mutationFn: deleteChannel,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['channels'] }),
  });

  const channels = data?.channels ?? [];

  const columns: ColumnDef<Channel, unknown>[] = [
    {
      header: 'Name',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 text-sm">
            {row.original.isPrivate ? '🔒' : '📻'}
          </span>
          <div>
            <Link to={`/channels/${row.original.id}`} className="font-medium text-blue-600 hover:underline">
              {row.original.name}
            </Link>
            {row.original.description && (
              <p className="text-xs text-gray-400 truncate max-w-xs">{row.original.description}</p>
            )}
          </div>
        </div>
      ),
    },
    {
      header: 'Type',
      cell: ({ row }) => (
        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
          row.original.isPrivate ? 'bg-yellow-100 text-yellow-700' : 'bg-green-100 text-green-700'
        }`}>
          {row.original.isPrivate ? 'Private' : 'Public'}
        </span>
      ),
    },
    {
      header: 'Members',
      cell: ({ row }) => (
        <span className="text-sm text-gray-700">
          {row.original._count?.members ?? 0} / {row.original.maxMembers}
        </span>
      ),
    },
    {
      header: 'Status',
      cell: ({ row }) => row.original.isActive
        ? <LiveBadge />
        : <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-500">Inactive</span>,
    },
    {
      header: 'Created',
      accessorKey: 'createdAt',
      cell: ({ getValue }) => format(new Date(getValue() as string), 'dd MMM yyyy'),
    },
    {
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <Link
            to={`/channels/${row.original.id}`}
            title="View members"
            className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-blue-50 hover:text-blue-600"
          >
            <Users size={16} />
          </Link>
          <Link
            to={`/channels/${row.original.id}`}
            title="Edit channel"
            className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-blue-50 hover:text-blue-600"
          >
            <Pencil size={16} />
          </Link>
          <ConfirmDialog
            title="Delete Channel"
            message={`Delete "${row.original.name}"? All members will be disconnected.`}
            confirmLabel="Delete"
            variant="danger"
            onConfirm={() => deleteMutation.mutateAsync(row.original.id)}
          >
            {(open) => (
              <button
                onClick={open}
                title="Delete channel"
                className="rounded-lg p-1.5 text-gray-500 transition-colors hover:bg-red-50 hover:text-red-600"
              >
                <Trash2 size={16} />
              </button>
            )}
          </ConfirmDialog>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Channels</h1>
        <Link
          to="/channels/create"
          className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          + Create Channel
        </Link>
      </div>

      {isLoading ? (
        <div className="py-12 text-center text-gray-400">Loading...</div>
      ) : (
        <DataTable data={channels} columns={columns} />
      )}
    </div>
  );
}
