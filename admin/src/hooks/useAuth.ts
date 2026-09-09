import { useMutation, useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { login as loginApi, getMe, logout as logoutApi } from '@/api/auth';
import { useAuthStore } from '@/stores/auth.store';

export function useLogin() {
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);

  return useMutation({
    mutationFn: ({ email, password }: { email: string; password: string }) =>
      loginApi(email, password),
    onSuccess: (data) => {
      if (data.user.role !== 'ADMIN') {
        throw new Error('Admin access only');
      }
      setAuth(data.user, data.accessToken, data.refreshToken);
      navigate('/dashboard');
    },
  });
}

export function useCurrentUser() {
  const accessToken = useAuthStore((s) => s.accessToken);
  return useQuery({
    queryKey: ['me'],
    queryFn: () => getMe(),
    enabled: !!accessToken,
  });
}

export function useLogout() {
  const store = useAuthStore();
  const navigate = useNavigate();

  return async () => {
    if (store.refreshToken) {
      try {
        await logoutApi(store.refreshToken);
      } catch {
        // ignore
      }
    }
    store.logout();
    navigate('/login');
  };
}
