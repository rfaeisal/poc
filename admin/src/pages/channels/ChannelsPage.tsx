import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
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

  const channels = data?.channels ?? [];

  const columns: ColumnDef<Channel, unknown>[] = [
    {
      header: 'Name',
      cell: ({ row }) => (
        <Link to={`/channels/${row.original.id}`} className="font-medium text-blue-600 hover:underline">
          {row.original.name}
        </Link>
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
      accessorFn: (row) => row._count?.members ?? 0,
    },
    {
      header: 'Max',
      accessorKey: 'maxMembers',
    },
    {
      header: 'Status',
      cell: ({ row }) => row.original.isActive ? <LiveBadge /> : <span className="text-xs text-gray-400">Inactive</span>,
    },
    {
      header: 'Created',
      accessorKey: 'createdAt',
      cell: ({ getValue }) => format(new Date(getValue() as string), 'dd MMM yyyy'),
    },
    {
      header: 'Actions',
      cell: ({ row }) => (
        <ConfirmDialog
          title="Delete Channel"
          message={`Delete "${row.original.name}"? All members will be disconnected.`}
          confirmLabel="Delete"
          variant="danger"
          onConfirm={async () => {
            await deleteChannel(row.original.id);
            queryClient.invalidateQueries({ queryKey: ['channels'] });
          }}
        >
          {(open) => (
            <button onClick={open} className="text-sm text-red-600 hover:underline">Delete</button>
          )}
        </ConfirmDialog>
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
          Create Channel
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
