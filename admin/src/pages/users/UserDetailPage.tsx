import { useParams } from 'react-router-dom';

export function UserDetailPage() {
  const { id } = useParams<{ id: string }>();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">User Detail</h1>
      <p className="text-sm text-gray-500">User ID: {id}</p>
      <p className="text-sm text-gray-400">Detail view — to be expanded</p>
    </div>
  );
}
