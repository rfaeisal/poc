export interface PlatformStats {
  totalUsers: number;
  activeUsers: number;
  totalChannels: number;
  activeChannels: number;
  totalOrganizations: number;
}

export interface PttLog {
  id: string;
  channelId: string;
  userId: string;
  startedAt: string;
  endedAt: string | null;
  durationMs: number | null;
  user: {
    profile: {
      callsign: string;
      name: string;
    } | null;
  };
  channel?: {
    name: string;
  };
}
