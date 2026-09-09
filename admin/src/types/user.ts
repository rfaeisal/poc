export interface UserProfile {
  id: string;
  userId: string;
  callsign: string;
  name: string;
  photoUrl: string | null;
  bio: string | null;
}

export interface User {
  id: string;
  email: string;
  role: 'USER' | 'MODERATOR' | 'ADMIN';
  isActive: boolean;
  isBanned: boolean;
  bannedReason: string | null;
  createdAt: string;
  lastSeenAt: string | null;
  profile: UserProfile | null;
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}
