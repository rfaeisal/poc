import { useAuthStore } from '@/stores/auth.store';
import { useLogout } from '@/hooks/useAuth';

export function Header() {
  const user = useAuthStore((s) => s.user);
  const logout = useLogout();

  return (
    <header className="flex h-16 items-center justify-end gap-4 border-b border-gray-200 bg-white px-6">
      <span className="text-sm text-gray-600">
        {user?.profile?.callsign ?? user?.email}
      </span>
      <button
        onClick={logout}
        className="rounded-lg px-3 py-1.5 text-sm font-medium text-gray-600 hover:bg-gray-100"
      >
        Logout
      </button>
    </header>
  );
}
