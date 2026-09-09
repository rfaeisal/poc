import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { createChannel } from '@/api/channels';

export function CreateChannelPage() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    name: '',
    description: '',
    isPrivate: false,
    password: '',
    maxMembers: 500,
  });

  const mutation = useMutation({
    mutationFn: () => createChannel({
      name: form.name,
      description: form.description || undefined,
      isPrivate: form.isPrivate,
      password: form.isPrivate && form.password ? form.password : undefined,
      maxMembers: form.maxMembers,
    }),
    onSuccess: () => navigate('/channels'),
  });

  const set = (field: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm((f) => ({ ...f, [field]: e.target.type === 'checkbox' ? (e.target as HTMLInputElement).checked : e.target.type === 'number' ? Number(e.target.value) : e.target.value }));

  return (
    <div className="mx-auto max-w-lg space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Create Channel</h1>

      <form onSubmit={(e) => { e.preventDefault(); mutation.mutate(); }} className="space-y-4 rounded-xl border border-gray-200 bg-white p-6">
        <div>
          <label className="block text-sm font-medium text-gray-700">Name</label>
          <input
            type="text"
            required
            minLength={2}
            value={form.name}
            onChange={set('name')}
            placeholder="Channel Umum"
            className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Description</label>
          <textarea
            value={form.description}
            onChange={set('description')}
            rows={3}
            placeholder="Deskripsi channel..."
            className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Max Members</label>
          <input
            type="number"
            value={form.maxMembers}
            onChange={set('maxMembers')}
            min={2}
            max={500}
            className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>

        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={form.isPrivate}
            onChange={set('isPrivate')}
            className="h-4 w-4 rounded border-gray-300"
          />
          <span className="text-sm text-gray-700">Private channel (requires password to join)</span>
        </label>

        {form.isPrivate && (
          <div>
            <label className="block text-sm font-medium text-gray-700">Channel Password</label>
            <input
              type="password"
              value={form.password}
              onChange={set('password')}
              minLength={4}
              placeholder="Min 4 characters"
              className="mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
        )}

        {mutation.error && (
          <p className="text-sm text-red-600">
            {(mutation.error as Error & { response?: { data?: { error?: string } } })?.response?.data?.error
              ?? 'Failed to create channel'}
          </p>
        )}

        <div className="flex justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={() => navigate('/channels')}
            className="rounded-lg px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={mutation.isPending}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {mutation.isPending ? 'Creating...' : 'Create Channel'}
          </button>
        </div>
      </form>
    </div>
  );
}
